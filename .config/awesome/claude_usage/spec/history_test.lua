local history = require("history")

local TMP = "spec/tmp/history_test.csv"

local function fresh()
	os.remove(TMP)
	return {}
end

describe("history.append/load", function()
	it("appends and reloads samples", function()
		local samples = fresh()
		local st = {
			five_hour = { percent = 10, resets_at = 5000 },
			seven_day = { percent = 40 },
			scoped = { { name = "Fable", percent = 3 } },
		}
		assert_true(history.append(TMP, samples, st, 1000))
		assert_eq(#samples, 3)
		local loaded = history.load(TMP)
		assert_eq(#loaded, 3)
		assert_eq(loaded[1].key, "five_hour")
		assert_eq(loaded[1].resets_at, 5000)
		assert_nil(loaded[2].resets_at)
		assert_eq(loaded[3].key, "scoped:Fable")
	end)
	it("returns false without windows", function()
		assert_eq(history.append(TMP, fresh(), { scoped = {} }, 1), false)
	end)
	it("prunes when the list grows large", function()
		local samples = fresh()
		local saved = history.MAX_SAMPLES
		history.MAX_SAMPLES = 5
		for t = 1, 4 do
			history.append(TMP, samples, { five_hour = { percent = t } }, t)
		end
		history.append(TMP, samples, { five_hour = { percent = 99 } }, 1000000)
		history.append(TMP, samples, { five_hour = { percent = 100 } }, 1000001)
		history.MAX_SAMPLES = saved
		assert_eq(#samples, 2)
		assert_eq(#history.load(TMP), 2)
	end)
end)

describe("history.rate/forecast/pace", function()
	local samples = {
		{ t = 1000, key = "five_hour", percent = 10, resets_at = 20000 },
		{ t = 2800, key = "five_hour", percent = 20, resets_at = 20000 },
		{ t = 4600, key = "five_hour", percent = 30, resets_at = 20000 },
		{ t = 4700, key = "seven_day", percent = 5, resets_at = 99999 },
	}
	it("computes percent per second within the same cycle", function()
		local r = history.rate(samples, "five_hour", 4600, 7200, 20000)
		assert_eq(r, 20 / 3600)
	end)
	it("ignores samples from another cycle and short spans", function()
		assert_nil(history.rate(samples, "five_hour", 4600, 7200, 30000))
		assert_nil(history.rate(samples, "seven_day", 4700, 86400, 99999))
	end)
	it("needs a longer span for the weekly window", function()
		local weekly = {
			{ t = 1000, key = "seven_day", percent = 6, resets_at = 99999 },
			{ t = 1000 + 1800, key = "seven_day", percent = 7, resets_at = 99999 },
			{ t = 1000 + 4 * 3600, key = "seven_day", percent = 9, resets_at = 99999 },
		}
		assert_nil(history.rate(weekly, "seven_day", 1000 + 1800, 86400, 99999))
		assert_true(history.rate(weekly, "seven_day", 1000 + 4 * 3600, 86400, 99999) > 0)
	end)
	it("forecasts exhaustion before the reset", function()
		local fc = history.forecast({ percent = 30, resets_at = 20000 }, 20 / 3600, 4600)
		assert_eq(fc.exhaust_at, 4600 + 12600)
		assert_true(fc.at_reset > 100)
	end)
	it("drops exhaustion when the window resets first", function()
		local fc = history.forecast({ percent = 30, resets_at = 6000 }, 20 / 3600, 4600)
		assert_nil(fc.exhaust_at)
		assert_true(math.abs(fc.at_reset - 37.78) < 0.1)
	end)
	it("treats a full window as exhausted now", function()
		assert_eq(history.forecast({ percent = 100, resets_at = 20000 }, 20 / 3600, 4600).exhaust_at, 4600)
		assert_eq(history.forecast({ percent = 100.4, resets_at = 20000 }, 0, 4600).exhaust_at, 4600)
		assert_eq(history.forecast({ percent = 100 }, nil, 4600).exhaust_at, 4600)
	end)
	it("returns nil without a rate", function()
		assert_nil(history.forecast({ percent = 1 }, nil, 1))
	end)
	it("computes pacing", function()
		assert_eq(history.pace({ resets_at = 1000 + 3600 * 4 }, 5 * 3600, 1000), 20)
		assert_nil(history.pace({ resets_at = 1000 + 6 * 3600 }, 5 * 3600, 1000))
		assert_nil(history.pace({}, 5, 1))
	end)
	it("filters series", function()
		local s = history.series(samples, "five_hour", 2000)
		assert_eq(#s, 2)
		assert_eq(s[1].percent, 20)
	end)
end)
