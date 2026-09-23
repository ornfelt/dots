-- model.lua - singleton holding the usage state: scheduling, fallback chain, backoff, subscribers.
--
-- Dependencies are injected through `deps` so the module runs without awesome in tests:
--   deps.now()               -> epoch seconds
--   deps.spawn(argv, cb)     -> like awful.spawn.easy_async
--   deps.timer(args)         -> like gears.timer (fields timeout/single_shot/autostart/callback, :start/:stop/:again)
--   deps.notify(args)        -> like naughty.notification
--   deps.warn(msg)           -> log a warning

local prefix = (...):match("^(.*%.)") or ""
local normalize = require(prefix .. "normalize")
local backoff_mod = require(prefix .. "backoff")
local notify_mod = require(prefix .. "notify")
local credentials = require(prefix .. "source.credentials")
local api = require(prefix .. "source.api")
local statusline_cache = require(prefix .. "source.statusline_cache")
local claude_json = require(prefix .. "source.claude_json")
local history = require(prefix .. "history")
local sessions_mod = require(prefix .. "sessions")

local M = {}

M.state = nil

local _opts, _deps, _timer, _redraw_timer, _backoff, _notifier
local _subs = {}
local _inflight = false
local _setup = false
local _last_good = nil
local _creds = nil
local _samples = nil -- history samples (nil when history is off)
local _last_api = nil -- last state that came from the API (scoped limits, breakdown, spend)
local _last_api_at = nil
local _sessions = nil -- last sessions summary
local _sessions_timer = nil
local _next_fetch_at = nil

local REDRAW_INTERVAL = 60

local function now()
	return _deps.now()
end

local function warn(msg)
	if _deps and _deps.warn then
		pcall(_deps.warn, msg)
	end
end

local function shallow_copy(t)
	local out = {}
	for k, v in pairs(t or {}) do
		out[k] = v
	end
	return out
end

local function is_stale(st, t)
	return st.fetched_at ~= nil and (t - st.fetched_at) > _opts.stale_after
end

local function set_state(st)
	M.state = st
	if _notifier then
		local ok, err = pcall(_notifier.update, _notifier, st, now())
		if not ok then
			warn("notifier error: " .. tostring(err))
		end
	end
	local subs = shallow_copy(_subs)
	for _, fn in ipairs(subs) do
		local ok, err = pcall(fn, st)
		if not ok then
			warn("subscriber error: " .. tostring(err))
		end
	end
end

--- Re-arm the fetch timer. Returns the effective delay.
local function schedule_next(delay)
	local jitter = _opts.jitter or 0
	local d = delay
	if jitter > 0 then
		d = d + math.random(-jitter, jitter)
	end
	if d < 30 then
		d = 30
	end
	if _timer then
		_timer:stop()
		_timer.timeout = d
		_timer:again()
	end
	return d
end

--- Fetch interval depending on whether a session is working.
local function current_interval()
	if _opts.sessions and _sessions and (_sessions.working or 0) == 0 then
		return math.max(_opts.interval_idle or _opts.interval, _opts.interval)
	end
	return _opts.interval
end

--- Attach forecast, pacing and session info to a state.
local function attach_context(st, t)
	st.context = nil
	if (_opts.context_max_age or 0) <= 0 then
		return
	end
	local raw = statusline_cache.read(_opts.cache_path)
	local ctx = raw and normalize.context_from(raw) or nil
	if ctx and ctx.at and t - ctx.at <= _opts.context_max_age then
		st.context = ctx
	end
end

local function attach_analysis(st, t)
	st.sessions = _sessions
	attach_context(st, t)
	if not _samples then
		return
	end
	st.forecast = { scoped = {} }
	st.pace = {}
	local function analyse(key, w, lookback)
		if not w then
			return nil
		end
		local rate = history.rate(_samples, key, t, lookback, w.resets_at)
		return history.forecast(w, rate, t)
	end
	st.forecast.five_hour = analyse("five_hour", st.five_hour, history.LOOKBACK.five_hour)
	st.forecast.seven_day = analyse("seven_day", st.seven_day, history.LOOKBACK.seven_day)
	for _, w in ipairs(st.scoped or {}) do
		if w.name then
			st.forecast.scoped[w.name] = analyse("scoped:" .. w.name:gsub(",", " "), w, history.LOOKBACK.scoped)
		end
	end
	st.pace.five_hour = history.pace(st.five_hour, 5 * 3600, t)
	st.pace.seven_day = history.pace(st.seven_day, 7 * 86400, t)
