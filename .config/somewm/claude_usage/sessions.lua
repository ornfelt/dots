-- sessions.lua - running Claude Code sessions from ~/.claude/sessions/*.json (pure Lua + io).

local prefix = (...):match("^(.*%.)") or ""
local json = require(prefix .. "json")

local M = {}

M.STATUS = {
	busy = "working",
	idle = "idle",
	waiting = "attention",
	needs_input = "attention",
}

local function default_list(dir)
	local names = {}
	local p = io.popen('ls -1 -- "' .. dir:gsub('"', '\\"') .. '" 2>/dev/null')
	if not p then
		return names
	end
	for line in p:lines() do
		if line:match("^%d+%.json$") then
			names[#names + 1] = line
		end
	end
	p:close()
	return names
end

local function default_alive(pid)
	local f = io.open("/proc/" .. tostring(pid) .. "/stat", "r")
	if f then
		f:close()
		return true
	end
	return false
end

--- Read the session directory.
---@param dir string
---@param now integer
---@param deps table|nil { list = fun(dir) -> filenames, alive = fun(pid) -> boolean }
---@return table summary { total, working, idle, attention, list = { {pid, name, status, kind, cwd, since} } }
function M.read(dir, now, deps)
	deps = deps or {}
	local list = deps.list or default_list
	local alive = deps.alive or default_alive
	local out = { total = 0, working = 0, idle = 0, attention = 0, list = {} }
	for _, name in ipairs(list(dir)) do
		local f = io.open(dir .. "/" .. name, "r")
		if f then
			local content = f:read("a")
			f:close()
			local ok, data = pcall(json.decode, content or "")
			if ok and type(data) == "table" and data.pid and alive(data.pid) then
				local status = M.STATUS[tostring(data.status)] or "idle"
				local updated = tonumber(data.statusUpdatedAt or data.updatedAt)
				if updated and updated > 1e11 then
					updated = math.floor(updated / 1000)
				end
				out.total = out.total + 1
				out[status] = out[status] + 1
				out.list[#out.list + 1] = {
					pid = data.pid,
					session_id = data.sessionId,
					name = data.name,
					status = status,
					raw_status = data.status,
					kind = data.kind,
					cwd = data.cwd,
					since = updated and math.max(0, now - updated) or nil,
				}
			end
		end
	end
	table.sort(out.list, function(a, b)
		return (a.pid or 0) < (b.pid or 0)
	end)
	return out
end

--- Compare two summaries and list notable transitions.
---@return table events { { kind = "attention"|"finished", session = <entry> } }
function M.diff(old, new)
	local events = {}
	if not old then
		return events
	end
	local before = {}
	for _, s in ipairs(old.list or {}) do
		before[s.pid] = s
	end
	for _, s in ipairs(new.list or {}) do
		local prev = before[s.pid]
		if prev and prev.status ~= s.status then
			if s.status == "attention" then
				events[#events + 1] = { kind = "attention", session = s }
			elseif prev.status == "working" and s.status == "idle" then
				events[#events + 1] = { kind = "finished", session = s }
			end
		end
	end
	return events
end

return M
