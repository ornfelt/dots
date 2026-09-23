-- format.lua - text and colour helpers for the bar and the popup (pure Lua).

local prefix = (...):match("^(.*%.)") or ""
local timeparse = require(prefix .. "timeparse")
local normalize = require(prefix .. "normalize")
local brand = require(prefix .. "brand")

local M = {}

M.relative = timeparse.relative
M.age = timeparse.age
M.absolute = timeparse.absolute
M.has_data = normalize.has_data

local LEVEL_RANK = { normal = 0, warn = 1, crit = 2 }
M.LEVEL_RANK = LEVEL_RANK

--- Round half up to an integer.
function M.round(x)
	return math.floor(x + 0.5)
end

--- Threshold level for a percentage.
---@param pct number|nil
---@param thresholds { warn: number, crit: number }
---@return "normal"|"warn"|"crit"
function M.level_for(pct, thresholds)
	if type(pct) ~= "number" then
		return "normal"
	end
	if pct >= (thresholds.crit or 90) then
		return "crit"
	elseif pct >= (thresholds.warn or 75) then
		return "warn"
	end
	return "normal"
end

--- Look up a window by key: "five_hour", "seven_day" or "scoped:<name>".
---@param st table|nil
---@param key string
---@return table|nil
function M.window(st, key)
	if type(st) ~= "table" or type(key) ~= "string" then
		return nil
	end
	if key == "five_hour" or key == "seven_day" then
		return st[key]
	end
	local name = key:match("^scoped:(.+)$")
	if name then
		for _, w in ipairs(st.scoped or {}) do
			if w.name == name then
				return w
			end
		end
	end
	return nil
end

--- Percentage that drives colours: the highest window, or the one named by opts.color_window.
---@param st table|nil
---@param opts table|nil
---@return number|nil
function M.max_percent(st, opts)
	if type(st) ~= "table" then
		return nil
	end
	local which = opts and opts.color_window or "max"
	if which ~= "max" then
		local w = M.window(st, which)
		return w and w.percent or nil
	end
	local best = nil
	local function consider(w)
		if type(w) == "table" and type(w.percent) == "number" and (best == nil or w.percent > best) then
			best = w.percent
		end
	end
	consider(st.five_hour)
	consider(st.seven_day)
	for _, w in ipairs(st.scoped or {}) do
		consider(w)
	end
	return best
end

--- Overall level of a state.
function M.state_level(st, thresholds, opts)
	return M.level_for(M.max_percent(st, opts), thresholds)
end

--- Colour for the bar text, or nil to inherit the container's foreground.
--- Precedence: error without data > crit > warn > stale > normal.
---@param st table|nil
---@param opts table resolved options
---@return string|nil
function M.color_for(st, opts)
	local colors = opts.colors or {}
	if not M.has_data(st) then
		if st and st.error then
			return colors.error
		end
		return colors.normal
	end
	local level = M.state_level(st, opts.thresholds or {}, opts)
	if level == "crit" then
		return colors.crit
	elseif level == "warn" then
		return colors.warn
	elseif st.stale and colors.stale then
		return colors.stale
	end
	return colors.normal
end

local SHORT_ERROR = {
	unauthorized = "!auth",
	no_credentials = "!cred",
	rate_limited = "!429",
	network = "!net",
	parse = "!parse",
	no_source = "!none",
}

--- Short bar label for an error code.
function M.short_error(code)
	return SHORT_ERROR[code] or "!err"
end

local function pct_text(w)
	if type(w) == "table" and type(w.percent) == "number" then
		return string.format("%d%%", M.round(w.percent))
	end
	return "--"
end

--- First letter of a model name, to keep the bar short ("Fable" -> "F").
local function short_name(name)
	return tostring(name):match("^[%z\1-\127\194-\244][\128-\191]*") or tostring(name)
end