end

local function record(st, t)
	if _samples and (st.source == "api" or st.source == "statusline") and not is_stale(st, t) then
		local last = _samples[#_samples]
		if not last or t - last.t >= 30 then
			history.append(_opts.history_path, _samples, st, t)
		end
	end
end

--- The statusLine only carries the two main windows. Keep the per-model limits, the
--- breakdown and the spend from the last API answer while the weekly cycle is the same.
local function merge_api_details(st)
	if st.source ~= "statusline" or not _last_api then
		return
	end
	local same_cycle = true
	if st.seven_day and st.seven_day.resets_at and _last_api.seven_day and _last_api.seven_day.resets_at then
		same_cycle = math.abs(st.seven_day.resets_at - _last_api.seven_day.resets_at) <= 120
	end
	if not same_cycle then
		return
	end
	if #(st.scoped or {}) == 0 and _last_api.scoped and #_last_api.scoped > 0 then
		st.scoped = {}
		for i, w in ipairs(_last_api.scoped) do
			local copy = {}
			for k, v in pairs(w) do
				copy[k] = v
			end
			st.scoped[i] = copy
		end
		st.scoped_from = _last_api.fetched_at
	end
	st.breakdown = st.breakdown or _last_api.breakdown
	if not st.spend or (st.spend.used == nil and _last_api.spend) then
		st.spend = _last_api.spend
	end
end

local function finalize(st, delay, err)
	_inflight = false
	local t = now()
	st.scoped = st.scoped or {}
	if st.source == "api" then
		_last_api = st
		_last_api_at = t
	end
	merge_api_details(st)
	st.error = err
	st.stale = is_stale(st, t)
	st.subscription = (_creds and _creds.subscription) or (M.state and M.state.subscription) or nil
	record(st, t)
	attach_analysis(st, t)
	local d = schedule_next(delay or current_interval())
	_next_fetch_at = t + d
	st.next_fetch_at = _next_fetch_at
	if normalize.has_data(st) then
		_last_good = st
	end
	set_state(st)
end

local function fallback_state()
	local st = shallow_copy(_last_good or {})
	st.scoped = st.scoped or {}
	return st
end

local function read_file_source(name, t)
	if name == "statusline" then
		local raw = statusline_cache.read(_opts.cache_path)
		if raw then
			return normalize.from_statusline(raw, t)
		end
	elseif name == "claude_json" then
		local raw = claude_json.read(_opts.claude_json_path)
		if raw then
			return normalize.from_claude_json(raw, t)
		end
	end
	return nil
end

local try_source

local function fetch_api(i, err, delay)
	local t = now()
	if _backoff:blocked(t) then
		err = err or { code = "rate_limited", message = "backing off", retry_at = _backoff.until_at, at = t }
		return try_source(i + 1, err, math.max(_backoff:remaining(t), 30))
	end
	-- A fresh statusLine cache makes the network call unnecessary.
	local uses_cache = false
	for _, name in ipairs(_opts.sources) do
		if name == "statusline" then
			uses_cache = true
		end
	end
	local api_recent = _last_api_at ~= nil and (t - _last_api_at) < (_opts.interval_idle or _opts.interval)
	if uses_cache and api_recent and (_opts.fresh_cache_max_age or 0) > 0 then
		local raw = statusline_cache.read(_opts.cache_path)
		if raw and tonumber(raw.ts) and t - tonumber(raw.ts) <= _opts.fresh_cache_max_age then
			local st = normalize.from_statusline(raw, t)
			if normalize.has_data(st) then
				st.source = "statusline"
				return finalize(st, delay, err)
			end
		end
	end
	local creds, cerr = credentials.read(_opts.credentials_path, t)
	if not creds then
		return try_source(i + 1, cerr, delay)
	end
	_creds = creds
	api.fetch(_opts, _deps, creds.token, function(ok, res)
		local t2 = now()
		if ok then
			_backoff:reset()
			local st = normalize.from_api(res, t2)
			st.source = "api"
			return finalize(st, nil, nil)
		end
		local d = delay
		if res.code == "rate_limited" or res.code == "network" then
			d = _backoff:fail(t2)
			res.retry_at = _backoff.until_at
		end
		return try_source(i + 1, res, d)
	end)
end

try_source = function(i, err, delay)
	local name = _opts.sources[i]
	if name == nil then
		return finalize(fallback_state(), delay, err or { code = "no_source", at = now() })
	end
	if name == "api" then
		return fetch_api(i, err, delay)
	elseif name == "statusline" or name == "claude_json" then
		local st = read_file_source(name, now())
		if st and normalize.has_data(st) then
			st.source = name
			return finalize(st, delay, err)
		end
		return try_source(i + 1, err, delay)
	end
	warn("unknown source '" .. tostring(name) .. "'")
	return try_source(i + 1, err, delay)
end

local function tick()
	if _inflight then
		return
	end
	_inflight = true
	try_source(1, nil, nil)
end

--- Paint something immediately from the file sources, before the first API fetch.
local function prime_from_cache()
	local t = now()
	for _, name in ipairs(_opts.sources) do
		if name ~= "api" then
			local st = read_file_source(name, t)
			if st and normalize.has_data(st) then
				st.source = name
				st.stale = is_stale(st, t)
				attach_analysis(st, t)
				st.next_fetch_at = t + (_opts.initial_delay or 0)
				_last_good = st
				set_state(st)
				return
			end
		end
	end
end

local function redraw()
	if not M.state or _inflight then
		return
	end
	local st = shallow_copy(M.state)
	local t = now()
	st.stale = is_stale(st, t)
	attach_analysis(st, t)
	set_state(st)
end

--- Scan the sessions directory; re-emit the state when something changed.
local function poll_sessions()
	local t = now()
	local ok, summary = pcall(sessions_mod.read, _opts.sessions_dir, t, _deps.sessions)
	if not ok then
		warn("sessions scan failed: " .. tostring(summary))
		return
	end
	local prev = _sessions
	_sessions = summary
	local changed = not prev
		or prev.total ~= summary.total
		or prev.working ~= summary.working
		or prev.idle ~= summary.idle
		or prev.attention ~= summary.attention
	if not changed then
		for i, s in ipairs(summary.list) do
			local p = prev.list[i]
			if not p or p.pid ~= s.pid or p.status ~= s.status then
				changed = true
				break
			end
		end
	end
	if not changed then
		return
	end
	if prev and _notifier then
		pcall(_notifier.sessions, _notifier, sessions_mod.diff(prev, summary), t)
	end
	-- Work just stopped or started: fetch soon so the numbers follow.
	if prev and not _inflight and not _backoff:blocked(t) and _timer then
		local was_working = (prev.working or 0) > 0
		local is_working = (summary.working or 0) > 0
		if was_working ~= is_working then
			local soon = t + (is_working and 60 or 45)
			if not _next_fetch_at or _next_fetch_at > soon then
				_timer:stop()
				_timer.timeout = soon - t
				_timer:again()
				_next_fetch_at = soon
			end
		end
	end
	if M.state and not _inflight then
		local st = shallow_copy(M.state)
		st.sessions = summary
		st.next_fetch_at = _next_fetch_at or st.next_fetch_at
		set_state(st)
	end
end

--- Start monitoring. Idempotent.
---@param opts table resolved options (see config.lua)
---@param deps table injected dependencies
function M.setup(opts, deps)
	if _setup then
		return
	end
	_setup = true
	_opts = opts
	_deps = deps
	_backoff = backoff_mod.new(opts.backoff)
	_notifier = notify_mod.new(opts, deps)
	math.randomseed(os.time() + math.floor((os.clock() * 1000) % 1000))

	-- The plan name comes from the credentials file; read it once so cache-only states show it too.
	local creds = credentials.read(opts.credentials_path, now())
	if creds then
		_creds = creds
	end

	if opts.history then
		local ok, samples = pcall(history.load, opts.history_path)
		_samples = ok and samples or {}
		if not ok then
			warn("cannot read history: " .. tostring(samples))
		end
	end
	if opts.sessions then
		poll_sessions()
	end

	prime_from_cache()

	_timer = deps.timer({
		timeout = opts.initial_delay or 5,
		single_shot = true,
		autostart = true,
		callback = tick,
	})
	_redraw_timer = deps.timer({
		timeout = REDRAW_INTERVAL,
		single_shot = false,
		autostart = true,
		callback = redraw,
	})
	if opts.sessions then
		_sessions_timer = deps.timer({
			timeout = opts.sessions_interval or 10,
			single_shot = false,
			autostart = true,
			callback = poll_sessions,
		})
	end
	if opts.watch_cache and deps.watch then
		local ok, err = pcall(deps.watch, opts.cache_path, function()
			M.cache_changed()
		end)
		if not ok then
			warn("cache watch unavailable: " .. tostring(err))
		end
	end
end

local _last_cache_event = 0

--- The statusLine cache was rewritten: read it now (debounced, honours in-flight fetches).
function M.cache_changed()
	if not _setup or _inflight then
		return
	end
	local t = now()
	if t - _last_cache_event < 2 then
		return
	end
	_last_cache_event = t
	if _timer then
		_timer:stop()
	end
	tick()
end

--- Rescan the sessions directory now (used by the Claude Code hook).
function M.poll_sessions()
	if _setup and _opts.sessions then
		poll_sessions()
	end
end

--- A Claude Code hook fired. kind is the notification_type for Notification events.
---@param event string hook_event_name
---@param kind string|nil
---@param session_id string|nil
function M.hook(event, kind, session_id)
	if not _setup then
		return
	end
	local needs_user = {
		permission_prompt = true,
		idle_prompt = true,
		agent_needs_input = true,
		elicitation_dialog = true,
		elicitation_url_dialog = true,
	}
	if event == "Notification" and kind and needs_user[kind] and _notifier then
		local session = nil
		for _, s in ipairs((_sessions and _sessions.list) or {}) do
			if session_id and s.session_id == session_id then
				session = s
			end
		end
		pcall(_notifier.attention, _notifier, session or { session_id = session_id }, now())
	end
	M.poll_sessions()
end

--- Subscribe to state updates. Calls fn immediately when a state exists.
--- Works as model:subscribe(fn) and model.subscribe(fn).
---@return fun() unsubscribe
function M.subscribe(a, b)
	local fn = b or a
	_subs[#_subs + 1] = fn
	if M.state ~= nil then
		local ok, err = pcall(fn, M.state)
		if not ok then
			warn("subscriber error: " .. tostring(err))
		end
	end
	return function()
		for i, sub in ipairs(_subs) do
			if sub == fn then
				table.remove(_subs, i)
				return
			end
		end
	end
end

--- Fetch now. With { force = true } the timer is ignored, the 429 backoff is not.
---@return boolean started
function M.refresh(_args)
	if not _setup or _inflight then
		return false
	end
	local t = now()
	if _backoff:blocked(t) then
		local st = shallow_copy(M.state or { scoped = {} })
		st.error = { code = "rate_limited", message = "backing off", retry_at = _backoff.until_at, at = t }
		set_state(st)
		return false
	end
	if _timer then
		_timer:stop()
	end
	tick()
	return true
end

--- Stop timers and forget subscribers.
function M.stop()
	if _timer then
		_timer:stop()
		_timer = nil
	end
	if _redraw_timer then
		_redraw_timer:stop()
		_redraw_timer = nil
	end
	if _sessions_timer then
		_sessions_timer:stop()
		_sessions_timer = nil
	end
	_samples = nil
	_sessions = nil
	_next_fetch_at = nil
	_last_api = nil
	_last_api_at = nil
	_subs = {}
	_inflight = false
	_setup = false
	_last_good = nil
	_creds = nil
	_notifier = nil
	M.state = nil
end

--- Internal: expose the backoff for the popup ("retry in …").
function M.backoff()
	return _backoff
end

--- History samples (empty when history is off).
function M.samples()
	return _samples or {}
end

--- Last sessions summary.
function M.sessions()
	return _sessions
end

return M
