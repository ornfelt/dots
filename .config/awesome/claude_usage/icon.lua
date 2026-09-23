-- icon.lua - a cairo-drawn starburst icon widget (awesome only).

local wibox = require("wibox")
local gears = require("gears")
local cairo = require("lgi").cairo

local M = {}

-- Twelve rays of uneven length and slightly uneven spacing, thick with round caps.
local RAYS = {
	{ 0.00, 1.00 },
	{ 0.52, 0.78 },
	{ 1.02, 0.96 },
	{ 1.60, 0.74 },
	{ 2.08, 1.00 },
	{ 2.62, 0.80 },
	{ 3.14, 0.94 },
	{ 3.66, 0.76 },
	{ 4.16, 1.00 },
	{ 4.72, 0.80 },
	{ 5.22, 0.96 },
	{ 5.76, 0.74 },
}

--- Draw the starburst into a cairo context.
---@param cr any cairo context
---@param width number
---@param height number
---@param color string|table anything gears.color accepts
function M.draw(cr, width, height, color)
	local size = math.min(width, height)
	local cx, cy = width / 2, height / 2
	local r = size / 2
	cr:save()
	cr:set_source(gears.color(color))
	cr:set_line_width(math.max(1, r * 0.24))
	cr:set_line_cap(cairo.LineCap.ROUND)
	for _, ray in ipairs(RAYS) do
		local angle, len = ray[1], ray[2]
		local inner = r * 0.14
		local outer = r * len * 0.86
		cr:move_to(cx + math.cos(angle) * inner, cy + math.sin(angle) * inner)
		cr:line_to(cx + math.cos(angle) * outer, cy + math.sin(angle) * outer)
		cr:stroke()
	end
	cr:restore()
end

--- Create the icon widget.
---@param args { size: number, color: string }
---@return table widget with :set_color(color)
function M.starburst(args)
	local w = wibox.widget.base.make_widget(nil, "claude_usage.starburst")
	w._size = args.size or 14
	w._color = args.color or "#D97757"

	function w:fit(_, width, height)
		local s = math.min(self._size, width, height)
		return s, s
	end

	function w:draw(_, cr, width, height)
		M.draw(cr, width, height, self._color)
	end

	function w:set_color(color)
		if self._color ~= color then
			self._color = color
			self:emit_signal("widget::redraw_needed")
		end
	end

	function w:set_size(size)
		self._size = size
		self:emit_signal("widget::layout_changed")
	end

	return w
end

return M