--- Plain text for the bar (no markup; the widget escapes it).
---@param st table|nil
---@param opts table resolved options
---@return string
function M.bar_text(st, opts)
	if type(opts.format) == "function" then
		local ok, text = pcall(opts.format, st, M)
		if ok and type(text) == "string" then
			return text
		end
	end
	local glyph = opts.show_glyph and (opts.glyph .. " ") or ""
	if st == nil then
		return glyph .. "…"
	end
	if not M.has_data(st) then
		local eg = opts.show_glyph and (opts.error_glyph .. " ") or ""
		if st.error then
			return eg .. M.short_error(st.error.code)
		end
		return glyph .. "--"
	end
	local parts = {}
	if not opts.compact then
		for _, key in ipairs(opts.bar_windows or { "five_hour", "seven_day", "scoped" }) do
			if key == "scoped" then
				for _, w in ipairs(st.scoped or {}) do
					parts[#parts + 1] = short_name(w.name) .. " " .. pct_text(w)
				end
			else
				local name = key:match("^scoped:(.+)$")
				local label = key == "five_hour" and "5h" or key == "seven_day" and "7d" or name and short_name(name) or key
				parts[#parts + 1] = label .. " " .. pct_text(M.window(st, key))
			end
		end
	end
	local text = glyph .. table.concat(parts, opts.separator or " · ")
	local spending = st.spend and st.spend.enabled and ((st.spend.percent or 0) > 0 or (st.spend.used or 0) > 0)
	if opts.spend_in_bar and spending then
		local amount = (st.spend.used or 0) > 0 and M.money(st.spend.used, st.spend.currency):gsub(" ", "")
			or string.format("%d%%", M.round(st.spend.percent or 0))
		text = text .. (opts.spend_flag or (" +" .. amount))
	end
	if opts.sessions_in_bar and st.sessions and (st.sessions.attention or 0) > 0 then
		text = text .. (opts.attention_flag or " !")
	end
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- One line for the active session's context window, nil when unknown.
---@param ctx table|nil
---@return string|nil
function M.context_text(ctx)
	if type(ctx) ~= "table" or type(ctx.percent) ~= "number" then
		return nil
	end
	local size = ""
	if ctx.size and ctx.size >= 1000 then
		size = ctx.size >= 1000000 and string.format(" of %.0fM", ctx.size / 1000000)
			or string.format(" of %dk", math.floor(ctx.size / 1000))
	end
	local model = ctx.model and (" (" .. tostring(ctx.model) .. ")") or ""
	return string.format("Active session: %d%%%s context%s", M.round(ctx.percent), size, model)
end

--- Text and level for a forecast (see history.forecast).
---@param fc table|nil
---@param now integer
---@return string|nil text
---@return string level "normal"|"warn"|"crit"
function M.forecast_text(fc, now)
	if type(fc) ~= "table" then
		return nil, "normal"
	end
	if fc.exhaust_at and fc.exhaust_at <= now then
		return "limit reached", "crit"
	end
	if fc.exhaust_at then
		local left = fc.exhaust_at - now
		local level = left < 3600 and "crit" or "warn"
		return "at this pace empty in " .. (timeparse.relative(fc.exhaust_at, now) or "?"), level
	end
	if fc.at_reset then
		if fc.rate == 0 then
			return "no usage lately", "normal"
		end
		return string.format("at this pace ~%d%% at reset", M.round(fc.at_reset)), "normal"
	end
	if fc.rate and fc.rate > 0 then
		return string.format("+%.1f%%/h", fc.rate * 3600), "normal"
	end
	return nil, "normal"
end

--- One line describing the running Claude Code sessions.
---@param sessions table|nil summary from sessions.read
---@return string|nil
function M.sessions_text(sessions)
	if type(sessions) ~= "table" then
		return nil
	end
	if sessions.total == 0 then
		return "no Claude Code session running"
	end
	local parts = {}
	if sessions.attention > 0 then
		parts[#parts + 1] = sessions.attention .. " need" .. (sessions.attention == 1 and "s" or "") .. " your attention"
	end
	if sessions.working > 0 then
		parts[#parts + 1] = sessions.working .. " working"
	end
	if sessions.idle > 0 then
		parts[#parts + 1] = sessions.idle .. " idle"
	end
	return string.format("%d session%s: %s", sessions.total, sessions.total == 1 and "" or "s", table.concat(parts, ", "))
end

--- Human readable money amount.
function M.money(amount, currency)
	if type(amount) ~= "number" then
		return nil
	end
	currency = currency or "USD"
	if currency == "USD" then
		return string.format("$%.2f", amount)
	elseif currency == "EUR" then
		return string.format("%.2f €", amount)
	end
	return string.format("%.2f %s", amount, currency)
end

local SOURCE_NAME = { api = "API", statusline = "statusLine", claude_json = "claude.json cache" }

--- Human readable error message for the popup.
function M.error_text(err, now)
	if type(err) ~= "table" then
		return nil
	end
	local code = err.code
	if code == "unauthorized" then
		return "Token expired or rejected – run any `claude` command to refresh"
	elseif code == "no_credentials" then
		return "No Claude Code credentials found – log in with `claude`"
	elseif code == "rate_limited" then
		local rem = err.retry_at and timeparse.relative(err.retry_at, now)
		return "Rate limited (429)" .. (rem and (", retry in " .. rem) or "")
	elseif code == "network" then
		return "Network error" .. (err.message and (": " .. err.message) or "")
	elseif code == "parse" then
		return "Unexpected response" .. (err.message and (": " .. err.message) or "")
	elseif code == "no_source" then
		return "No data source available"
	end
	return err.message or tostring(code)
end

local function window_line(label, w, now)
	if not w then
		return nil
	end
	local parts = { string.format("%s: %d%%", label, M.round(w.percent)) }
	if w.assumed then
		parts[#parts + 1] = "no usage yet"
	elseif w.resets_at then
		local d = w.resets_at - now
		if d > 8 * 86400 or d < -86400 then
			parts[#parts + 1] = "resets at " .. timeparse.absolute(w.resets_at)
		elseif d < 0 then
			parts[#parts + 1] = "reset due"
		else
			parts[#parts + 1] = "resets in " .. timeparse.relative(w.resets_at, now)
		end
	end
	local line = table.concat(parts, " – ")
	if w.is_active then
		line = line .. " *"
	end
	return line
end

--- Lines for the details popup. The first line is the title.
---@param st table|nil
---@param now integer
---@param opts table|nil resolved options
---@return string[]
function M.popup_lines(st, now, opts)
	opts = opts or {}
	local lines = {}
	local title = "Claude usage"
	if st and st.subscription then
		title = title .. " (" .. tostring(st.subscription) .. ")"
	end
	lines[#lines + 1] = title

	if st == nil then
		lines[#lines + 1] = "Loading…"
		return lines
	end

	if M.has_data(st) then
		local fcs = st.forecast or {}
		local function add_forecast(fc)
			local text = M.forecast_text(fc, now)
			if text then
				lines[#lines + 1] = "    " .. text
			end
		end
		lines[#lines + 1] = window_line("Session (5h)", st.five_hour, now) or "Session (5h): --"
		add_forecast(fcs.five_hour)
		lines[#lines + 1] = window_line("Weekly (7d)", st.seven_day, now) or "Weekly (7d): --"
		add_forecast(fcs.seven_day)
		if opts.popup_show_scoped ~= false then
			for _, w in ipairs(st.scoped or {}) do
				lines[#lines + 1] = "  " .. window_line(w.name or "Model", w, now)
			end
		end
		if opts.popup_show_breakdown ~= false and st.breakdown then
			local parts = {}
			for _, r in ipairs(st.breakdown) do
				if r.percent > 0 then
					parts[#parts + 1] = string.format("%s %d%%", r.name, M.round(r.percent))
				end
			end
			if #parts > 0 then
				lines[#lines + 1] = "Weekly by surface: " .. table.concat(parts, ", ")
			end
		end
		if opts.popup_show_spend ~= false and st.spend and st.spend.enabled then
			local used = M.money(st.spend.used, st.spend.currency)
			local limit = M.money(st.spend.limit, st.spend.currency)
			local text = "Extra usage: "
			if used and limit then
				text = text .. used .. " / " .. limit
			elseif used then
				text = text .. used
			end
			text = text .. string.format(" (%d%%)", M.round(st.spend.percent or 0))
			lines[#lines + 1] = text
		end
	else
		lines[#lines + 1] = "No usage data"
	end

	local context_line = M.context_text(st.context)
	if context_line then
		lines[#lines + 1] = context_line
	end
	local sessions_line = M.sessions_text(st.sessions)
	if sessions_line then
		lines[#lines + 1] = sessions_line
	end
	lines[#lines + 1] = ""
	if st.fetched_at then
		local src = SOURCE_NAME[st.source] or tostring(st.source or "unknown")
		local line = "via " .. src .. ", " .. timeparse.age(st.fetched_at, now)
		if st.stale then
			line = line .. " (stale)"
		end
		lines[#lines + 1] = line
	end
	if st.error then
		local prefix_text = M.has_data(st) and "Last check failed: " or ""
		lines[#lines + 1] = prefix_text .. (M.error_text(st.error, now) or "error")
	end
	if st.next_fetch_at then
		lines[#lines + 1] = "Next check in " .. (timeparse.relative(st.next_fetch_at, now) or "?")
	end
	return lines
end

--- Background colour of the chip (style = "chip").
---@param st table|nil
---@param opts table resolved options
---@return string
function M.chip_color(st, opts)
	local chip = opts.chip or {}
	if not M.has_data(st) then
		if st and st.error then
			return chip.error or brand.palette.error
		end
		return chip.normal or brand.palette.orange
	end
	return brand.level_color(M.state_level(st, opts.thresholds or {}, opts), chip)
end

local SUBSCRIPTION_NAME = { max = "Max", pro = "Pro", team = "Team", enterprise = "Enterprise", free = "Free" }

--- Human readable plan name.
function M.plan_name(subscription)
	if type(subscription) ~= "string" or subscription == "" then
		return nil
	end
	return (SUBSCRIPTION_NAME[subscription:lower()] or subscription) .. " plan"
end

local function reset_text(w, now)
	if w and w.assumed then
		return "no usage yet"
	end
	if not w or not w.resets_at then
		return nil
	end
	local d = w.resets_at - now
	if d > 8 * 86400 or d < -86400 then
		return "resets at " .. timeparse.absolute(w.resets_at)
	elseif d < 0 then
		return "reset due"
	end
	return "resets in " .. timeparse.relative(w.resets_at, now)
end

--- Structured content for the graphical popup.
---@param st table|nil
---@param now integer
---@param opts table resolved options
---@return table rows  { title, subtitle, windows = { {label, sub, percent, level, reset, active} }, spend, breakdown, footer, error, stale }
function M.popup_rows(st, now, opts)
	opts = opts or {}
	local thresholds = opts.thresholds or {}
	local rows = { title = "Claude usage", windows = {}, footer = {} }

	if st == nil then
		rows.subtitle = "Loading…"
		return rows
	end

	local sub = {}
	local plan = M.plan_name(st.subscription)
	if plan then
		sub[#sub + 1] = plan
	end
	if st.fetched_at then
		local src = SOURCE_NAME[st.source] or tostring(st.source or "?")
		sub[#sub + 1] = "via " .. src .. " " .. timeparse.age(st.fetched_at, now)
	end
	if st.stale then
		sub[#sub + 1] = "stale"
	end
	rows.subtitle = table.concat(sub, " · ")
	rows.stale = st.stale or false

	if M.has_data(st) then
		local fcs = st.forecast or {}
		local paces = st.pace or {}
		local function add(key, label, subtext, w, fc, pace)
			local ftext, flevel = M.forecast_text(fc, now)
			rows.windows[#rows.windows + 1] = {
				key = key,
				label = label,
				sub = subtext,
				percent = w and w.percent or nil,
				level = w and M.level_for(w.percent, thresholds) or "normal",
				reset = reset_text(w, now),
				active = w and w.is_active or false,
				forecast = ftext,
				forecast_level = flevel,
				pace = pace,
			}
		end
		add("five_hour", "Session", "5-hour window", st.five_hour, fcs.five_hour, paces.five_hour)
		add("seven_day", "Weekly", "7-day window", st.seven_day, fcs.seven_day, paces.seven_day)
		if opts.popup_show_scoped ~= false then
			for _, w in ipairs(st.scoped or {}) do
				local name = w.name or "Model"
				add("scoped:" .. name, name, "weekly, this model", w, (fcs.scoped or {})[name], nil)
			end
		end
		if opts.popup_show_spend ~= false and st.spend and st.spend.enabled then
			local used = M.money(st.spend.used, st.spend.currency)
			local limit = M.money(st.spend.limit, st.spend.currency)
			local text = used and limit and (used .. " of " .. limit) or used or nil
			local level = "normal"
			if thresholds.spend and (st.spend.percent or 0) >= thresholds.spend then
				level = "warn"
			end
			rows.spend = { label = "Extra usage", text = text, percent = st.spend.percent or 0, level = level }
		end
		if opts.popup_show_breakdown ~= false and st.breakdown then
			local parts = {}
			for _, r in ipairs(st.breakdown) do
				if r.percent > 0 then
					parts[#parts + 1] = string.format("%s %d%%", r.name, M.round(r.percent))
				end
			end
			if #parts > 0 then
				rows.breakdown = table.concat(parts, " · ")
			end
		end
	else
		rows.empty = "No usage data"
	end

	rows.context = M.context_text(st.context)
	if st.sessions then
		rows.sessions = {
			text = M.sessions_text(st.sessions),
			attention = st.sessions.attention or 0,
			list = st.sessions.list,
		}
	end
	if st.error then
		rows.error = M.error_text(st.error, now)
	end
	if st.next_fetch_at then
		rows.footer[#rows.footer + 1] = "next check in " .. (timeparse.relative(st.next_fetch_at, now) or "?")
	end
	return rows
end

return M
