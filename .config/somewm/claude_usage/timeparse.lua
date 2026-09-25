-- timeparse.lua - ISO 8601 parsing and relative time formatting (pure Lua, no awesome deps).

local M = {}

--- Convert a broken-down UTC time table into an epoch timestamp.
--- os.time() always interprets its argument as local time, so the local/UTC
--- delta at that instant is measured and added back.
---@param f table  Fields year, month, day, hour, min, sec (UTC).
---@return integer|nil
local function epoch_from_utc_fields(f)
	f.isdst = nil
	local ok, guess = pcall(os.time, f)
	if not ok or type(guess) ~= "number" then
		return nil
	end
	local u = os.date("!*t", guess)
	u.isdst = nil
	local ok2, as_local = pcall(os.time, u)
	if not ok2 or type(as_local) ~= "number" then
		return nil
	end
	local offset = guess - as_local -- local minus UTC at that instant
	return guess + offset
end

--- Parse an ISO 8601 timestamp such as "2026-09-23T15:00:00.261688+00:00" or
--- "2026-07-26T15:50:00Z" into epoch seconds (integer, fractional part dropped).
---@param s any
---@return integer|nil
function M.iso8601(s)
	if type(s) ~= "string" then
		return nil
	end
	local year, month, day, hour, min, rest = s:match("^%s*(%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](%d%d):(%d%d)(.*)$")
	if not year then
		return nil
	end
	local sec = 0
	local secs, after = rest:match("^:(%d%d)(.*)$")
	if secs then
		sec = tonumber(secs)
		rest = after
	end
	rest = rest:gsub("^[%.,]%d+", "") -- fractional seconds
	rest = rest:gsub("%s+$", "")
	local offset
	if rest == "" or rest == "Z" or rest == "z" then
		offset = 0
	else
		local sign, oh, om = rest:match("^([%+%-])(%d%d):?(%d%d)$")
		if not sign then
			return nil
		end
		offset = (tonumber(oh) * 3600 + tonumber(om) * 60) * (sign == "-" and -1 or 1)
	end
	local epoch = epoch_from_utc_fields({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = sec,
	})
	if not epoch then
		return nil
	end
	return epoch - offset
end

--- Format the duration from `now` until `target` as a short string.
--- Examples: "2h 14m", "3d 4h", "43m", "now", "expired".
---@param target integer|nil epoch seconds
---@param now integer epoch seconds
---@return string|nil  nil when target is nil
function M.relative(target, now)
	if type(target) ~= "number" then
		return nil
	end
	local d = target - now
	if d < 0 then
		return "expired"
	end
	if d < 60 then
		return "now"
	end
	local days = math.floor(d / 86400)
	local hours = math.floor((d % 86400) / 3600)
	local mins = math.floor((d % 3600) / 60)
	if days > 0 then
		return string.format("%dd %dh", days, hours)
	elseif hours > 0 then
		return string.format("%dh %dm", hours, mins)
	end
	return string.format("%dm", mins)
end

--- Format how long ago `then_` was, e.g. "just now", "3 min ago", "2 h ago", "1 d ago".
---@param then_ integer|nil epoch seconds
---@param now integer
---@return string
function M.age(then_, now)
	if type(then_) ~= "number" then
		return "unknown age"
	end
	local d = now - then_
	if d < 60 then
		return "just now"
	elseif d < 3600 then
		return string.format("%d min ago", math.floor(d / 60))
	elseif d < 86400 then
		return string.format("%d h ago", math.floor(d / 3600))
	end
	return string.format("%d d ago", math.floor(d / 86400))
end

--- Local wall-clock representation of an epoch, e.g. "2026-09-23 17:00".
---@param epoch integer
---@return string
function M.absolute(epoch)
	return os.date("%Y-%m-%d %H:%M", epoch)
end

return M
