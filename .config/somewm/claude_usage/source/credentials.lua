-- source/credentials.lua - read the Claude Code OAuth access token (read-only, never written).

local root = (...):gsub("source%.[^%.]+$", "")
local json = require(root .. "json")

local M = {}

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("a")
	f:close()
	return content
end

--- Read ~/.claude/.credentials.json.
---@param path string
---@param now integer
---@return table|nil creds  { token, expires_at, subscription, tier }
---@return table|nil err    { code, message, at }
function M.read(path, now)
	local content = read_file(path)
	if not content or content == "" then
		return nil, { code = "no_credentials", message = "cannot read " .. path, at = now }
	end
	local ok, data = pcall(json.decode, content)
	if not ok or type(data) ~= "table" then
		return nil, { code = "no_credentials", message = "credentials file is not valid JSON", at = now }
	end
	local oauth = data.claudeAiOauth
	if type(oauth) ~= "table" or type(oauth.accessToken) ~= "string" or oauth.accessToken == "" then
		return nil, { code = "no_credentials", message = "no claudeAiOauth.accessToken in credentials", at = now }
	end
	local expires_at = tonumber(oauth.expiresAt)
	if expires_at and expires_at > 1e11 then
		expires_at = expires_at / 1000
	end
	if expires_at and expires_at <= now then
		return nil, { code = "unauthorized", message = "access token expired", at = now }
	end
	return {
		token = oauth.accessToken,
		expires_at = expires_at,
		subscription = oauth.subscriptionType,
		tier = oauth.rateLimitTier,
	}
end

return M
