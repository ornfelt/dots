-- bar.lua - cairo-drawn progress bar with a pace marker, and a sparkline (awesome only).

local wibox = require("wibox")
local gears = require("gears")
local cairo = require("lgi").cairo

local M = {}

local function rounded(cr, x, y, w, h, r)
	r = math.min(r, h / 2, w / 2)
	if w <= 0 then
		return
	end
	cr:new_sub_path()
	cr:arc(x + w - r, y + r, r, -math.pi / 2, 0)
	cr:arc(x + w - r, y + h - r, r, 0, math.pi / 2)
	cr:arc(x + r, y + h - r, r, math.pi / 2, math.pi)
	cr:arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
	cr:close_path()
end

--- Progress bar. args: value (0-100), color, track, marker (0-100 or nil), marker_color, height.
function M.bar(args)
	local w = wibox.widget.base.make_widget(nil, "claude_usage.bar")
	w._args = args

	function w:fit(_, width)
		return width, self._args.height or 6
	end

	function w:draw(_, cr, width, height)
		local a = self._args
		local r = height / 2
		cr:set_source(gears.color(a.track or "#3A3835"))
		rounded(cr, 0, 0, width, height, r)
		cr:fill()
		local value = math.max(0, math.min(a.value or 0, 100))
		local fill = width * value / 100
		if fill > 0 then
			cr:set_source(gears.color(a.color or "#D97757"))
			rounded(cr, 0, 0, math.max(fill, height), height, r)
			cr:fill()
		end
		if a.marker then
			local x = math.floor(width * math.max(0, math.min(a.marker, 100)) / 100 + 0.5)
			cr:set_source(gears.color(a.marker_color or "#FAF9F5"))
			cr:rectangle(x - 1, -2, 2, height + 4)
			cr:fill()
		end
	end

	function w:set_value(v)
		self._args.value = v
		self:emit_signal("widget::redraw_needed")
	end

	return w
end

--- Sparkline. args: points ({ {t=, percent=} }, sorted), from, to, color, track, height, marker_t (nil).
function M.sparkline(args)
	local w = wibox.widget.base.make_widget(nil, "claude_usage.sparkline")
	w._args = args

	function w:fit(_, width)
		return width, self._args.height or 18
	end

	function w:draw(_, cr, width, height)
		local a = self._args
		local pts = a.points or {}
		local from, to = a.from, a.to
		if to <= from then
			return
		end
		-- baseline
		cr:set_source(gears.color(a.track or "#3A3835"))
		cr:set_line_width(1)
		cr:move_to(0, height - 0.5)
		cr:line_to(width, height - 0.5)
		cr:stroke()
		if #pts < 2 then
			return
		end
		local function xy(p)
			local x = (p.t - from) / (to - from) * width
			local y = height - 1 - math.max(0, math.min(p.percent, 100)) / 100 * (height - 2)
			return x, y
		end
		-- area
		cr:set_source(gears.color((a.color or "#D97757") .. "33"))
		local x0, y0 = xy(pts[1])
		cr:move_to(x0, height)
		cr:line_to(x0, y0)
		for i = 2, #pts do
			local x, y = xy(pts[i])
			if pts[i].percent < pts[i - 1].percent - 20 then
				-- a reset: drop to the baseline and start again
				local xp = xy(pts[i - 1])
				cr:line_to(xp, height)
				cr:line_to(x, height)
			end
			cr:line_to(x, y)
		end
		local xl = xy(pts[#pts])
		cr:line_to(xl, height)
		cr:close_path()
		cr:fill()
		-- line
		cr:set_source(gears.color(a.color or "#D97757"))
		cr:set_line_width(1.5)
		cr:set_line_join(cairo.LineJoin.ROUND)
		cr:move_to(x0, y0)
		for i = 2, #pts do
			local x, y = xy(pts[i])
			if pts[i].percent < pts[i - 1].percent - 20 then
				cr:stroke()
				cr:move_to(x, y)
			else
				cr:line_to(x, y)
			end
		end
		cr:stroke()
	end

	return w
end

return M
