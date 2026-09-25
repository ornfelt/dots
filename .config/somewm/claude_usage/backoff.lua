-- backoff.lua - exponential backoff state machine for failed fetches (pure Lua).

local Backoff = {}
Backoff.__index = Backoff

local M = {}

--- Create a backoff tracker.
---@param schedule integer[]  Delays in seconds for the 1st, 2nd, ... consecutive failure; the last repeats.
function M.new(schedule)
	return setmetatable({
		schedule = schedule or { 300, 600, 1200, 1800 },
		attempt = 0,
		until_at = nil,
	}, Backoff)
end

--- Register a failure and return the delay until the next attempt.
---@param now integer
---@return integer delay seconds
function Backoff:fail(now)
	self.attempt = math.min(self.attempt + 1, #self.schedule)
	local delay = self.schedule[self.attempt] or 300
	self.until_at = now + delay
	return delay
end

--- Forget all failures.
function Backoff:reset()
	self.attempt = 0
	self.until_at = nil
end

--- Whether fetching is currently blocked.
---@param now integer
---@return boolean
function Backoff:blocked(now)
	return self.until_at ~= nil and now < self.until_at
end

--- Seconds until fetching is allowed again (0 when not blocked).
---@param now integer
---@return integer
function Backoff:remaining(now)
	if not self:blocked(now) then
		return 0
	end
	return self.until_at - now
end

return M
