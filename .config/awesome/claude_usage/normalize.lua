-- normalize.lua - turn the three raw data formats into one canonical state table (pure Lua).
--
-- Canonical state (fields filled by model.lua are marked *):
--   five_hour  = { percent, resets_at, is_active } | nil
--   seven_day  = { percent, resets_at, is_active } | nil
--   scoped     = { { name, percent, resets_at, kind, is_active }, ... }
--   spend      = { enabled, percent, used, currency, limit } | nil
--   breakdown  = { { name, percent }, ... } | nil
--   fetched_at = epoch
--   source*, stale*, error*, next_fetch_at*, subscription*

local prefix = (...):match("^(.*%.)") or ""
local timeparse = require(prefix .. "timeparse")

local M = {}

local function percent(v)
	local n = tonumber(v)
	if n == nil then
		return nil
	end
	if n < 0 then
		n = 0
	end
	return n
end

local function window(pct, resets_at, extra)
	if pct == nil then
		return nil
	end
	local w = { percent = pct, resets_at = resets_at }
	for k, v in pairs(extra or {}) do
		w[k] = v
	end
	return w
end

local function money(obj)
	if type(obj) == "number" then
		return obj
	end
	if type(obj) ~= "table" or type(obj.amount_minor) ~= "number" then
		return nil
	end
	local exp = tonumber(obj.exponent) or 2
	return obj.amount_minor / (10 ^ exp)
end

local function spend_from(raw)
	local s = raw.spend
	if type(s) == "table" then
		local used = money(s.used)
		return {
			enabled = s.enabled == true,
			percent = percent(s.percent) or 0,
			used = used,
			currency = (type(s.used) == "table" and s.used.currency) or "USD",
			limit = money(s.limit),
		}
	end
	local e = raw.extra_usage
	if type(e) == "table" and e.is_enabled ~= nil then
		return {
			enabled = e.is_enabled == true,
			percent = percent(e.utilization) or 0,
			used = tonumber(e.used_credits),
			currency = e.currency or "USD",
			limit = tonumber(e.monthly_limit),
		}
	end
	return nil
end

