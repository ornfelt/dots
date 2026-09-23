local H = require("spec.helpers")
local model = require("model")
local config = require("config")

local function merge(a, b)
	for k, v in pairs(b or {}) do
		a[k] = v
	end
	return a
end

local function setup(overrides)
	model.stop()
	local deps = H.deps()
	local opts = config.resolve(merge({
		credentials_path = "spec/fixtures/credentials_ok.json",
		cache_path = "spec/fixtures/statusline.json",
		claude_json_path = "spec/fixtures/claude_json.json",
		jitter = 0,
		backoff = { 100, 200 },
		initial_delay = 5,
		history = false,
		sessions = false,
		fresh_cache_max_age = 0,
	}, overrides))
	model.setup(opts, deps)
	return deps, opts
end

local API_BODY = H.read("spec/fixtures/api_limits.json")

describe("model", function()
	it("primes the state from the statusline cache before the first fetch", function()
		local deps = setup()
		assert_eq(model.state.source, "statusline")
		assert_eq(model.state.five_hour.percent, 23.5)
		assert_eq(model.state.stale, false)
		assert_eq(#deps.spawned, 0)
		assert_eq(deps.timers[1].timeout, 5)
	end)

	it("replaces cached data with the API response and schedules the interval", function()
		local deps, opts = setup()
		deps.timers[1]:fire()
		assert_eq(#deps.spawned, 1)
		assert_eq(deps.spawned[1].argv[6], "Authorization: Bearer REDACTED-TOKEN")
		H.respond(deps, API_BODY, 200)
		assert_eq(model.state.source, "api")
		assert_eq(model.state.seven_day.percent, 67)
		assert_eq(model.state.subscription, "max")
		assert_nil(model.state.error)
		assert_eq(deps.timers[1].timeout, opts.interval)
		assert_eq(model.state.next_fetch_at, deps.t + opts.interval)
	end)

	it("falls back to the statusline cache on 429 and backs off", function()
		local deps = setup()
		deps.timers[1]:fire()
		H.respond(deps, "", 429)
		assert_eq(model.state.source, "statusline")
		assert_eq(model.state.error.code, "rate_limited")
		assert_eq(deps.timers[1].timeout, 100)
		deps.t = deps.t + 100
		deps.timers[1]:fire()
		H.respond(deps, "", 429)
		assert_eq(deps.timers[1].timeout, 200)
		deps.t = deps.t + 200
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(model.state.source, "api")
		assert_eq(deps.timers[1].timeout, 300)
	end)

	it("keeps the normal interval on 401 and does not back off", function()
		local deps = setup()
		deps.timers[1]:fire()
		H.respond(deps, "", 401)
		assert_eq(model.state.error.code, "unauthorized")
		assert_eq(model.state.source, "statusline")
		assert_eq(deps.timers[1].timeout, 300)
	end)

	it("skips curl entirely when the token is expired", function()
		local deps = setup({ credentials_path = "spec/fixtures/credentials_expired.json" })
		deps.timers[1]:fire()
		assert_eq(#deps.spawned, 0)
		assert_eq(model.state.error.code, "unauthorized")
		assert_eq(model.state.five_hour.percent, 23.5)
	end)

	it("uses ~/.claude.json when the statusline cache is missing and flags it stale", function()
		local deps = setup({ cache_path = "spec/fixtures/nope.json", sources = { "claude_json" } })
		assert_eq(model.state.source, "claude_json")
		assert_eq(model.state.fetched_at, 1758490000)
		assert_eq(model.state.stale, true)
		deps.timers[1]:fire()
		assert_eq(#deps.spawned, 0)
		assert_eq(model.state.source, "claude_json")
	end)

	it("reports no_source but keeps the last good data", function()
		local deps = setup({ cache_path = "spec/fixtures/nope.json", claude_json_path = "spec/fixtures/nope.json" })
		assert_nil(model.state)
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(model.state.source, "api")
		deps.timers[1]:fire()
		H.respond(deps, "", 503)
		assert_eq(model.state.error.code, "network")
		assert_eq(model.state.seven_day.percent, 67)
		assert_eq(model.state.source, "api")
	end)

	it("honours the backoff on forced refresh", function()
		local deps = setup()
		deps.timers[1]:fire()
		H.respond(deps, "", 429)
		assert_eq(model.refresh({ force = true }), false)
		assert_eq(#deps.spawned, 1)
		assert_eq(model.state.error.code, "rate_limited")
		deps.t = deps.t + 101
		assert_eq(model.refresh({ force = true }), true)
		assert_eq(#deps.spawned, 2)
	end)

	it("ignores overlapping refreshes while a fetch is in flight", function()
		local deps = setup()
		deps.timers[1]:fire()
		assert_eq(model.refresh({ force = true }), false)
		assert_eq(#deps.spawned, 1)
	end)

	it("survives throwing subscribers", function()
		local deps = setup()
		local calls = 0
		model.subscribe(function()
			calls = calls + 1
			error("boom")
		end)
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(calls, 2)
		assert_true(#deps.warnings >= 1)
		assert_eq(model.state.source, "api")
	end)

	it("notifies once when a window crosses a threshold", function()
		local deps = setup({ thresholds = { warn = 60, crit = 95 } })
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(#deps.notifications, 1)
		assert_true(deps.notifications[1].message:find("Weekly %(7d%) at 67%%") ~= nil)
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(#deps.notifications, 1)
	end)

	it("supports unsubscribe and stop", function()
		local deps = setup()
		local calls = 0
		local unsub = model.subscribe(function()
			calls = calls + 1
		end)
		assert_eq(calls, 1)
		unsub()
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(calls, 1)
		model.stop()
		assert_nil(model.state)
	end)
end)

describe("model (cache preference, sessions, history)", function()
	it("uses a fresh statusline cache between API polls and keeps the API-only details", function()
		-- cache with the same weekly reset as the API fixture (2026-09-23T15:00Z = 1790175600)
		local cache = io.open("spec/tmp/same_cycle.json", "w")
		cache:write('{"ts":1758560000,"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":1758570000},'
			.. '"seven_day":{"used_percentage":41.2,"resets_at":1790175600}}}')
		cache:close()
		local deps = setup({ fresh_cache_max_age = 120, interval_idle = 900, cache_path = "spec/tmp/same_cycle.json" })
		deps.t = 1758560000 - 100
		-- first poll always asks the API
		deps.timers[1]:fire()
		assert_eq(#deps.spawned, 1)
		H.respond(deps, API_BODY, 200)
		assert_eq(model.state.source, "api")
		assert_eq(#model.state.scoped, 2)
		-- cache ts is 1758560000: fresh, API answer recent -> no network
		deps.t = 1758560000 + 60
		deps.timers[1]:fire()
		assert_eq(#deps.spawned, 1)
		assert_eq(model.state.source, "statusline")
		assert_eq(model.state.five_hour.percent, 23.5)
		assert_eq(#model.state.scoped, 2, "scoped limits carried over from the API")
		assert_eq(model.state.scoped[1].name, "Fable")
		assert_eq(model.state.scoped_from, 1758560000 - 100)
		assert_true(model.state.breakdown ~= nil)
		-- after interval_idle the API is asked again even though the cache is fresh
		deps.t = 1758560000 - 100 + 901
		local later = io.open("spec/tmp/fresh_cache.json", "w")
		later:write('{"ts":' .. deps.t .. ',"rate_limits":{"five_hour":{"used_percentage":1},'
			.. '"seven_day":{"used_percentage":2}}}')
		later:close()
		model.stop()
		local deps2 = setup({ fresh_cache_max_age = 120, interval_idle = 900, cache_path = "spec/tmp/fresh_cache.json" })
		deps2.t = deps.t
		deps2.timers[1]:fire()
		assert_eq(#deps2.spawned, 1, "no recent API answer -> API is called")
	end)

	it("polls slowly while no session works and fast while one does", function()
		local sdeps = {
			list = function()
				return { "1.json" }
			end,
			alive = function()
				return true
			end,
		}
		local dir = "spec/tmp/sessions"
		os.execute("mkdir -p " .. dir)
		local function write(status)
			local f = assert(io.open(dir .. "/1.json", "w"))
			f:write('{"pid":1,"status":"' .. status .. '","name":"s","statusUpdatedAt":1}')
			f:close()
		end
		write("idle")
		local deps = H.deps()
		deps.sessions = sdeps
		model.stop()
		local opts = config.resolve({
			credentials_path = "spec/fixtures/credentials_ok.json",
			cache_path = "spec/fixtures/nope.json",
			claude_json_path = "spec/fixtures/nope.json",
			jitter = 0,
			history = false,
			sessions = true,
			sessions_dir = dir,
			interval = 200,
			interval_idle = 900,
		})
		model.setup(opts, deps)
		assert_eq(model.state, nil)
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(deps.timers[1].timeout, 900, "idle interval")
		assert_eq(model.state.sessions.total, 1)
		-- a session starts working: refresh soon, then fast interval
		write("busy")
		deps.timers[3]:fire()
		assert_eq(deps.timers[1].timeout, 60)
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(deps.timers[1].timeout, 200, "active interval")
		-- needs attention: notification and flag
		write("waiting")
		deps.timers[3]:fire()
		assert_eq(#deps.notifications, 1)
		assert_true(deps.notifications[1].message:find("needs your attention") ~= nil)
		assert_eq(model.state.sessions.attention, 1)
		os.remove(dir .. "/1.json")
	end)

	it("records history and attaches a forecast", function()
		local path = "spec/tmp/model_history.csv"
		os.remove(path)
		local deps = setup({ history = true, history_path = path, cache_path = "spec/fixtures/nope.json" })
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(#model.samples(), 4)
		assert_true(model.state.forecast ~= nil)
		assert_nil(model.state.forecast.five_hour, "no rate from a single sample")
		deps.t = deps.t + 900
		deps.timers[1]:fire()
		local body = API_BODY:gsub('"percent": 3,', '"percent": 8,', 1)
		H.respond(deps, body, 200)
		assert_eq(#model.samples(), 8)
		local fc = model.state.forecast.five_hour
		assert_true(fc ~= nil and fc.rate > 0)
		assert_true(model.state.pace.seven_day == nil or model.state.pace.seven_day >= 0)
		os.remove(path)
	end)
end)

describe("model (hook, cache watch)", function()
	it("reacts to a cache rewrite by reading the fresh cache", function()
		local watched = nil
		local deps = H.deps()
		deps.watch = function(path, cb)
			watched = { path = path, cb = cb }
		end
		model.stop()
		local opts = config.resolve({
			credentials_path = "spec/fixtures/credentials_ok.json",
			cache_path = "spec/fixtures/statusline.json",
			claude_json_path = "spec/fixtures/nope.json",
			jitter = 0,
			history = false,
			sessions = false,
			fresh_cache_max_age = 120,
			watch_cache = true,
		})
		model.setup(opts, deps)
		assert_true(watched ~= nil and watched.path == "spec/fixtures/statusline.json")
		deps.t = 1758560000 - 60
		deps.timers[1]:fire()
		H.respond(deps, API_BODY, 200)
		assert_eq(model.state.source, "api")
		deps.t = 1758560000 + 30
		watched.cb()
		assert_eq(#deps.spawned, 1, "fresh cache, recent API answer: no network")
		assert_eq(model.state.source, "statusline")
		assert_eq(model.state.next_fetch_at, deps.t + 300)
		-- debounced
		local before = deps.timers[1].again_calls
		watched.cb()
		assert_eq(deps.timers[1].again_calls, before)
	end)

	it("notifies once from a hook and rescans sessions", function()
		local dir = "spec/tmp/sessions_hook"
		os.execute("mkdir -p " .. dir)
		local f = assert(io.open(dir .. "/7.json", "w"))
		f:write('{"pid":7,"sessionId":"sess-7","status":"busy","name":"hooked","statusUpdatedAt":1}')
		f:close()
		local deps = H.deps()
		deps.sessions = {
			list = function()
				return { "7.json" }
			end,
			alive = function()
				return true
			end,
		}
		model.stop()
		model.setup(config.resolve({
			credentials_path = "spec/fixtures/credentials_ok.json",
			cache_path = "spec/fixtures/nope.json",
			claude_json_path = "spec/fixtures/nope.json",
			jitter = 0,
			history = false,
			sessions = true,
			sessions_dir = dir,
		}), deps)
		model.hook("Notification", "permission_prompt", "sess-7")
		assert_eq(#deps.notifications, 1)
		assert_eq(deps.notifications[1].message, "hooked needs your attention")
		model.hook("Notification", "permission_prompt", "sess-7")
		assert_eq(#deps.notifications, 1, "deduplicated")
		model.hook("Notification", "auth_success", "sess-7")
		model.hook("Stop", "", "sess-7")
		assert_eq(#deps.notifications, 1)
		os.remove(dir .. "/7.json")
	end)
end)
