-- Minimal dependency-free test runner. Usage (from the repo root): lua5.4 spec/run.lua [filter]
package.path = "./?.lua;./?/init.lua;" .. package.path

local filter = arg and arg[1]
os.execute("mkdir -p spec/tmp")
local passed, failed = 0, 0
local current = ""

local function fmt(v)
	if type(v) == "table" then
		local parts = {}
		for k, val in pairs(v) do
			parts[#parts + 1] = tostring(k) .. "=" .. tostring(val)
		end
		table.sort(parts)
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end

function describe(name, fn)
	local prev = current
	current = (prev ~= "" and (prev .. " › ") or "") .. name
	fn()
	current = prev
end

function it(name, fn)
	local full = current .. " › " .. name
	if filter and not full:find(filter, 1, true) then
		return
	end
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		io.stderr:write("FAIL " .. full .. "\n  " .. tostring(err) .. "\n")
	end
end

function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error((msg and (msg .. ": ") or "") .. "expected " .. fmt(expected) .. ", got " .. fmt(actual), 2)
	end
end

function assert_true(v, msg)
	if not v then
		error((msg and (msg .. ": ") or "") .. "expected truthy, got " .. fmt(v), 2)
	end
end

function assert_nil(v, msg)
	if v ~= nil then
		error((msg and (msg .. ": ") or "") .. "expected nil, got " .. fmt(v), 2)
	end
end

function assert_error(fn, msg)
	local ok = pcall(fn)
	if ok then
		error((msg and (msg .. ": ") or "") .. "expected an error", 2)
	end
end

local files = {
	"spec/timeparse_test.lua",
	"spec/backoff_test.lua",
	"spec/history_test.lua",
	"spec/sessions_test.lua",
	"spec/config_test.lua",
	"spec/normalize_test.lua",
	"spec/format_test.lua",
	"spec/brand_test.lua",
	"spec/features_test.lua",
	"spec/api_test.lua",
	"spec/notify_test.lua",
	"spec/model_test.lua",
}
for _, f in ipairs(files) do
	local chunk, err = loadfile(f)
	if not chunk then
		io.stderr:write("cannot load " .. f .. ": " .. tostring(err) .. "\n")
		failed = failed + 1
	else
		chunk()
	end
end

io.write(string.format("%d passed, %d failed (TZ=%s, %s)\n", passed, failed, os.getenv("TZ") or "unset", _VERSION))
os.exit(failed == 0 and 0 or 1)
