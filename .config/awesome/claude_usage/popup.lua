-- popup.lua - the details popup: header with logo, one bar per usage window, footer (awesome only).

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local prefix = (...):match("^(.*%.)") or ""
local format = require(prefix .. "format")
local brand = require(prefix .. "brand")
local icon = require(prefix .. "icon")
local bar = require(prefix .. "bar")
local history = require(prefix .. "history")

local M = {}

local function esc(s)
	return gears.string.xml_escape(tostring(s or ""))
end

local function span(text, color, extra)
	return string.format('<span foreground="%s"%s>%s</span>', color, extra or "", esc(text))
end

--- Build the popup content widget from structured rows.
---@param rows table from format.popup_rows
---@param opts table resolved options
---@return table widget
function M.build(rows, opts, samples)
	local c = opts.popup_colors
	local base_font = opts.font or beautiful.font
	local _, size = brand.font_parts(base_font)
	local f_title = brand.font(base_font, size + 2, "Bold")
	local f_body = brand.font(base_font, size)
	local f_small = brand.font(base_font, math.max(size - 1, 7))
	local f_pct = brand.font(base_font, size + 1, "Bold")

	local function textbox(markup, font, align)
		return wibox.widget({
			markup = markup,
			font = font,
			align = align or "left",
			widget = wibox.widget.textbox,
		})
	end

	local function level_color(level)
		if level == "crit" then
			return c.crit
		elseif level == "warn" then
			return c.warn
		end
		return c.accent
	end

	local body = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(10),
	})

	-- Header: logo + title + subtitle
	local title_lines = wibox.widget({
		textbox(span(rows.title, c.fg), f_title),
		textbox(span(rows.subtitle or "", c.muted), f_small),
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(1),
	})
	body:add(wibox.widget({
		wibox.container.place(icon.starburst({ size = dpi(size * 2.6), color = c.accent }), "center", "center"),
		title_lines,
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(10),
	}))

	-- Usage windows
	local now = os.time()
	local spark_from = now - (opts.sparkline_hours or 24) * 3600
	local function bar_row(label, subtext, percent, level, right_text, note, extra)
		extra = extra or {}
		local color = level_color(level)
		local pct_markup = percent and span(string.format("%d%%", format.round(percent)), color, ' font_weight="bold"')
			or span("--", c.muted)
		local head = wibox.widget({
			{
				textbox(span(label, c.fg, ' font_weight="bold"'), f_body),
				subtext and textbox(span(subtext, c.muted), f_small) or nil,
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(6),
			},
			nil,
			textbox(right_text or pct_markup, f_pct, "right"),
			layout = wibox.layout.align.horizontal,
		})
		local progress = bar.bar({
			value = percent or 0,
			color = color,
			track = c.track,
			marker = extra.pace,
			marker_color = c.muted,
			height = dpi(6),
		})
		local row = wibox.widget({
			head,
			progress,
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(4),
		})
		if note then
			row:add(textbox(span(note, c.muted), f_small))
		end
		if extra.forecast then
			local fcolor = extra.forecast_level == "normal" and c.muted or level_color(extra.forecast_level)
			row:add(textbox(span(extra.forecast, fcolor), f_small))
		end
		if extra.series and #extra.series >= 2 then
			-- Show at least one hour, at most sparkline_hours, starting where the data starts.
			local first = extra.series[1].t
			local from = math.max(spark_from, math.min(first, now - 3600))
			row:add(bar.sparkline({
				points = extra.series,
				from = from,
				to = now,
				color = color,
				track = c.track,
				height = dpi(16),
			}))
		end
		return row
	end

	if rows.empty then
		body:add(textbox(span(rows.empty, c.muted), f_body))
	end
	for _, w in ipairs(rows.windows or {}) do
		local note = w.reset
		if w.active and note then
			note = note .. " · active limit"
		elseif w.active then
			note = "active limit"
		end
		local series = (samples and w.key) and history.series(samples, w.key, spark_from) or nil
		body:add(bar_row(w.label, w.sub, w.percent, w.level, nil, note, {
			pace = w.pace,
			forecast = w.forecast,
			forecast_level = w.forecast_level,
			series = series,
		}))
	end
	if rows.spend then
		body:add(bar_row(rows.spend.label, nil, rows.spend.percent, rows.spend.level, nil, rows.spend.text))
	end
	if rows.breakdown then
		body:add(textbox(span("This week: " .. rows.breakdown, c.muted), f_small))
	end

	-- Active session context window
	if rows.context then
		body:add(textbox(span(rows.context, c.muted), f_small))
	end

	-- Sessions
	if rows.sessions and rows.sessions.text then
		local color = rows.sessions.attention > 0 and c.warn or c.muted
		body:add(textbox(span(rows.sessions.text, color), f_small))
	end

	-- Footer
	local footer_parts = {}
	if rows.error then
		body:add(textbox(span(rows.error, c.warn), f_small))
	end
	for _, line in ipairs(rows.footer or {}) do
		footer_parts[#footer_parts + 1] = line
	end
	if #footer_parts > 0 then
		body:add(wibox.widget({
			{
				forced_height = dpi(1),
				color = c.border,
				widget = wibox.widget.separator,
			},
			textbox(span(table.concat(footer_parts, " · "), c.muted), f_small),
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(6),
		}))
	end

	return wibox.widget({
		body,
		margins = dpi(14),
		widget = wibox.container.margin,
	})
end

--- Attach a popup to `widget`. Returns a handle with :toggle_pinned(), :show(), :hide().
---@param widget table wibox widget
---@param model table the usage model
---@param opts table resolved options
function M.attach(widget, model, opts)
	local c = opts.popup_colors
	local popup, unsub
	local pinned = false
	local radius = dpi(opts.popup_radius or 10)

	local function ensure_popup()
		if popup then
			return popup
		end
		-- awful.popup measures its content at 9999 px unless maximum_width is set; wrapped
		-- text would then be measured as one line and get clipped at the bottom.
		local width = dpi(opts.popup_width or 300)
		popup = awful.popup({
			widget = wibox.widget({ layout = wibox.layout.fixed.vertical }),
			minimum_width = width,
			maximum_width = width,
			ontop = true,
			visible = false,
			bg = c.bg,
			fg = c.fg,
			border_width = dpi(opts.popup_border_width or 1),
			border_color = c.border,
			shape = function(cr, w, h)
				gears.shape.rounded_rect(cr, w, h, radius)
			end,
		})
		return popup
	end

	local function fill(state)
		local p = ensure_popup()
		local samples = model.samples and model.samples() or nil
		local ok, content = pcall(M.build, format.popup_rows(state, os.time(), opts), opts, samples)
		if ok then
			p.widget = content
		else
			gears.debug.print_warning("claude_usage: popup build failed: " .. tostring(content))
		end
	end

	local handle = {}
	local keygrabber = nil
	local grabbing_mouse = false

	local function stop_grabs()
		if keygrabber then
			keygrabber:stop()
			keygrabber = nil
		end
		if grabbing_mouse then
			grabbing_mouse = false
			mousegrabber.stop()
		end
	end

	local function start_grabs()
		if opts.popup_escape ~= false and not keygrabber then
			keygrabber = awful.keygrabber({
				stop_key = "Escape",
				stop_event = "press",
				autostart = true,
				stop_callback = function()
					keygrabber = nil
					handle:hide()
				end,
			})
		end
		if opts.popup_click_away ~= false and not grabbing_mouse then
			grabbing_mouse = true
			mousegrabber.run(function(m)
				if m.buttons[1] or m.buttons[2] or m.buttons[3] then
					grabbing_mouse = false
					handle:hide()
					return false
				end
				return grabbing_mouse
			end, "left_ptr")
		end
	end

	function handle:show(anchor)
		local p = ensure_popup()
		if not unsub then
			unsub = model.subscribe(fill)
		else
			fill(model.state)
		end
		local geo = anchor or mouse.current_widget_geometry
		-- A placement function is re-applied by awful.popup whenever the content changes size,
		-- so a growing popup stays on screen instead of sliding under the bar.
		if opts.popup_placement then
			p.placement = function(d)
				return opts.popup_placement(d, geo)
			end
		elseif geo then
			p.placement = function(d)
				return awful.placement.next_to(d, {
					preferred_positions = { "top", "bottom" },
					preferred_anchors = "middle",
					geometry = geo,
					margins = { top = dpi(6), bottom = dpi(6) },
					honor_workarea = true,
				})
			end
		else
			p.placement = function(d)
				awful.placement.under_mouse(d)
				return awful.placement.no_offscreen(d)
			end
		end
		p.visible = true
	end

	function handle:hide()
		pinned = false
		stop_grabs()
		if unsub then
			unsub()
			unsub = nil
		end
		if popup then
			popup.visible = false
		end
	end

	function handle:pin(anchor)
		handle:show(anchor)
		pinned = true
		start_grabs()
	end

	function handle:toggle_pinned(anchor)
		if pinned then
			handle:hide()
		else
			handle:pin(anchor)
		end
	end

	function handle:is_pinned()
		return pinned
	end

	widget:connect_signal("mouse::enter", function()
		if not pinned then
			handle:show()
		end
	end)
	widget:connect_signal("mouse::leave", function()
		if not pinned then
			handle:hide()
		end
	end)

	return handle
end

return M
