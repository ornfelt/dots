-- notify.lua - desktop notifications on threshold crossings (pure logic; deps.notify does the display).

local prefix = (...):match("^(.*%.)") or ""
local format = require(prefix .. "format")
local normalize = require(prefix .. "normalize")

local Notifier = {}
Notifier.__index = Notifier

local M = {}

---@param opts table resolved options
---@param deps table { notify = fun(args) }
function M.new(opts, deps)
	return setmetatable({
		opts = opts,
		deps = deps,
		windows = {}, -- key -> { level, percent, resets_at }
		fail_count = 0,
		error_notified = false,
		last_attention = {}, -- session key -> epoch of the last attention notification
	}, Notifier)
end

local ATTENTION_WINDOW = 60

--- Announce that a session needs the user; repeats within a minute are dropped.
---@param session table|nil { name, pid, session_id }
---@param now integer
---@return boolean sent
function Notifier:attention(session, now)
	if not self.opts.notify_attention then
		return false
	end
	local key = session and (session.session_id or session.pid or session.name) or "unknown"
	local last = self.last_attention[key]
	if last and now - last < ATTENTION_WINDOW then
		return false
	end
	self.last_attention[key] = now
	local name = session and (session.name or (session.pid and ("pid " .. tostring(session.pid)))) or "A session"
	self:emit({ title = "Claude Code", message = name .. " needs your attention", urgency = "normal" })
	return true
end

function Notifier:emit(args)
	if type(self.deps.notify) ~= "function" then
		return
	end
	args.title = args.title or "Claude usage"
	args.timeout = self.opts.notify_timeout
	args.icon = self.opts.notify_icon
	args.app_name = "claude_usage"
	pcall(self.deps.notify, args)
end

function Notifier:check_window(key, label, w, now)
	local rank = format.LEVEL_RANK
	local level = format.level_for(w.percent, self.opts.thresholds)
	local stored = self.windows[key]

	if stored then
		local reset = (stored.resets_at ~= nil and now > stored.resets_at)
			or (w.resets_at ~= nil and stored.resets_at ~= nil and w.resets_at > stored.resets_at)
			or (stored.percent - w.percent > 20)
		if reset then
			if self.opts.notify_reset and stored.level ~= "normal" and level == "normal" then
				self:emit({ message = label .. " window reset, now at " .. format.round(w.percent) .. "%" })
			end
			stored = nil
		end
	end
	stored = stored or { level = "normal", percent = w.percent, resets_at = w.resets_at }

	if rank[level] > rank[stored.level] and self.opts.notify_threshold then
		local msg = string.format("%s at %d%%", label, format.round(w.percent))
		local rel = w.resets_at and format.relative(w.resets_at, now)
		if rel then
			msg = msg .. " (resets in " .. rel .. ")"
		end
		self:emit({ message = msg, urgency = level == "crit" and "critical" or "normal" })
	end

	stored.level = level
	stored.percent = w.percent
	stored.resets_at = w.resets_at or stored.resets_at
	self.windows[key] = stored
end

--- Announce session transitions (see sessions.diff).
---@param events table
function Notifier:sessions(events, now)
	now = now or os.time()
	for _, ev in ipairs(events or {}) do
		local name = ev.session and (ev.session.name or ("pid " .. tostring(ev.session.pid))) or "a session"
		if ev.kind == "attention" then
			self:attention(ev.session, now)
		elseif ev.kind == "finished" and self.opts.notify_finished then
			self:emit({ title = "Claude Code", message = name .. " finished", urgency = "low" })
		end
	end
end

--- Feed a new state. Safe to call repeatedly with the same data.
---@param st table|nil
---@param now integer
function Notifier:update(st, now)
	if type(st) ~= "table" then
		return
	end
	local has = normalize.has_data(st)
	if has then
		self.fail_count = 0
		self.error_notified = false
	elseif st.error then
		self.fail_count = self.fail_count + 1
		if self.opts.notify_error and self.fail_count >= 3 and not self.error_notified then
			self:emit({ message = format.error_text(st.error, now) or "usage fetch failed", urgency = "normal" })
			self.error_notified = true
		end
		return
	else
		return
	end

	if st.five_hour then
		self:check_window("five_hour", "Session (5h)", st.five_hour, now)
	end
	if st.seven_day then
		self:check_window("seven_day", "Weekly (7d)", st.seven_day, now)
	end
	for _, s in ipairs(st.scoped or {}) do
		local name = s.name or "model"
		self:check_window("scoped:" .. name, "Weekly (" .. name .. ")", s, now)
	end
	if st.spend and st.spend.enabled and self.opts.thresholds.spend then
		local pseudo = { percent = st.spend.percent or 0 }
		local saved = self.opts.thresholds
		self.opts.thresholds = { warn = saved.spend, crit = math.huge }
		self:check_window("spend", "Extra usage", pseudo, now)
		self.opts.thresholds = saved
	end
end

return M
