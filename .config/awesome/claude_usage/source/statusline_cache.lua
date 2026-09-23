-- source/statusline_cache.lua - read the file written by contrib/statusline-cache.sh.

local root = (...):gsub("source%.[^%.]+$", "")
local json = require(root .. "json")

local M = {}

--- Read and decode the cache file.
---@param path string
---@return table|nil raw
function M.read(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("a")
	f:close()
	if not content or content == "" then
		return nil
	end
	local ok, data = pcall(json.decode, content)
	if not ok or type(data) ~= "table" then
		return nil
	end
	if type(data.rate_limits) ~= "table" and type(data.context) ~= "table" then
		return nil
	end
	return data
end

return M
