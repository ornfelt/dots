-- awesome-claude-usage - AwesomeWM wibar widget showing Claude Code rate-limit usage.
--
--   local claude_usage = require("claude_usage")
--   local w = claude_usage.new({ thresholds = { warn = 70, crit = 90 } })
--
-- Public surface:
--   claude_usage.new(opts)        -> wibox widget (also claude_usage(opts))
--   claude_usage.setup(opts)      -> start polling without a widget
--   claude_usage.state            -> current state table or nil
--   claude_usage.subscribe(fn)    -> fn(state) now and on every update; returns an unsubscribe function
--   claude_usage.refresh({force}) -> fetch now (the 429 backoff is still honoured)
--   claude_usage.stop()
--   claude_usage.format           -> text helpers (popup_lines, bar_text, relative, ...)

local prefix = (...) .. "."
local config = require(prefix .. "config")
local model = require(prefix .. "model")
local format = require(prefix .. "format")
local widget = require(prefix .. "widget")

local M = {
	version = config.version,
	format = format,
	model = model,
	opts = nil,
}

local function warn(msg)
	local ok, gears = pcall(require, "gears")
	if ok then
		gears.debug.print_warning("claude_usage: " .. msg)
	else
		io.stderr:write("claude_usage: " .. msg .. "\n")
	end
end

--- Watch the cache file's directory with inotifywait; calls cb on every rewrite.
local function watch_file(path, cb)
	local awful = require("awful")
	local dir, name = path:match("^(.*)/([^/]+)$")
	if not dir then
		return
	end
	os.execute('mkdir -p "' .. dir .. '" 2>/dev/null')
	local pid = awful.spawn.with_line_callback({
		"inotifywait",
		"-m",
		"-q",
		"-e",
		"close_write,moved_to",
		"--format",
		"%f",
		dir,
	}, {
		stdout = function(line)
			if line == name then
				cb()
			end
		end,
		exit = function(reason, code)
			if reason == "exit" and code ~= 0 then
				warn("inotifywait exited with code " .. tostring(code) .. "; cache watch off")
			end
		end,
	})
	if type(pid) ~= "number" then
		error("cannot start inotifywait: " .. tostring(pid))
	end
	awesome.connect_signal("exit", function()
		awesome.kill(pid, 9)
	end)
end

local function real_deps()
	local awful = require("awful")
	local gears = require("gears")
	local naughty = require("naughty")
	return {
		watch = watch_file,
		now = os.time,
		spawn = function(argv, cb)
			awful.spawn.easy_async(argv, cb)
		end,
		timer = function(args)
			return gears.timer(args)
		end,
		notify = function(args)
			if naughty.notification then
				naughty.notification(args)
			else
				-- awesome 4.3 stable has no notification object API
				naughty.notify({
					title = args.title,
					text = args.message,
					timeout = args.timeout,
					icon = args.icon,
					preset = args.urgency == "critical" and naughty.config.presets.critical or nil,
				})
			end
		end,
		warn = warn,
	}
end

--- Resolve options and start the model. Idempotent; later calls return the first resolved options.
---@param opts table|nil
---@return table resolved options
function M.setup(opts)
	if M.opts then
		if opts and next(opts) ~= nil then
			warn("setup() called again with options; the first options stay in effect")
		end
		return M.opts
	end
	M.opts = config.resolve(opts, warn)
	model.setup(M.opts, real_deps())
	return M.opts
end

local _widgets = {}

--- Create the wibar widget (starts polling on first use).
---@param opts table|nil
---@return table widget
function M.new(opts)
	local resolved = M.setup(opts)
	local w = widget.new(model, resolved)
	_widgets[#_widgets + 1] = w
	return w
end

--- Pin or unpin the popup without the mouse (bind it to a key). Prefers the widget on the
--- focused screen and places the popup next to it; falls back to the centre of the
--- focused screen when no widget position is known yet.
function M.toggle_popup()
	local awful = require("awful")
	local focused = awful.screen.focused()
	local target, geo = nil, nil
	for _, w in ipairs(_widgets) do
		local g = w.geometry_hint and w.geometry_hint() or nil
		if g and (not target or g.screen == focused) then
			target, geo = w, g
		end
	end
	target = target or _widgets[1]
	if not target or not target.popup then
		return false
	end
	if target.popup:is_pinned() then
		target.popup:hide()
		return false
	end
	if not geo then
		local g = focused.geometry
		geo = { x = g.x + g.width / 2, y = g.y + g.height / 2, width = 1, height = 1 }
	end
	target.popup:pin(geo)
	return true
end

--- Screen geometry of the created widgets (diagnostics; false before the first draw).
function M.widget_geometries()
	local out = {}
	for i, w in ipairs(_widgets) do
		local g = w.geometry_hint and w.geometry_hint() or nil
		if g and g.drawable then
			local wg = g.drawable:geometry()
			local bw = g.drawable.border_width or 0
			out[i] = { x = wg.x + bw + g.x, y = wg.y + bw + g.y, width = g.width, height = g.height,
				screen = g.screen and g.screen.index or nil }
		else
			out[i] = false
		end
	end
	return out
end

--- Close any pinned or open popup.
function M.hide_popup()
	for _, w in ipairs(_widgets) do
		if w.popup then
			w.popup:hide()
		end
	end
end

--- Entry point for contrib/claude-usage-hook.sh.
function M.hook(event, kind, session_id)
	return model.hook(event, kind, session_id)
end

--- Rescan ~/.claude/sessions now.
function M.refresh_sessions()
	return model.poll_sessions()
end

function M.subscribe(a, b)
	return model.subscribe(b or a)
end

function M.refresh(args)
	return model.refresh(args)
end

function M.stop()
	model.stop()
	M.opts = nil
	_widgets = {}
end

--- Diagnostic text for bug reports. Contains versions, effective options and the
--- current state, but never the token or account identifiers.
---@return string
function M.debug()
	local lines = { "awesome-claude-usage " .. M.version }
	local ok, awesome_ver = pcall(function()
		return awesome.version
	end)
	lines[#lines + 1] = "awesome " .. (ok and tostring(awesome_ver) or "?") .. ", " .. _VERSION
	local o = M.opts
	if o then
		lines[#lines + 1] = string.format(
			"options: style=%s icon=%s interval=%d sources=%s thresholds=%d/%d popup=%s",
			tostring(o.style),
			tostring(o.icon),
			o.interval,
			table.concat(o.sources, ","),
			o.thresholds.warn,
			o.thresholds.crit,
			tostring(o.popup)
		)
	else
		lines[#lines + 1] = "options: not set up"
	end
	local st = model.state
	if st then
		local b = model.backoff()
		lines[#lines + 1] = string.format(
			"state: source=%s fetched=%s stale=%s error=%s backoff_attempt=%s",
			tostring(st.source),
			st.fetched_at and os.date("%Y-%m-%d %H:%M:%S", st.fetched_at) or "nil",
			tostring(st.stale),
			st.error and (tostring(st.error.code) .. " (" .. tostring(st.error.message) .. ")") or "nil",
			b and tostring(b.attempt) or "?"
		)
		for _, line in ipairs(format.popup_lines(st, os.time(), o or {})) do
			lines[#lines + 1] = "  " .. line
		end
	else
		lines[#lines + 1] = "state: nil"
	end
	return table.concat(lines, "\n")
end

setmetatable(M, {
	__call = function(_, opts)
		return M.new(opts)
	end,
	__index = function(_, key)
		if key == "state" then
			return model.state
		end
		return nil
	end,
})

return M
