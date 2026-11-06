--[[

     Multicolor Awesome WM theme 2.0
     github.com/lcpz

--]]

local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi   = require("beautiful.xresources").apply_dpi

local os = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme                                     = {}
theme.confdir                                   = os.getenv("HOME") .. "/.config/awesome/themes/multicolor"
--theme.wallpaper                                 = theme.confdir .. "/wall.png"
--theme.font                                      = "JetBrainsMono Nerd Font 11"
-- Propo: the icons are as wide as they are drawn, so one gap after an icon
-- looks the same for every icon (see ~/.local/bin/statusbar/sb-theme)
theme.font                                      = "JetBrainsMono Nerd Font Propo Bold 11"
theme.taglist_font                              = "JetBrainsMono Nerd Font Propo Bold 11"
theme.menu_bg_normal                            = "#282828"
theme.menu_bg_focus                             = "#282828"
theme.bg_normal                                 = "#282828"
theme.bg_focus                                  = "#282828"
theme.bg_urgent                                 = "#282828"
--theme.fg_normal                                 = "#aaaaaa"
theme.fg_normal                                 = "#ebdbb2"
--theme.fg_focus                                  = "#ff8c00"
theme.fg_focus                                  = "#282828"
theme.fg_urgent                                 = "#af1d18"
theme.fg_minimize                               = "#ffffff"
theme.border_width                              = dpi(1)
theme.border_normal                             = "#1c2022"
theme.border_focus                              = "#ebdbb2"
theme.border_marked                             = "#3ca4d8"
theme.menu_border_width                         = 0
theme.menu_width                                = dpi(130)
theme.menu_submenu_icon                         = theme.confdir .. "/icons/submenu.png"
theme.menu_fg_normal                            = "#aaaaaa"
theme.menu_fg_focus                             = "#ff8c00"
theme.menu_bg_normal                            = "#050505dd"
theme.menu_bg_focus                             = "#050505dd"
theme.widget_temp                               = theme.confdir .. "/icons/temp.png"
theme.widget_uptime                             = theme.confdir .. "/icons/ac.png"
theme.widget_cpu                                = theme.confdir .. "/icons/cpu.png"
theme.widget_weather                            = theme.confdir .. "/icons/dish.png"
theme.widget_fs                                 = theme.confdir .. "/icons/fs.png"
theme.widget_mem                                = theme.confdir .. "/icons/mem.png"
theme.widget_note                               = theme.confdir .. "/icons/note.png"
theme.widget_note_on                            = theme.confdir .. "/icons/note_on.png"
--theme.widget_netdown                            = theme.confdir .. "/icons/net_down.png"
--theme.widget_netup                              = theme.confdir .. "/icons/net_up.png"
theme.widget_mail                               = theme.confdir .. "/icons/mail.png"
theme.widget_batt                               = theme.confdir .. "/icons/bat.png"
theme.widget_clock                              = theme.confdir .. "/icons/clock.png"
--theme.widget_vol                                = theme.confdir .. "/icons/spkr.png"
--theme.taglist_squares_sel                       = theme.confdir .. "/icons/square_a.png"
--theme.taglist_squares_unsel                     = theme.confdir .. "/icons/square_b.png"
theme.tasklist_plain_task_name                  = true
theme.tasklist_disable_icon                     = true
-- fg_focus is the dark text of the selected tag
theme.tasklist_fg_focus                         = theme.fg_normal
theme.useless_gap                               = 10
theme.layout_txt_tile                           = "[t]"
theme.layout_txt_tileleft                       = "[l]"
theme.layout_txt_tilebottom                     = "[b]"
theme.layout_txt_tiletop                        = "[tt]"
theme.layout_txt_fairv                          = "[fv]"
theme.layout_txt_fairh                          = "[fh]"
theme.layout_txt_spiral                         = "[Φ]"
--theme.layout_txt_spiral                       = "[@]" -- the old symbol
theme.layout_txt_dwindle                        = "[d]"
theme.layout_txt_centerwork                     = "|M|"
theme.layout_txt_max                            = "[m]"
theme.layout_txt_fullscreen                     = "[F]"
theme.layout_txt_magnifier                      = "[M]"
theme.layout_txt_floating                       = "[*]"
theme.layout_tile                               = theme.confdir .. "/icons/tile.png"
theme.layout_tilegaps                           = theme.confdir .. "/icons/tilegaps.png"
theme.layout_tileleft                           = theme.confdir .. "/icons/tileleft.png"
theme.layout_tilebottom                         = theme.confdir .. "/icons/tilebottom.png"
theme.layout_tiletop                            = theme.confdir .. "/icons/tiletop.png"
theme.layout_fairv                              = theme.confdir .. "/icons/fairv.png"
theme.layout_fairh                              = theme.confdir .. "/icons/fairh.png"
theme.layout_spiral                             = theme.confdir .. "/icons/spiral.png"
theme.layout_dwindle                            = theme.confdir .. "/icons/dwindle.png"
theme.layout_max                                = theme.confdir .. "/icons/max.png"
theme.layout_fullscreen                         = theme.confdir .. "/icons/fullscreen.png"
theme.layout_magnifier                          = theme.confdir .. "/icons/magnifier.png"
theme.layout_floating                           = theme.confdir .. "/icons/floating.png"
theme.titlebar_close_button_normal              = theme.confdir .. "/icons/titlebar/close_normal.png"
theme.titlebar_close_button_focus               = theme.confdir .. "/icons/titlebar/close_focus.png"
theme.titlebar_minimize_button_normal           = theme.confdir .. "/icons/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus            = theme.confdir .. "/icons/titlebar/minimize_focus.png"
theme.titlebar_ontop_button_normal_inactive     = theme.confdir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive      = theme.confdir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active       = theme.confdir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active        = theme.confdir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_sticky_button_normal_inactive    = theme.confdir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive     = theme.confdir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active      = theme.confdir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active       = theme.confdir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_floating_button_normal_inactive  = theme.confdir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive   = theme.confdir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active    = theme.confdir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active     = theme.confdir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive = theme.confdir .. "/icons/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = theme.confdir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   = theme.confdir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    = theme.confdir .. "/icons/titlebar/maximized_focus_active.png"

