local sessions = require("sessions")

local DIR = "spec/fixtures/sessions"
local deps = {
	list = function()
		return { "100.json", "200.json", "300.json", "400.json", "notes.txt" }
	end,
	alive = function(pid)
		return pid ~= 400
	end,
}

describe("sessions.read", function()
	it("summarises live sessions", function()
		local s = sessions.read(DIR, 1758560000, deps)
		assert_eq(s.total, 3)
		assert_eq(s.working, 1)
		assert_eq(s.idle, 1)
		assert_eq(s.attention, 1)
		assert_eq(s.list[1].name, "repo-a")
		assert_eq(s.list[1].since, 60)
		assert_eq(s.list[3].status, "attention")
	end)
	it("handles a missing directory", function()
		local s = sessions.read("spec/fixtures/nope", 1)
		assert_eq(s.total, 0)
	end)
end)

describe("sessions.diff", function()
	it("reports attention and finished transitions", function()
		local old = {
			list = { { pid = 1, status = "working" }, { pid = 2, status = "working" }, { pid = 3, status = "idle" } },
		}
		local new = {
			list = { { pid = 1, status = "idle" }, { pid = 2, status = "attention" }, { pid = 3, status = "working" } },
		}
		local ev = sessions.diff(old, new)
		assert_eq(#ev, 2)
		assert_eq(ev[1].kind, "finished")
		assert_eq(ev[2].kind, "attention")
		assert_eq(#sessions.diff(nil, new), 0)
	end)
end)
