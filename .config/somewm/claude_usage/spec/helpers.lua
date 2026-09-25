local H = {}

function H.read(path)
	local f = assert(io.open(path, "r"))
	local s = f:read("a")
	f:close()
	return s
end

function H.json(path)
	return require("json").decode(H.read(path))
end

--- Fake awesome dependencies for model tests.
function H.deps(t0)
	local d = { t = t0 or 1758560000, spawned = {}, notifications = {}, timers = {}, warnings = {} }
	d.now = function()
		return d.t
	end
	d.spawn = function(argv, cb)
		d.spawned[#d.spawned + 1] = { argv = argv, cb = cb }
	end
	d.timer = function(args)
		local tm = {
			timeout = args.timeout,
			single_shot = args.single_shot,
			callback = args.callback,
			started = args.autostart or false,
			again_calls = 0,
		}
		function tm:start()
			self.started = true
		end
		function tm:stop()
			self.started = false
		end
		function tm:again()
			self.started = true
			self.again_calls = self.again_calls + 1
		end
		function tm:fire()
			if self.single_shot then
				self.started = false
			end
			self.callback()
		end
		d.timers[#d.timers + 1] = tm
		return tm
	end
	d.notify = function(args)
		d.notifications[#d.notifications + 1] = args
	end
	d.warn = function(msg)
		d.warnings[#d.warnings + 1] = msg
	end
	return d
end

--- Simulate a finished curl run for the last spawned command.
function H.respond(d, body, http)
	local s = d.spawned[#d.spawned]
	assert(s, "nothing was spawned")
	s.cb(body .. "\n" .. tostring(http), "", "exit", 0)
end

return H
