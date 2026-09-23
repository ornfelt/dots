local brand = require("brand")
local format = require("format")
local config = require("config")

describe("brand.font", function()
	it("splits family and size", function()
		local fam, size = brand.font_parts("Hack Nerd Font 10")
		assert_eq(fam, "Hack Nerd Font")
		assert_eq(size, 10)
		fam, size = brand.font_parts("sans 9.5")
		assert_eq(fam, "sans")
		assert_eq(size, 9.5)
		fam, size = brand.font_parts(nil)
		assert_eq(fam, "sans")
		assert_eq(size, 10)
	end)
	it("builds derived fonts", function()
		assert_eq(brand.font("Hack Nerd Font 10", 12, "Bold"), "Hack Nerd Font Bold 12")
		assert_eq(brand.font("Hack Nerd Font 10", 9), "Hack Nerd Font 9")
	end)
end)

describe("format.chip_color", function()
	local opts = config.resolve({})
	local function st(pct)
		return { scoped = {}, seven_day = { percent = pct } }
	end
	it("follows the level", function()
		assert_eq(format.chip_color(st(10), opts), "#D97757")
		assert_eq(format.chip_color(st(75), opts), "#E39B3A")
		assert_eq(format.chip_color(st(90), opts), "#C8442E")
	end)
	it("greys out on error without data", function()
		assert_eq(format.chip_color({ scoped = {}, error = { code = "network" } }, opts), "#4A4744")
		assert_eq(format.chip_color(nil, opts), "#D97757")
	end)
end)

describe("format.popup_rows", function()
	local opts = config.resolve({})
	it("builds windows, spend, breakdown and footer", function()
		local st = {
			five_hour = { percent = 16, resets_at = 1000 + 4 * 3600 + 23 * 60, is_active = true },
			seven_day = { percent = 4, resets_at = 1000 + 19 * 3600 },
			scoped = { { name = "Fable", percent = 91, resets_at = 1000 + 19 * 3600 } },
			spend = { enabled = true, percent = 12, used = 12.34, limit = 100, currency = "USD" },
			breakdown = { { name = "Claude Code", percent = 100 }, { name = "Chats", percent = 0 } },
			fetched_at = 1000,
			source = "api",
			subscription = "max",
			next_fetch_at = 1000 + 240,
		}
		local rows = format.popup_rows(st, 1000 + 60, opts)
		assert_eq(rows.title, "Claude usage")
		assert_eq(rows.subtitle, "Max plan · via API 1 min ago")
		assert_eq(#rows.windows, 3)
		assert_eq(rows.windows[1].label, "Session")
		assert_eq(rows.windows[1].reset, "resets in 4h 22m")
		assert_eq(rows.windows[1].active, true)
		assert_eq(rows.windows[3].level, "crit")
		assert_eq(rows.spend.text, "$12.34 of $100.00")
		assert_eq(rows.breakdown, "Claude Code 100%")
		assert_eq(rows.footer[1], "next check in 3m")
		assert_nil(rows.error)
	end)
	it("handles loading, empty and error states", function()
		assert_eq(format.popup_rows(nil, 1, opts).subtitle, "Loading…")
		local rows = format.popup_rows({ scoped = {}, error = { code = "unauthorized" } }, 1, opts)
		assert_eq(rows.empty, "No usage data")
		assert_true(rows.error:find("Token expired") ~= nil)
		assert_eq(#rows.windows, 0)
	end)
	it("marks stale cached data", function()
		local st = { scoped = {}, five_hour = { percent = 1 }, fetched_at = 0, source = "claude_json", stale = true }
		local rows = format.popup_rows(st, 7200, opts)
		assert_eq(rows.subtitle, "via claude.json cache 2 h ago · stale")
		assert_eq(rows.windows[2].percent, nil)
	end)
end)