-- Random wallpaper: any jpg/jpeg/png directly in ~/Pictures/Wallpapers.
-- If there is none, theme.wallpaper stays nil and the wallpaper is left alone.
local function get_random_wallpaper(directory)
    local wallpapers = {}
    local command = "find '" .. directory .. "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) 2>/dev/null"
    local handle = io.popen(command)
    if handle then
        for file in handle:lines() do
            table.insert(wallpapers, file)
        end
        handle:close()
    end

    if #wallpapers > 0 then
        math.randomseed(os.time())
        return wallpapers[math.random(#wallpapers)]
    end
end

theme.wallpaper = get_random_wallpaper(os.getenv("HOME") .. "/Pictures/Wallpapers")

local markup = lain.util.markup

-- Status modules, like dwm's blocks: each one runs its statusbar script, the
-- same as dwmblocks / dwmblocksc / dwmblocksr, with SB_BAR=awesome and shows
-- what it prints. The icons, colours, the gap after an icon (SB_GAP), the
-- separator between the visible modules (SB_SEP) and the room after the last
-- one (SB_EDGE) all come from ~/.local/bin/statusbar/sb-theme, so both bars
-- look the same and are changed in one place. A click runs the script with
-- BLOCK_BUTTON set, then updates the module, like dwm's clickable blocks.
-- sb-demo cycles every module through its variants (sb_refresh_all below).
local statusbar_dir = os.getenv("HOME") .. "/.local/bin/statusbar/"
local sb_demo_seed = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/sb-demo/seed"

-- NAME='value' lines of sb-theme (the sh scripts source it)
local function read_sb_theme(path)
    local t = {}
    local f = io.open(path, "r")
    if not f then return t end
    for line in f:lines() do
        local k, v = line:match("^%s*([%w_]+)='([^']*)'")
        if k then t[k] = v end
    end
    f:close()
    return t
end

local sb = read_sb_theme(statusbar_dir .. "sb-theme")
local SB_GAP  = sb.SB_GAP or " "
local SB_SEP  = sb.SB_SEP or "  "
local SB_EDGE = sb.SB_EDGE or ""

-- True while sb-demo runs
local function sb_demo_active()
    local f = io.open(sb_demo_seed, "r")
    if f then f:close() end
    return f ~= nil
end

-- Markup for the "colour<TAB>icon<TAB>value" lines a script prints
local function sb_markup(out)
    local parts = {}
    for line in out:gmatch("[^\n]+") do
        local color, icon, value = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
        if color then
            local text = (icon ~= "" and value ~= "") and (icon .. SB_GAP .. value) or (icon .. value)
            parts[#parts + 1] = markup.fg.color(color ~= "" and color or theme.fg_normal, gears.string.xml_escape(text))
        end
    end
    return table.concat(parts, SB_GAP)
end

-- The bar row: SB_SEP before each visible widget but the first, SB_EDGE at the end
local sb_row = wibox.layout.fixed.horizontal()
local sb_entries = {}

local function sb_update_separators()
    local seen = false
    for _, e in ipairs(sb_entries) do
        e.sep.visible = seen and e.widget.visible
        seen = seen or e.widget.visible
    end
end

local function sb_add(widget)
    local sep = wibox.widget { widget = wibox.widget.textbox, font = theme.font, text = SB_SEP, visible = false }
    sb_row:add(sep)
    sb_row:add(widget)
    sb_entries[#sb_entries + 1] = { widget = widget, sep = sep }
    sb_update_separators()
end

local sb_modules = {}
local SB_BUTTONS = { 1, 2, 3, 4, 5 }

-- A module for a script, updated every `interval` seconds. buttons = false
-- leaves the clicks to someone else (the clock's calendar).
local function sb_module(script, interval, buttons)
    local m = { hidden = false, has_text = false }
    local cmd = "SB_BAR=awesome " .. script
    m.widget = wibox.widget { widget = wibox.widget.textbox, font = theme.font, align = "center", valign = "center", visible = false }
    -- hidden (mod-ctrl-p) modules are shown during sb-demo
    function m.refresh_visibility()
        m.widget.visible = m.has_text and (not m.hidden or sb_demo_active())
    end
    function m.update()
        awful.spawn.easy_async_with_shell(cmd, function(stdout)
            m.has_text = stdout:find("%S") ~= nil
            m.widget:set_markup(sb_markup(stdout))
            m.refresh_visibility()
            sb_update_separators()
        end)
    end
    if buttons ~= false then
        local list = {}
        for _, button in ipairs(SB_BUTTONS) do
            list[#list + 1] = awful.button({}, button, function()
                awful.spawn.easy_async_with_shell("BLOCK_BUTTON=" .. button .. " " .. cmd, function() m.update() end)
            end)
        end
        m.widget:buttons(my_table.join(table.unpack(list)))
    end
    gears.timer({ timeout = interval, autostart = true, call_now = true, callback = m.update })
    sb_modules[#sb_modules + 1] = m
    return m
end

-- Spotify: the track, clicks: notification, play/pause, previous/next
local sb_spotify = sb_module(os.getenv("HOME") .. "/.local/bin/my_scripts/spotify_dwmblocks.sh", 5)
-- net down/up, memory and cpu, shown/hidden with mod-ctrl-p; left click: details
local sb_net     = sb_module(statusbar_dir .. "sb-sysinfo net", 2)
local sb_mem     = sb_module(statusbar_dir .. "sb-sysinfo mem", 2)
local sb_cpu     = sb_module(statusbar_dir .. "sb-sysinfo cpu", 2)
-- Network: a wifi or ethernet icon, cyan online, red offline, orange while
-- restarting NetworkManager, gray unknown. Left click: details, middle:
-- restart NetworkManager, right: wifi menu (wifi_menu.sh)
local sb_network = sb_module(statusbar_dir .. "sb-network", 3)
-- Weather, cpu temperature, volume, battery: left click a notification
-- (forecast, sensors and top processes, acpi) or mute, scroll the volume,
-- right click an update
local sb_weather = sb_module(statusbar_dir .. "weather", 600)
local sb_temp    = sb_module(statusbar_dir .. "cputemp", 5)
local sb_volume  = sb_module(statusbar_dir .. "sb-volume", 5)
local sb_battery = sb_module(statusbar_dir .. "sb-battery", 5)
-- Clock, with lain's calendar on hover and its clicks
local sb_clock   = sb_module(statusbar_dir .. "sb-clock", 30, false)

-- rc.lua's volume keys update the widget with beautiful.volume.update()
theme.volume = { widget = sb_volume.widget, update = sb_volume.update }

-- Calendar
theme.cal = lain.widget.cal({
    attach_to = { sb_clock.widget },
    notification_preset = {
        font = "Terminus 10",
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    }
})

--theme.weather = lain.widget.weather({
--    city_id = 2673730,
--    notification_preset = { font = theme.font, fg = theme.fg_normal },
--
--    weather_na_markup = markup.fontfg(theme.font, "#ebdbb2", "N/A "),
--    settings = function()
--        descr = weather_now["weather"][1]["description"]:lower()
--        units = math.floor(weather_now["main"]["temp"])
--        widget:set_markup(markup.fontfg(theme.font, "#ebdbb2", descr .. " @ " .. units .. "°C "))
--    end
--})
--theme.weather = lain.widget.weather({
--    city_id = 2673730,
--    notification_preset = { font = theme.font, fg = theme.fg_normal },
--    weather_na_markup = markup.fontfg(theme.font, default_color, "N/A"),
--
--    settings = function()
--        descr = weather_now["weather"][1]["description"]:lower()
--        units = math.floor(weather_now["main"]["temp"])
--
--        local color
--        if units < 0 then
--            color = gruvbox_blue
--        elseif units > 20 then
--            color = gruvbox_red
--        else
--            color = default_color
--        end
--
--        --widget:set_markup(markup.fontfg(theme.font, color, descr .. " @ " .. units .. "°C "))
--        widget:set_markup(markup.fontfg(theme.font, color, units .. "°C "))
--    end
--})

-- / fs
--[[ commented because it needs Gio/Glib >= 2.54
local fsicon = wibox.widget.imagebox(theme.widget_fs)
theme.fs = lain.widget.fs({
    notification_preset = { font = "Terminus 10", fg = theme.fg_normal },
    settings  = function()
        widget:set_markup(markup.fontfg(theme.font, "#80d9d8", string.format("%.1f", fs_now["/"].percentage) .. "% "))
    end
})
--]]

-- Mail IMAP check
--[[ to be set before use
local mailicon = wibox.widget.imagebox()
theme.mail = lain.widget.imap({
    timeout  = 180,
    server   = "server",
    mail     = "mail",
    password = "keyring get mail",
    settings = function()
        if mailcount > 0 then
            mailicon:set_image(theme.widget_mail)
            widget:set_markup(markup.fontfg(theme.font, "#cccccc", mailcount .. " "))
        else
            widget:set_text("")
            --mailicon:set_image() -- not working in 4.0
            mailicon._private.image = nil
            mailicon:emit_signal("widget::redraw_needed")
            mailicon:emit_signal("widget::layout_changed")
        end
    end
})
--]]

-- MPD
local mpdicon = wibox.widget.imagebox()
theme.mpd = lain.widget.mpd({
    settings = function()
        mpd_notification_preset = {
            text = string.format("%s [%s] - %s\n%s", mpd_now.artist,
                   mpd_now.album, mpd_now.date, mpd_now.title)
        }

        if mpd_now.state == "play" then
            artist = mpd_now.artist .. " > "
            title  = mpd_now.title .. " "
            mpdicon:set_image(theme.widget_note_on)
        elseif mpd_now.state == "pause" then
            artist = "mpd "
            title  = "paused "
        else
            artist = ""
            title  = ""
            --mpdicon:set_image() -- not working in 4.0
            mpdicon._private.image = nil
            mpdicon:emit_signal("widget::redraw_needed")
            mpdicon:emit_signal("widget::layout_changed")
        end
        widget:set_markup(markup.fontfg(theme.font, "#e54c62", artist) .. markup.fontfg(theme.font, "#b2b2b2", title))
    end
})

-- Claude Code usage (claude_usage/)
local claude_orange = sb.COLOR_CLAUDE or "#D97757"

-- Show the extra-usage amount (the " +30.19€" tail) in the bar. The popup still
-- reports the spend either way.
local claude_show_spend = false

-- The popup sits just below the mouse and tracks it while the widget is hovered.
local claude_usage  -- forward declaration, the follow timer needs it
local claude_popup

local claude_last_x, claude_last_y

local function claude_place_under_mouse(d, force)
    local coords = mouse.coords()
    if not force and coords.x == claude_last_x and coords.y == claude_last_y then
        return  -- pointer has not moved, nothing to reposition
    end
    claude_last_x, claude_last_y = coords.x, coords.y
    local wa = (mouse.screen or awful.screen.focused()).workarea
    local w, h = d.width, d.height
    local x = coords.x - math.floor(w / 2)
    local y = coords.y + dpi(16)

    -- keep it on screen: clamp horizontally, flip above the cursor if it would overflow
    if x < wa.x then x = wa.x end
    if x + w > wa.x + wa.width then x = wa.x + wa.width - w end
    if y + h > wa.y + wa.height then y = coords.y - h - dpi(8) end
    if y < wa.y then y = wa.y end

    d.x, d.y = x, y
end

local function claude_mouse_over_widget()
    local widgets = mouse.current_widgets
    if not widgets then return false end
    for _, w in ipairs(widgets) do
        if w == claude_usage then return true end
    end
    return false
end

-- Stops on its own once the popup closes or the pointer leaves the widget, so a
-- pinned popup stays where it was pinned instead of chasing the cursor.
local claude_follow_timer = gears.timer({
    timeout = 0.03,
    callback = function()
        if not claude_popup or not claude_popup.visible or not claude_mouse_over_widget() then
            claude_follow_timer:stop()
            return
        end
        claude_place_under_mouse(claude_popup)
    end,
})

claude_usage = require("claude_usage").new({
    on_click = (awful.util.terminal or "xterm") .. " -e claude",

    -- beautiful.font is not set yet while beautiful.init() runs this file, so the
    -- widget would fall back to "sans 10"; name the bar font explicitly. The icon
    -- size and the popup fonts are derived from it.
    font   = theme.font,

    spend_in_bar = claude_show_spend,

    -- no chip: icon and numbers drawn in Claude orange, red at the crit threshold
    style  = "bare",
    colors = {
        normal = claude_orange,
        icon   = claude_orange,
        warn   = claude_orange,  -- same as normal, so the text always matches the icon
        crit   = sb.COLOR_CLAUDE_CRIT,
        error  = sb.COLOR_CLAUDE_ERROR,
    },

    popup_placement = function(d)
        claude_popup = d
        claude_place_under_mouse(d, true)  -- also runs when the popup content resizes
        if not claude_follow_timer.started then
            claude_follow_timer:start()
        end
    end,
})

-- sb-demo: the text shows sb-claude's made-up usage (the same formatting as
-- the widget's) and the widget's own updates wait until the demo ends
local claude_textbox = claude_usage.textbox
local claude_set_markup = claude_textbox.set_markup
local claude_real_markup
local claude_in_demo = false
rawset(claude_textbox, "set_markup", function(self, text)
    claude_real_markup = text
    if not claude_in_demo then
        return claude_set_markup(self, text)
    end
    return true
end)

local function claude_demo_update()
    if sb_demo_active() then
        awful.spawn.easy_async_with_shell("SB_BAR=awesome " .. statusbar_dir .. "sb-claude", function(out)
            local color, _, text = out:match("^([^\t]*)\t([^\t]*)\t([^\n]*)")
            if color then
                claude_in_demo = true
                claude_set_markup(claude_textbox, markup.fg.color(color, gears.string.xml_escape(text)))
            end
        end)
    elseif claude_in_demo then
        claude_in_demo = false
        if claude_real_markup then
            claude_set_markup(claude_textbox, claude_real_markup)
        end
    end
end

-- The bar row, in dwm's order
sb_add(sb_spotify.widget)
sb_add(claude_usage)
sb_add(sb_net.widget)
sb_add(sb_mem.widget)
sb_add(sb_cpu.widget)
sb_add(sb_network.widget)
sb_add(sb_weather.widget)
sb_add(sb_temp.widget)
sb_add(sb_volume.widget)
sb_add(sb_battery.widget)
sb_add(sb_clock.widget)
sb_row:add(wibox.widget { widget = wibox.widget.textbox, font = theme.font, text = SB_EDGE })

-- Updates every module at once (sb-demo calls it through awesome-client on
-- every tick and once more at the end)
function sb_refresh_all()
    for _, m in ipairs(sb_modules) do
        m.update()
    end
    claude_demo_update()
end

local function update_txt_layoutbox(s)
    -- Writes a string representation of the current layout in a textbox widget,
    -- with one space before it, between it and the tag numbers
    local txt_l = theme["layout_txt_" .. awful.layout.getname(awful.layout.get(s))] or ""
    s.mytxtlayoutbox:set_text(" " .. txt_l)
end


local my_config_path = os.getenv("HOME") .. "/.config/my_config.txt"

local function read_config()
  local file = io.open(my_config_path, "r")
  if not file then
    return nil -- Return nil if the file doesn't exist
  end

  local config = {}
  for line in io.lines(my_config_path) do
    local key, value = line:match("^%s*(%S+)%s*:%s*(%S+)%s*$")
    if key and value then
      config[key] = value:lower() -- Store values in lowercase for case-insensitive comparison
    end
  end
  return config
end

local function write_config(key, value)
  local lines = {}
  local key_found = false

  -- Read existing lines if file exists
  local file = io.open(my_config_path, "r")
  if file then
    for line in file:lines() do
      local existing_key = line:match("^%s*(%S+)%s*:")
      if existing_key == key then
        table.insert(lines, key .. ": " .. tostring(value))
        key_found = true
      else
        table.insert(lines, line)
      end
    end
    file:close()
  end

  -- If key is not found, append it
  if not key_found then
    table.insert(lines, key .. ": " .. tostring(value))
  end

  -- Write to file (create if not exists)
  file = io.open(my_config_path, "w")
  if not file then
    error("Unable to open or create file: " .. my_config_path)
  end

  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()
end

local widgets_to_toggle = {
  sb_net,
  sb_mem,
  sb_cpu,
}

local function set_widget_visibility(visible)
  for _, m in ipairs(widgets_to_toggle) do
    m.hidden = not visible
    m.refresh_visibility()
  end
  sb_update_separators()
end

-- Shows/hides the widgets and saves it as awsm_bar_toggled (true is hidden).
-- The saved state is the new visibility, not the file's value flipped, so the
-- two cannot drift apart.
function toggle_widget_visibility()
  local hide = not sb_net.hidden
  set_widget_visibility(not hide)
  write_config("awsm_bar_toggled", tostring(hide))
end

-- Shows/hides the window title on every screen (dwm toggletitle)
local show_title = true

function toggle_title()
  show_title = not show_title
  for s in screen do
    s.mytasklist.visible = show_title
  end
end

function check_toggle_widget_visibility()
  local my_config = read_config()
  set_widget_visibility(not (my_config and my_config["awsm_bar_toggled"] == "true"))
end

function theme.at_screen_connect(s)
    -- Quake application
    -- lain finds the dropdown by its instance name; wezterm has no flag to set
    -- it (lain's default "-name %s" makes wezterm exit), so use st's -n
    s.quake = lain.util.quake({ app = "st", argname = "-n %s" })
    -- Scratchpads like dwm's spterm (python3) and spcalc (plain st)
    s.quake_py = lain.util.quake({ app = "st", argname = "-n %s", name = "spterm",
        extra = "-e python3", width = 0.5, height = 0.5, vert = "center", horiz = "center" })
    s.quake_calc = lain.util.quake({ app = "st", argname = "-n %s", name = "spcalc",
        width = 0.5, height = 0.5, vert = "center", horiz = "center" })

    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    if wallpaper then
        gears.wallpaper.maximized(wallpaper, s, true)
    end

    -- Tags
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.

    -- We need one layoutbox per screen.
    s.mytxtlayoutbox = wibox.widget.textbox()
    update_txt_layoutbox(s)
    awful.tag.attached_connect_signal(s, "property::selected", function () update_txt_layoutbox(s) end)
    awful.tag.attached_connect_signal(s, "property::layout", function () update_txt_layoutbox(s) end)
    s.mytxtlayoutbox:buttons(my_table.join(
                           awful.button({}, 1, function() awful.util.layout_menu() end),
                           awful.button({}, 2, function () awful.layout.set( awful.layout.layouts[1] ) end),
                           awful.button({}, 3, function() awful.layout.inc(-1) end),
                           awful.button({}, 4, function() awful.layout.inc(1) end),
                           awful.button({}, 5, function() awful.layout.inc(-1) end)))

    -- Create a taglist widget
    --s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)
    --s.mytaglist = awful.widget.taglist {
    --    screen = s,
    --    filter = function (t) return t.selected or #t:clients() > 0 end,
    --    --buttons = taglist_buttons
    --}

  local gruvbox_white = "#ebdbb2"
  local gruvbox_black = "#282828"

  -- Modify the taglist label function
  local original_taglist_label = awful.widget.taglist.taglist_label

  awful.widget.taglist.taglist_label = function(tag, args, tb)

    -- Use the original taglist_label function
    local text, bg, bg_image, icon, other_args = original_taglist_label(tag, args, tb)

    -- Customize colors based on whether the tag is selected
    if tag.selected then
      bg = gruvbox_white
      other_args.fg_focus = gruvbox_black
    else
      bg = gruvbox_black
      other_args.fg_focus = gruvbox_white
    end

    return text, bg, bg_image, icon, other_args
  end

  -- https://awesomewm.org/doc/api/classes/wibox.widget.textbox.html
  s.mytaglist = awful.widget.taglist {
    screen = s,
    filter = function(t) return t.selected or #t:clients() > 0 end,
    buttons = awful.util.taglist_buttons,
    layout = {
      --spacing = 8,
      --spacing = 2,
      layout = wibox.layout.fixed.horizontal,
    },
    widget_template = {
      {
        {
          id = "text_role",
          widget = wibox.widget.textbox,
        },
        widget = wibox.container.place, -- Center the text
        halign = "center", -- Horizontal alignment
      },
      id = "background_role",
      widget = wibox.container.background,
      forced_width = 30,
    },
  }

    -- The title of the focused window, after the layout. A screen without the
    -- focus shows its last focused window, like dwm's m->sel.
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = function (c, scr) return c == awful.client.focus.history.get(scr, 0) end,
    }
    s.mytasklist.visible = show_title

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = dpi(25), bg = theme.bg_normal, fg = theme.fg_normal })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            --s.mylayoutbox,
            s.mytaglist,
            s.mytxtlayoutbox,
            --s.mypromptbox,
            mpdicon,
            theme.mpd.widget,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            --wibox.widget.systray(),

            --mailicon,
            --theme.mail.widget,

            --spotify_widget({
            --    font = theme.font,
            --    -- play_icon = '/usr/share/icons/Papirus-Light/24x24/categories/spotify.svg',
            --    -- pause_icon = '/usr/share/icons/Papirus-Dark/24x24/panel/spotify-indicator.svg',
            --    dim_when_paused = true,
            --    dim_opacity = 0.5,
            --    max_length = -1,
            --}),
            --fsicon,
            --theme.fs.widget,
            --theme.weather.widget,
            -- spotify, claude, net, mem, cpu, network, weather, temp,
            -- volume, battery, clock, with the separators (see sb_add)
            sb_row,
        },
    }

    -- Create the bottom wibox
    --s.mybottomwibox = awful.wibar({ position = "bottom", screen = s, border_width = 0, height = dpi(20), bg = theme.bg_normal, fg = theme.fg_normal })

    -- Add widgets to the bottom wibox
    --s.mybottomwibox:setup {
    --    layout = wibox.layout.align.horizontal,
    --    { -- Left widgets
    --        layout = wibox.layout.fixed.horizontal,
    --    },
    --    s.mytasklist, -- Middle widget
    --    { -- Right widgets
    --        layout = wibox.layout.fixed.horizontal,
    --        s.mylayoutbox,
    --    },
    --}
end

return theme