local function breakdown_from(raw)
	local b = raw.seven_day_breakdown
	if type(b) ~= "table" or type(b.rows) ~= "table" then
		return nil
	end
	local rows = {}
	for _, r in ipairs(b.rows) do
		local pct = percent(r.percent)
		if pct and r.display_name then
			rows[#rows + 1] = { name = r.display_name, percent = pct }
		end
	end
	if #rows == 0 then
		return nil
	end
	return rows
end

--- Normalise a response of the OAuth usage endpoint (also the shape stored in ~/.claude.json).
---@param raw table
---@param now integer
---@return table state
function M.from_api(raw, now)
	local st = { scoped = {}, fetched_at = now }
	if type(raw) ~= "table" then
		return st
	end

	if type(raw.limits) == "table" then
		for _, l in ipairs(raw.limits) do
			if type(l) == "table" then
				local w = window(percent(l.percent), timeparse.iso8601(l.resets_at), {
					kind = l.kind,
					is_active = l.is_active == true,
				})
				if w then
					if l.kind == "session" then
						st.five_hour = st.five_hour or w
					elseif l.kind == "weekly_all" then
						st.seven_day = st.seven_day or w
					elseif l.kind == "weekly_scoped" then
						local model = type(l.scope) == "table" and l.scope.model or nil
						w.name = (type(model) == "table" and (model.display_name or model.id)) or nil
						if w.name then
							st.scoped[#st.scoped + 1] = w
						end
					end
				end
			end
		end
	end

	-- Legacy fields fill in whatever limits[] did not provide.
	if not st.five_hour and type(raw.five_hour) == "table" then
		st.five_hour = window(percent(raw.five_hour.utilization), timeparse.iso8601(raw.five_hour.resets_at))
	end
	if not st.seven_day and type(raw.seven_day) == "table" then
		st.seven_day = window(percent(raw.seven_day.utilization), timeparse.iso8601(raw.seven_day.resets_at))
	end
	if #st.scoped == 0 then
		for _, entry in ipairs({ { "Opus", "seven_day_opus" }, { "Sonnet", "seven_day_sonnet" } }) do
			local v = raw[entry[2]]
			if type(v) == "table" then
				local w = window(percent(v.utilization), timeparse.iso8601(v.resets_at), { name = entry[1] })
				if w then
					st.scoped[#st.scoped + 1] = w
				end
			end
		end
	end

	-- Scoped weekly windows share the weekly reset; fill it in when the API left it null.
	for _, w in ipairs(st.scoped) do
		if w.resets_at == nil and st.seven_day then
			w.resets_at = st.seven_day.resets_at
		end
	end

	st.spend = spend_from(raw)
	st.breakdown = breakdown_from(raw)
	return st
end

local function epoch_seconds(v)
	local n = tonumber(v)
	if n == nil then
		return nil
	end
	if n > 1e11 then
		n = n / 1000 -- milliseconds
	end
	return math.floor(n)
end

--- Normalise the file written by contrib/statusline-cache.sh (or a raw statusLine JSON).
---@param raw table  { ts?, rate_limits = { five_hour?, seven_day?, spend_limit? } }
---@param now integer
---@return table state
function M.from_statusline(raw, now)
	local st = { scoped = {}, fetched_at = now }
	if type(raw) ~= "table" then
		return st
	end
	local rl = type(raw.rate_limits) == "table" and raw.rate_limits or nil
	if rl then
		-- Claude Code drops a window from rate_limits once its reset time has passed and no new
		-- usage started it again, so a missing window next to a present one means "0 %, not started".
		for _, key in ipairs({ "five_hour", "seven_day" }) do
			if type(rl[key]) == "table" then
				st[key] = window(percent(rl[key].used_percentage), epoch_seconds(rl[key].resets_at))
			else
				st[key] = { percent = 0, resets_at = nil, assumed = true }
			end
		end
	end
	if rl and type(rl.spend_limit) == "table" and percent(rl.spend_limit.used_percentage) then
		st.spend = { enabled = true, percent = percent(rl.spend_limit.used_percentage), currency = "USD" }
	end
	local ts = epoch_seconds(raw.ts)
	if ts then
		st.fetched_at = ts
	end
	st.context = M.context_from(raw)
	return st
end

--- Active-session context window from the statusLine cache (nil when absent).
---@param raw table
---@return table|nil { percent, size, input_tokens, model, session_id, at }
function M.context_from(raw)
	if type(raw) ~= "table" then
		return nil
	end
	local c = raw.context
	if type(c) ~= "table" then
		return nil
	end
	local pct = percent(c.used_percentage)
	if pct == nil then
		return nil
	end
	return {
		percent = pct,
		size = tonumber(c.size),
		input_tokens = tonumber(c.input_tokens),
		model = raw.model,
		session_id = raw.session_id,
		at = epoch_seconds(raw.ts),
	}
end

--- Normalise the cachedUsageUtilization object of ~/.claude.json (or the whole file).
---@param raw table
---@param now integer
---@return table state
function M.from_claude_json(raw, now)
	if type(raw) ~= "table" then
		return { scoped = {}, fetched_at = now }
	end
	local cu = type(raw.cachedUsageUtilization) == "table" and raw.cachedUsageUtilization or raw
	local st = M.from_api(cu.utilization, now)
	local fetched = epoch_seconds(cu.fetchedAtMs)
	if fetched then
		st.fetched_at = fetched
	end
	return st
end

--- Whether the state carries at least one usage window.
---@param st table|nil
---@return boolean
function M.has_data(st)
	return type(st) == "table" and (st.five_hour ~= nil or st.seven_day ~= nil or (st.scoped and #st.scoped > 0))
		or false
end

return M
