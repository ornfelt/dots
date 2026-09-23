#!/usr/bin/env lua
-- cli.lua - the same usage data for waybar, polybar, tmux or a shell prompt.
--
--   lua5.4 cli.lua              text:  "5h 16% · 7d 4%"
--   lua5.4 cli.lua --json       the canonical state table as JSON
--   lua5.4 cli.lua --waybar     {"text","tooltip","class","percentage"} for waybar's custom module
--   lua5.4 cli.lua --lines      the popup lines, one per row (tmux, notify-send, ...)
--   options: --max-age N   reuse the last result if it is younger than N seconds (default 300)
--            --no-network  never call the API, use the cache files only
--
-- Results are cached in $XDG_CACHE_HOME/claude-usage/last.json together with the
-- backoff state, so calling this every few seconds from a status bar is safe.

local script_dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
package.path = script_dir .. "/?.lua;" .. script_dir .. "/?/init.lua;" .. package.path

local json = require("json")
local config = require("config")
local normalize = require("normalize")
local format = require("format")
local history = require("history")
local sessions_mod = require("sessions")
local credentials = require("source.credentials")
local api = require("source.api")
local statusline_cache = require("source.statusline_cache")
local claude_json = require("source.claude_json")

local mode = "text"
local max_age = 300
local network = true
local i = 1
while i <= #arg do
	local a = arg[i]
	if a == "--json" or a == "--waybar" or a == "--lines" or a == "--text" then
		mode = a:sub(3)
	elseif a == "--max-age" then
		i = i + 1
		max_age = tonumber(arg[i]) or max_age
	elseif a == "--no-network" then
		network = false
	elseif a == "-h" or a == "--help" then
		print("usage: cli.lua [--text|--json|--waybar|--lines] [--max-age N] [--no-network]")
		os.exit(0)
	end
	i = i + 1
end

local opts = config.resolve({ sessions_in_bar = false, show_glyph = false })
local now = os.time()
local cache_dir = opts.cache_path:match("^(.*)/[^/]+$") or "."
local last_path = cache_dir .. "/last.json"

local function read_json(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("a")
	f:close()
	local ok, data = pcall(json.decode, content or "")
	return ok and type(data) == "table" and data or nil
end

local function write_json(path, data)
	os.execute('mkdir -p "' .. cache_dir .. '" 2>/dev/null')
	local tmp = path .. ".tmp"
	local f = io.open(tmp, "w")
	if not f then
		return
	end
	f:write(json.encode(data))
	f:close()
	os.rename(tmp, path)
end

local function shell_quote(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function run_curl(token)
	local argv = api.argv(opts, token)
	local parts = {}
	for _, a in ipairs(argv) do
		parts[#parts + 1] = shell_quote(a)
	end
	local p = io.popen(table.concat(parts, " ") .. " 2>&1; printf '\\n__EXIT__%s' $?", "r")
	if not p then
		return false, { code = "network", message = "cannot run curl", at = now }
	end
	local out = p:read("a") or ""
	p:close()
	local body, code = out:match("^(.*)\n__EXIT__(%d+)%s*$")
	code = tonumber(code) or 1
	if code ~= 0 then
		return api.interpret("", body, "exit", code, now)
	end
	return api.interpret(body, "", "exit", 0, now)
end

local last = read_json(last_path) or {}
local state, err

-- 1) recent result
if last.state and last.fetched_at and now - last.fetched_at <= max_age then
	state = last.state
end

-- 2) fresh statusLine cache
if not state then
	local raw = statusline_cache.read(opts.cache_path)
	if raw and tonumber(raw.ts) and now - tonumber(raw.ts) <= opts.fresh_cache_max_age then
		state = normalize.from_statusline(raw, now)
		state.source = "statusline"
	end
end

-- 3) API, unless backing off
if not state and network then
	if last.retry_at and now < last.retry_at then
		err = { code = "rate_limited", message = "backing off", retry_at = last.retry_at, at = now }
	else
		local creds, cerr = credentials.read(opts.credentials_path, now)
		if not creds then
			err = cerr
		else
			local ok, res = run_curl(creds.token)
			if ok then
				state = normalize.from_api(res, now)
				state.source = "api"
				state.subscription = creds.subscription
				last.retry_at = nil
				last.backoff_attempt = 0
			else
				err = res
				if res.code == "rate_limited" or res.code == "network" then
					local attempt = math.min((last.backoff_attempt or 0) + 1, #opts.backoff)
					last.backoff_attempt = attempt
					last.retry_at = now + opts.backoff[attempt]
					err.retry_at = last.retry_at
				end
			end
		end
	end
end

-- 4) fallbacks
if not state then
	local raw = statusline_cache.read(opts.cache_path)
	if raw then
		state = normalize.from_statusline(raw, now)
		state.source = "statusline"
	end
end
if not state then
	local raw = claude_json.read(opts.claude_json_path)
	if raw then
		state = normalize.from_claude_json(raw, now)
		state.source = "claude_json"
	end
end
if not state and last.state then
	state = last.state
end
state = state or { scoped = {} }
state.error = err
state.stale = state.fetched_at ~= nil and (now - state.fetched_at) > opts.stale_after

if opts.history then
	local samples = history.load(opts.history_path)
	if (state.source == "api" or state.source == "statusline") and not state.stale then
		local newest = samples[#samples]
		if not newest or now - newest.t >= 30 then
			os.execute('mkdir -p "' .. cache_dir .. '" 2>/dev/null')
			history.append(opts.history_path, samples, state, now)
		end
	end
	state.forecast = { scoped = {} }
	state.pace = {}
	for _, key in ipairs({ "five_hour", "seven_day" }) do
		local w = state[key]
		if w then
			local rate = history.rate(samples, key, now, history.LOOKBACK[key], w.resets_at)
			state.forecast[key] = history.forecast(w, rate, now)
		end
	end
	state.pace.five_hour = history.pace(state.five_hour, 5 * 3600, now)
	state.pace.seven_day = history.pace(state.seven_day, 7 * 86400, now)
end
if opts.sessions then
	local ok, summary = pcall(sessions_mod.read, opts.sessions_dir, now)
	if ok then
		state.sessions = summary
	end
end

-- persist for the next call (only real fetches refresh the timestamp)
if state.source == "api" or state.source == "statusline" then
	last.state = state
	last.fetched_at = state.fetched_at or now
end
write_json(last_path, last)

local level = format.state_level(state, opts.thresholds)
if mode == "json" then
	print(json.encode(state))
elseif mode == "lines" then
	print(table.concat(format.popup_lines(state, now, opts), "\n"))
elseif mode == "waybar" then
	local class = level
	if not format.has_data(state) then
		class = "error"
	elseif state.stale then
		class = "stale"
	end
	print(json.encode({
		text = format.bar_text(state, opts),
		tooltip = table.concat(format.popup_lines(state, now, opts), "\n"),
		class = class,
		percentage = math.floor(format.max_percent(state) or 0),
	}))
else
	print(format.bar_text(state, opts))
end
