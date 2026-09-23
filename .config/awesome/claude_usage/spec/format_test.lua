local format = require("format")
local config = require("config")

local function state(five, seven, extra)
	local st = { scoped = {}, fetched_at = 1000, source = "api" }
	if five then
		st.five_hour = { percent = five, resets_at = 1000 + 3600 }
	end
	if seven then
		st.seven_day = { percent = seven, resets_at = 1000 + 2 * 86400 }
	end
	for k, v in pairs(extra or {}) do
		st[k] = v
	end
	return st
end

describe("format.bar_text", function()
	local opts = config.resolve({ glyph = "G", error_glyph = "E" })
	it("renders both windows with rounding", function()
		assert_eq(format.bar_text(state(66.6, 3.2), opts), "G 5h 67% · 7d 3%")
	end)
	it("renders placeholders for missing windows", function()
		assert_eq(format.bar_text(state(nil, 50), opts), "G 5h -- · 7d 50%")
	end)
	it("renders loading and error states", function()
		assert_eq(format.bar_text(nil, opts), "G …")
		assert_eq(format.bar_text({ scoped = {}, error = { code = "unauthorized" } }, opts), "E !auth")
		assert_eq(format.bar_text({ scoped = {}, error = { code = "rate_limited" } }, opts), "E !429")
		assert_eq(format.bar_text({ scoped = {} }, opts), "G --")
	end)
	it("omits the glyph on request", function()
		local o = config.resolve({ show_glyph = false })
		assert_eq(format.bar_text(state(1, 2), o), "5h 1% · 7d 2%")
	end)
	it("uses a custom format function and survives its errors", function()
		local o = config.resolve({
			format = function(st, f)
				return "W" .. f.round(st.seven_day.percent)
			end,
		})
		assert_eq(format.bar_text(state(1, 2.6), o), "W3")
		local bad = config.resolve({
			format = function()
				error("boom")
			end,
			glyph = "G",
		})
		assert_eq(format.bar_text(state(1, 2), bad), "G 5h 1% · 7d 2%")
	end)
end)

describe("format.color_for", function()
	local opts = config.resolve({ colors = { normal = "N", warn = "W", crit = "C", error = "E", stale = "S" } })
	it("picks the level from the highest window", function()
		assert_eq(format.color_for(state(74.9, 10), opts), "N")
		assert_eq(format.color_for(state(75, 10), opts), "W")
		assert_eq(format.color_for(state(10, 89.9), opts), "W")
		assert_eq(format.color_for(state(10, 90), opts), "C")
	end)
	it("considers scoped windows", function()
		local st = state(1, 2, { scoped = { { name = "Fable", percent = 95 } } })
		assert_eq(format.color_for(st, opts), "C")
	end)
	it("applies error and stale precedence", function()
		assert_eq(format.color_for({ scoped = {}, error = { code = "network" } }, opts), "E")
		assert_eq(format.color_for(state(1, 2, { stale = true }), opts), "S")
		assert_eq(format.color_for(state(80, 2, { stale = true }), opts), "W")
	end)
	it("returns nil when inheriting", function()
		assert_nil(format.color_for(state(1, 2), config.resolve({})))
	end)
end)

describe("format.popup_lines", function()
	local opts = config.resolve({})
	it("lists windows, scoped limits, spend, source and next check", function()
		local st = state(3, 67, {
			scoped = { { name = "Fable", percent = 51, resets_at = 1000 + 2 * 86400, is_active = true } },
			spend = { enabled = true, percent = 12.34, used = 12.34, limit = 100, currency = "USD" },
			breakdown = {
				{ name = "Claude Code", percent = 89 },
				{ name = "Chats", percent = 11 },
				{ name = "Cowork", percent = 0 },
			},
			subscription = "max",
			next_fetch_at = 1000 + 240,
		})
		local lines = format.popup_lines(st, 1000 + 180, opts)
		assert_eq(lines[1], "Claude usage (max)")
		assert_eq(lines[2], "Session (5h): 3% – resets in 57m")
		assert_eq(lines[3], "Weekly (7d): 67% – resets in 1d 23h")
		assert_eq(lines[4], "  Fable: 51% – resets in 1d 23h *")
		assert_eq(lines[5], "Weekly by surface: Claude Code 89%, Chats 11%")
		assert_eq(lines[6], "Extra usage: $12.34 / $100.00 (12%)")
		assert_eq(lines[7], "")
		assert_eq(lines[8], "via API, 3 min ago")
		assert_eq(lines[9], "Next check in 1m")
	end)
	it("explains errors alongside cached data", function()
		local st = state(3, 67, { source = "statusline", stale = true, error = { code = "rate_limited", retry_at = 1600 } })
		local lines = format.popup_lines(st, 1000, opts)
		assert_eq(lines[5], "via statusLine, just now (stale)")
		assert_eq(lines[6], "Last check failed: Rate limited (429), retry in 10m")
	end)
	it("handles no data", function()
		local lines = format.popup_lines({ scoped = {}, error = { code = "unauthorized" } }, 1000, opts)
		assert_eq(lines[2], "No usage data")
		assert_eq(lines[4], "Token expired or rejected – run any `claude` command to refresh")
		assert_eq(format.popup_lines(nil, 1, opts)[2], "Loading…")
	end)
	it("labels windows that have not started", function()
		local st = state(nil, 2, { five_hour = { percent = 0, assumed = true } })
		local lines = format.popup_lines(st, 1000, opts)
		assert_eq(lines[2], "Session (5h): 0% – no usage yet")
		local rows = format.popup_rows(st, 1000, opts)
		assert_eq(rows.windows[1].reset, "no usage yet")
	end)
	it("uses absolute times for implausible resets", function()
		local st = state(1, 2, { five_hour = { percent = 1, resets_at = 1000 + 30 * 86400 } })
		local lines = format.popup_lines(st, 1000, opts)
		assert_true(lines[2]:find("resets at %d%d%d%d%-") ~= nil, lines[2])
	end)
end)

describe("format.forecast_text", function()
	it("says the limit is reached instead of forecasting an expired exhaustion", function()
		local text, level = format.forecast_text({ rate = 0.001, exhaust_at = 1000 }, 1000)
		assert_eq(text, "limit reached")
		assert_eq(level, "crit")
		assert_eq(format.forecast_text({ exhaust_at = 900 }, 1000), "limit reached")
	end)
	it("forecasts a future exhaustion", function()
		local text, level = format.forecast_text({ rate = 0.001, exhaust_at = 1000 + 1800 }, 1000)
		assert_eq(text, "at this pace empty in 30m")
		assert_eq(level, "crit")
	end)
end)
