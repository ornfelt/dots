-- source/claude_json.lua - read cachedUsageUtilization from ~/.claude.json (Claude Code's own cache).

local root = (...):gsub("source%.[^%.]+$", "")
local json = require(root .. "json")

local M = {}

--- Read ~/.claude.json and return only the cachedUsageUtilization object.
---@param path string
---@return table|nil { fetchedAtMs, utilization }
function M.read(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("a")
	f:close()
	if not content or not content:find('"cachedUsageUtilization"', 1, true) then
		return nil
	end
	local ok, data = pcall(json.decode, content)
	if not ok or type(data) ~= "table" then
		return nil
	end
	local cu = data.cachedUsageUtilization
	if type(cu) ~= "table" or type(cu.utilization) ~= "table" then
		return nil
	end
	return cu
end

return M
