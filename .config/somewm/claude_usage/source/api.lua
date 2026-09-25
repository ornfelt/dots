-- source/api.lua - fetch the OAuth usage endpoint with curl (via awful.spawn, injected as deps.spawn).

local root = (...):gsub("source%.[^%.]+$", "")
local json = require(root .. "json")

local M = {}

M.BETA_HEADER = "oauth-2025-04-20"

--- Build the curl argv. Exposed for tests.
---@param opts table resolved options
---@param token string
---@return string[]
function M.argv(opts, token)
	return {
		opts.curl_cmd or "curl",
		"-sS",
		"--max-time",
		tostring(opts.timeout or 15),
		"-H",
		"Authorization: Bearer " .. token,
		"-H",
		"anthropic-beta: " .. M.BETA_HEADER,
		"-H",
		"Accept: application/json",
		"-A",
		opts.user_agent or "awesome-claude-usage",
		"-w",
		"\n%{http_code}",
		opts.api_url,
	}
end

--- Interpret a finished curl run. Exposed for tests.
---@return boolean ok
---@return table   raw decoded JSON on success, or { code, message, http } on failure
function M.interpret(stdout, stderr, reason, code, now)
	stdout = stdout or ""
	stderr = stderr or ""
	if reason ~= "exit" or code ~= 0 then
		local msg = stderr:gsub("^%s*curl:%s*%(%d+%)%s*", ""):gsub("%s+$", "")
		if msg == "" then
			msg = "curl failed (" .. tostring(reason) .. " " .. tostring(code) .. ")"
		end
		return false, { code = "network", message = msg, at = now }
	end
	local body, http = stdout:match("^(.*)\n(%d%d%d)%s*$")
	if not http then
		return false, { code = "parse", message = "no HTTP status in curl output", at = now }
	end
	http = tonumber(http)
	if http == 200 then
		local ok, data = pcall(json.decode, body)
		if not ok or type(data) ~= "table" then
			return false, { code = "parse", message = "response is not valid JSON", http = http, at = now }
		end
		return true, data
	elseif http == 401 or http == 403 then
		return false, { code = "unauthorized", message = "HTTP " .. http, http = http, at = now }
	elseif http == 429 then
		return false, { code = "rate_limited", message = "HTTP 429", http = http, at = now }
	elseif http >= 500 then
		return false, { code = "network", message = "HTTP " .. http, http = http, at = now }
	end
	return false, { code = "parse", message = "HTTP " .. http, http = http, at = now }
end

--- Fetch usage. `deps.spawn(argv, cb)` must call cb(stdout, stderr, reason, code) like awful.spawn.easy_async.
---@param opts table
---@param deps table
---@param token string
---@param cb fun(ok: boolean, result: table)
function M.fetch(opts, deps, token, cb)
	local argv = M.argv(opts, token)
	local ok_spawn, err = pcall(deps.spawn, argv, function(stdout, stderr, reason, code)
		local ok, res = M.interpret(stdout, stderr, reason, code, deps.now())
		cb(ok, res)
	end)
	if not ok_spawn then
		cb(false, { code = "network", message = "cannot run curl: " .. tostring(err), at = deps.now() })
	end
end

return M
