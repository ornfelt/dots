-- widget.lua - the wibar widget: icon, text, chip background, mouse buttons, popup (awesome only).

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local prefix = (...):match("^(.*%.)") or ""
local format = require(prefix .. "format")
local brand = require(prefix .. "brand")
local icon = require(prefix .. "icon")
local popup = require(prefix .. "popup")

local M = {}

--- Create the widget.
---@param model table usage model (already set up)
---@param opts table resolved options
---@return table widget  wibox.container.background; fields .textbox, .icon, .model, .popup
function M.new(model, opts)
	local font = opts.font or beautiful.font
	local _, font_size = brand.font_parts(font)
	local chip = opts.style == "chip"

	local textbox = wibox.widget({
		widget = wibox.widget.textbox,
		font = font,
		align = opts.align or "center",
		valign = "center",
	})

	local row = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(5),
	})

	local icon_widget = nil
	if opts.icon == "starburst" then
		icon_widget = icon.starburst({
			size = opts.icon_size or dpi(math.floor(font_size * 1.35 + 0.5)),
			color = chip and opts.chip.fg or (opts.colors.icon or brand.palette.orange),
		})
		row:add(wibox.container.place(icon_widget, "center", "center"))
	end
	row:add(textbox)

	local inner = row
	if opts.forced_width then
		inner = wibox.widget({
			row,
			halign = opts.align or "center",
			forced_width = opts.forced_width,
			widget = wibox.container.place,
		})
	end

	if opts.compact then
		textbox.visible = false
	end

	local container
	local fill_percent = 0
	if chip then
		local radius = dpi(opts.chip.radius or 6)
		local pad_x = opts.compact and dpi(opts.chip.padding_x or 8) + dpi(6) or dpi(opts.chip.padding_x or 8)
		container = wibox.widget({
			{
				inner,
				left = pad_x,
				right = pad_x,
				top = dpi(opts.chip.padding_y or 1),
				bottom = dpi(opts.chip.padding_y or 1),
				widget = wibox.container.margin,
			},
			bg = opts.chip.normal,
			fg = opts.chip.fg,
			shape = function(cr, w, h)
				gears.shape.rounded_rect(cr, w, h, radius)
			end,
			widget = wibox.container.background,
		})
		if opts.compact then
			-- The chip itself becomes the bar: track colour behind, level colour filling from the left.
			container.bg = opts.chip.track or "#3A3835"
			container.bgimage = function(_, cr, width, height)
				local fill = width * math.max(0, math.min(fill_percent, 100)) / 100
				if fill > 0 then
					cr:set_source(gears.color(container._fill_color or opts.chip.normal))
					cr:rectangle(0, 0, fill, height)
					cr:fill()
				end
			end
		end
	else
		container = wibox.widget({
			inner,
			widget = wibox.container.background,
		})
	end

	-- Remember the wibox and drawable we are drawn into, so the popup can be placed
	-- next to the widget without the mouse being over it (see geometry_hint).
	local orig_draw = container.draw
	container.draw = function(self, context, cr, width, height)
		self._context_wibox = context.wibox
		self._context_drawable = context.drawable
		if orig_draw then
			return orig_draw(self, context, cr, width, height)
		end
	end

	--- Geometry of this widget relative to its wibox (plus `drawable` and `screen`), in the
	--- same shape as mouse.current_widget_geometry, or nil before its first draw.
	--- awful.placement.next_to needs the drawable to turn it into screen coordinates.
	function container.geometry_hint()
		local wb, d = container._context_wibox, container._context_drawable
		if not wb or not d or not d._widget_hierarchy then
			return nil
		end
		local function walk(h)
			if h:get_widget() == container then
				return h
			end
			for _, child in ipairs(h:get_children()) do
				local found = walk(child)
				if found then
					return found
				end
			end
			return nil
		end
		local h = walk(d._widget_hierarchy)
		if not h then
			return nil
		end
		local w, hgt = h:get_size()
		local x, y, ww, hh = h:get_matrix_to_device():transform_rectangle(0, 0, w, hgt)
		return { x = x, y = y, width = ww, height = hh, drawable = wb, screen = wb.screen }
	end

	-- The glyph is only part of the text when no drawn icon is present.
	local text_opts = setmetatable({ show_glyph = opts.icon == "glyph" and opts.show_glyph }, { __index = opts })

	local function render(state)
		local text = gears.string.xml_escape(format.bar_text(state, text_opts))
		if chip and opts.compact then
			fill_percent = format.max_percent(state, opts) or 0
			container._fill_color = format.chip_color(state, opts)
			container:emit_signal("widget::redraw_needed")
		elseif chip then
			container.bg = format.chip_color(state, opts)
		elseif opts.color_target ~= "none" then
			local color = format.color_for(state, opts)
			if color then
				text = string.format('<span foreground="%s">%s</span>', color, text)
			end
		end
		textbox:set_markup(text)
		if opts.compact then
			-- keep the flags visible even in compact mode
			local flags = text:match("[%$\u{2691}!]+%s*$")
			textbox.visible = flags ~= nil
			if flags then
				textbox:set_markup(flags)
			end
		end
	end

	render(model.state)
	model.subscribe(render)

	local popup_handle = nil
	if opts.popup then
		popup_handle = popup.attach(container, model, opts)
	end

	local function run_action(action, default)
		if type(action) == "function" then
			local ok, err = pcall(action, model.state, container)
			if not ok then
				gears.debug.print_warning("claude_usage: click handler failed: " .. tostring(err))
			end
		elseif type(action) == "string" and action ~= "" then
			awful.spawn.with_shell(action)
		elseif default then
			default()
		end
	end

	container.buttons = {
		awful.button({}, 1, function()
			run_action(opts.on_click)
		end),
		awful.button({}, 2, function()
			run_action(opts.on_middle_click, function()
				if popup_handle then
					popup_handle:toggle_pinned()
				end
			end)
		end),
		awful.button({}, 3, function()
			run_action(opts.on_right_click, function()
				model.refresh({ force = true })
			end)
		end),
	}

	container.textbox = textbox
	container.icon = icon_widget
	container.model = model
	container.popup = popup_handle
	return container
end

return M
