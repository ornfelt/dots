-- history.lua - usage samples on disk, burn rate, forecast and pacing (pure Lua).
--
-- File format: one CSV line per sample, "epoch,key,percent,resets_at" where key is
-- "five_hour", "seven_day" or "scoped:<name>", and resets_at may be empty.

local M = {}

M.MAX_SAMPLES = 4000
M.MAX_AGE = 8 * 86400
M.LOOKBACK = { five_hour = 2 * 3600, seven_day = 24 * 3600, scoped = 24 * 3600 }
-- Seconds between the first and last sample before a rate is trusted. Short spans on the
-- weekly window would extrapolate a few busy minutes into a whole week.
M.MIN_SPAN = { five_hour = 900, seven_day = 3 * 3600, scoped = 3 * 3600 }

local function parse_line(line)
	local t, key, pct, resets = line:match("^(%d+),([^,]+),([%d%.%-]+),(%d*)%s*$")
	if not t then
		return nil
	end
	return { t = tonumber(t), key = key, percent = tonumber(pct), resets_at = tonumber(resets) }
end

--- Load samples from disk (missing file -> empty list).
---@param path string
---@return table samples sorted by time
function M.load(path)
	local samples = {}
	local f = io.open(path, "r")
	if not f then
		return samples
	end
	for line in f:lines() do
		local s = parse_line(line)
		if s then
			samples[#samples + 1] = s
		end
	end
	f:close()
	table.sort(samples, function(a, b)
		return a.t < b.t
	end)
	return samples
end

local function windows_of(state)
	local out = {}
	if state.five_hour then
		out[#out + 1] = { key = "five_hour", w = state.five_hour }
	end
	if state.seven_day then
		out[#out + 1] = { key = "seven_day", w = state.seven_day }
	end
	for _, s in ipairs(state.scoped or {}) do
		if s.name then
			out[#out + 1] = { key = "scoped:" .. s.name:gsub(",", " "), w = s }
		end
	end
	return out
end

local function write_all(path, samples)
	local f = io.open(path, "w")
	if not f then
		return false
	end
	for _, s in ipairs(samples) do
		f:write(string.format("%d,%s,%s,%s\n", s.t, s.key, tostring(s.percent), s.resets_at and tostring(s.resets_at) or ""))
	end
	f:close()
	return true
end

--- Record the windows of a state. Appends to `samples` in memory and to the file;
--- rewrites the file (pruning old samples) when it grows large.
---@param path string
---@param samples table in-memory list from load()
---@param state table
---@param now integer
---@return boolean written
function M.append(path, samples, state, now)
	local new = {}
	for _, item in ipairs(windows_of(state)) do
		if type(item.w.percent) == "number" then
			new[#new + 1] = { t = now, key = item.key, percent = item.w.percent, resets_at = item.w.resets_at }
		end
	end
	if #new == 0 then
		return false
	end
	for _, s in ipairs(new) do
		samples[#samples + 1] = s
	end
	if #samples > M.MAX_SAMPLES then
		local kept = {}
		for _, s in ipairs(samples) do
			if s.t >= now - M.MAX_AGE then
				kept[#kept + 1] = s
			end
		end
		for i = #samples, 1, -1 do
			samples[i] = nil
		end
		for i, s in ipairs(kept) do
			samples[i] = s
		end
		return write_all(path, samples)
	end
	local f = io.open(path, "a")
	if not f then
		return false
	end
	for _, s in ipairs(new) do
		f:write(string.format("%d,%s,%s,%s\n", s.t, s.key, tostring(s.percent), s.resets_at and tostring(s.resets_at) or ""))
	end
	f:close()
	return true
end

--- Samples of one key since a point in time.
---@return table list of { t, percent, resets_at }
function M.series(samples, key, since)
	local out = {}
	for _, s in ipairs(samples) do
		if s.key == key and s.t >= since then
			out[#out + 1] = s
		end
	end
	return out
end

local function same_cycle(a, b)
	if a == nil or b == nil then
		return true
	end
	return math.abs(a - b) <= 120
end

--- Burn rate in percent per second for a window, from samples within `lookback`
--- that belong to the same reset cycle. nil when there is not enough data.
---@param samples table
---@param key string
---@param now integer
---@param lookback integer seconds
---@param resets_at integer|nil current reset time of the window
---@return number|nil
function M.rate(samples, key, now, lookback, resets_at)
	local first, last
	for _, s in ipairs(samples) do
		if s.key == key and s.t >= now - lookback and s.t <= now and same_cycle(s.resets_at, resets_at) then
			if not first or s.t < first.t then
				first = s
			end
			if not last or s.t > last.t then
				last = s
			end
		end
	end
	local min_span = M.MIN_SPAN[key] or M.MIN_SPAN[key:match("^scoped") and "scoped" or "five_hour"] or 900
	if not first or not last or last.t - first.t < min_span then
		return nil
	end
	local dp = last.percent - first.percent
	if dp <= 0 then
		return 0
	end
	return dp / (last.t - first.t)
end

--- Project a window forward at the given rate.
---@param w table { percent, resets_at }
---@param rate number|nil percent per second
---@param now integer
---@return table|nil { rate, at_reset = percent expected at reset (nil without resets_at), exhaust_at = epoch or nil }
function M.forecast(w, rate, now)
	if not w or type(w.percent) ~= "number" then
		return nil
	end
	if w.percent >= 100 then
		return { rate = rate, exhaust_at = now } -- used up, whatever the rate
	end
	if rate == nil then
		return nil
	end
	local out = { rate = rate }
	if rate > 0 then
		out.exhaust_at = now + math.floor((100 - w.percent) / rate)
	end
	if w.resets_at and w.resets_at > now then
		out.at_reset = math.min(w.percent + rate * (w.resets_at - now), 999)
		if out.exhaust_at and out.exhaust_at >= w.resets_at then
			out.exhaust_at = nil -- resets before it runs out
		end
	end
	return out
end

--- Percent a window "should" be at for an even spread over its length.
---@param w table { resets_at }
---@param length integer window length in seconds (5h or 7d)
---@param now integer
---@return number|nil
function M.pace(w, length, now)
	if not w or not w.resets_at or length <= 0 then
		return nil
	end
	local elapsed = length - (w.resets_at - now)
	if elapsed < 0 or elapsed > length then
		return nil
	end
	return elapsed / length * 100
end

return M
