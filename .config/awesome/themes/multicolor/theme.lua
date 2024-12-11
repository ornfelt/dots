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
theme.wallpaper                                 = theme.confdir .. "/wall.png"
--theme.font                                      = "JetBrainsMono Nerd Font 11"
theme.font                                      = "JetBrainsMono Nerd Font Bold 11"
theme.taglist_font                              = "JetBrainsMono Nerd Font Bold 11"
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
theme.useless_gap                               = 8
theme.layout_txt_tile                           = "[t]"
theme.layout_txt_tileleft                       = "[l]"
theme.layout_txt_tilebottom                     = "[b]"
theme.layout_txt_tiletop                        = "[tt]"
theme.layout_txt_fairv                          = "[fv]"
theme.layout_txt_fairh                          = "[fh]"
theme.layout_txt_spiral                         = " [@]"
theme.layout_txt_dwindle                        = "[d]"
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

local markup = lain.util.markup

-- Textclock
os.setlocale(os.getenv("LANG")) -- to localize the clock
--local clockicon = wibox.widget.imagebox(theme.widget_clock)
local clockicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#8ec07c", "󰥔 "),
    align = "center",
    valign = "center"
}

--local mytextclock = wibox.widget.textclock(markup("#7788af", "%A %d %B ") .. markup("#ab7367", ">") .. markup("#de5e1e", " %H:%M "))

local mytextclock = wibox.widget.textclock(markup("#8ec07c", "%A %d %B ") .. markup("#8ec07c", "—") .. markup("#8ec07c", " %H:%M "))
mytextclock.font = theme.font

-- Calendar
theme.cal = lain.widget.cal({
    attach_to = { mytextclock },
    notification_preset = {
        font = "Terminus 10",
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    }
})

-- Weather
--local weathericon = wibox.widget.imagebox(theme.widget_weather)

local gruvbox_blue = "#458588"
local gruvbox_red = "#cc241d"
local default_color = "#ebdbb2"

local weathericon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, default_color, "   "),
    align = "center",
    valign = "center"
}

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

local weather_widget = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, default_color, "Loading..."),
    align = "center",
    valign = "center",
}

local function log_weather_update(message)
    local log_file = "/home/jonas/awesome_weather_update.log"
    local log_entry = os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n"

    local file = io.open(log_file, "a")
    if file then
        file:write(log_entry)
        file:close()
    else
        print("Failed to open log file for writing: " .. log_file)
    end
end

local function update_weather_widget()
    local script_path = "~/.local/bin/statusbar/weather"

    awful.spawn.easy_async_with_shell(script_path, function(stdout, stderr)
        if stderr and #stderr > 0 then
            weather_widget:set_markup(markup.fontfg(theme.font, default_color, "Error"))
            weathericon:set_markup(markup.fontfg(theme.font, default_color, "   "))
            return
        end

        local output = stdout:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        local units = tonumber(output:match("%-?%d+")) -- Extract numeric temperature
        local color

        if units then
            if units < 0 then
                color = gruvbox_blue
            elseif units > 20 then
                color = gruvbox_red
            else
                color = default_color
            end
            weather_widget:set_markup(markup.fontfg(theme.font, color, output))
            weathericon:set_markup(markup.fontfg(theme.font, color, "   "))
        else
            weather_widget:set_markup(markup.fontfg(theme.font, default_color, output))
            weathericon:set_markup(markup.fontfg(theme.font, default_color, "   "))
        end

        local log_message = "Weather output updated: " .. output
        log_weather_update(log_message)
    end)
end

gears.timer({
    timeout = 600,
    autostart = true,
    callback = update_weather_widget,
})

update_weather_widget()

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

-- CPU
--local cpuicon = wibox.widget.imagebox(theme.widget_cpu)

local cpuicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#b16286", "  "),
    align = "center",
    valign = "center"
}

local cpu = lain.widget.cpu({
    settings = function()
        --widget:set_markup(markup.fontfg(theme.font, "#e33a6e", cpu_now.usage .. "% "))
        widget:set_markup(markup.fontfg(theme.font, "#b16286", cpu_now.usage .. "% "))
    end
})

-- Coretemp
--local tempicon = wibox.widget.imagebox(theme.widget_temp)
local tempicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#d79921", "  "),
    align = "center",
    valign = "center"
}
local temp = lain.widget.temp({
    settings = function()
        --widget:set_markup(markup.fontfg(theme.font, "#f1af5f", coretemp_now .. "°C "))
        widget:set_markup(markup.fontfg(theme.font, "#d79921", coretemp_now .. "°C "))
    end
})

-- Battery
--local baticon = wibox.widget.imagebox(theme.widget_batt)
local baticon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#d3869b", "  "),
    align = "center",
    valign = "center"
}
--local bat = lain.widget.bat({
--    settings = function()
--        local perc = bat_now.perc ~= "N/A" and bat_now.perc .. "%" or bat_now.perc
--
--        if bat_now.ac_status == 1 then
--            perc = perc .. " plug"
--        end
--
--        --widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, perc .. " "))
--        widget:set_markup(markup.fontfg(theme.font, "#d3869b", perc .. " "))
--    end
--})
local bat = lain.widget.bat({
    settings = function()
        local perc = bat_now.perc ~= "N/A" and tonumber(bat_now.perc) or nil
        local icon = " "

        if bat_now.ac_status == 1 then
            icon = "󰂄"
        elseif perc then
            -- Icons based on percentage
            if perc >= 80 then
                icon = " "
            elseif perc >= 60 then
                icon = " "
            elseif perc >= 40 then
                icon = " "
            elseif perc >= 20 then
                icon = " "
            else
                icon = " "
            end
        end

        baticon:set_markup(markup.fontfg(theme.font, "#d3869b", " " .. icon .. " "))
        widget:set_markup(markup.fontfg(theme.font, "#d3869b", (perc or "100") .. "%  "))
    end
})

-- ALSA volume
--local volicon = wibox.widget.imagebox(theme.widget_vol)
local volicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#83a598", " 󰕾 "),
    align = "center",
    valign = "center"
}
theme.volume = lain.widget.alsa({
    settings = function()
        --if volume_now.status == "off" then
        --  volume_now.level = volume_now.level .. "M"
        --end
        if volume_now.status == "off" then
            volicon:set_markup(markup.fontfg(theme.font, "#83a598", " 󰖁 "))
        else
            volicon:set_markup(markup.fontfg(theme.font, "#83a598", " 󰕾 "))
        end

        widget:set_markup(markup.fontfg(theme.font, "#83a598", volume_now.level .. "% "))
    end
})

-- Net
--local netdownicon = wibox.widget.imagebox(theme.widget_netdown)
local netdowninfo = wibox.widget.textbox()
--local netupicon = wibox.widget.imagebox(theme.widget_netup)
local netupinfo = lain.widget.net({
    settings = function()
        --if iface ~= "network off" and
        --   string.match(theme.weather.widget.text, "N/A")
        --then
        --    theme.weather.update()
        --end
        --theme.weather.update()

        --widget:set_markup(markup.fontfg(theme.font, "#e54c62", net_now.sent .. " "))
        --netdowninfo:set_markup(markup.fontfg(theme.font, "#87af5f", net_now.received .. " "))
        widget:set_markup(markup.fontfg(theme.font, "#fe8019", net_now.sent .. " "))
        netdowninfo:set_markup(markup.fontfg(theme.font, "#689d6a", net_now.received .. " "))
    end
})

local netupicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#fe8019", " "),
    align = "center",
    valign = "center"
}

local netdownicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#689d6a", "  "),
    align = "center",
    valign = "center"
}

-- MEM
--local memicon = wibox.widget.imagebox(theme.widget_mem)
local memicon = wibox.widget {
    widget = wibox.widget.textbox,
    markup = markup.fontfg(theme.font, "#fabd2f", " 󰍛 "),
    align = "center",
    valign = "center"
}

local memory = lain.widget.mem({
    settings = function()
        --widget:set_markup(markup.fontfg(theme.font, "#e0da37", mem_now.used .. "M "))
        widget:set_markup(markup.fontfg(theme.font, "#fabd2f", mem_now.used .. "M "))
    end
})

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

local spotify_widget = require("lain.widget.spotify-widget.spotify")

local custom_spotify_widget = spotify_widget({
    font = theme.font,
    dim_when_paused = true,
    dim_opacity = 0.5,
    max_length = -1,
})

 -- Spotify widget with left, right, top, bottom margins
local spotify_widget_with_margin = wibox.container.margin(custom_spotify_widget, 0, 3, 0, 0)

local function update_txt_layoutbox(s)
    -- Writes a string representation of the current layout in a textbox widget
    local txt_l = theme["layout_txt_" .. awful.layout.getname(awful.layout.get(s))] or ""
    s.mytxtlayoutbox:set_text(txt_l)
end

function toggle_widget_visibility()
  local widgets_to_toggle = {
    netdownicon,
    netdowninfo,
    netupicon,
    netupinfo.widget,
    memicon,
    memory.widget,
    cpuicon,
    cpu.widget,
  }

  for _, widget in ipairs(widgets_to_toggle) do
    widget.visible = not widget.visible
  end
end

function theme.at_screen_connect(s)
    -- Quake application
    s.quake = lain.util.quake({ app = awful.util.terminal })

    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    -- Tags
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.

    -- We need one layoutbox per screen.
    s.mytxtlayoutbox = wibox.widget.textbox(theme["layout_txt_" .. awful.layout.getname(awful.layout.get(s))])
    awful.tag.attached_connect_signal(s, "property::selected", function () update_txt_layoutbox(s) end)
    awful.tag.attached_connect_signal(s, "property::layout", function () update_txt_layoutbox(s) end)
    s.mytxtlayoutbox:buttons(my_table.join(
                           awful.button({}, 1, function() awful.layout.inc(1) end),
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

    -- Create a tasklist widget
    --s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

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
        --s.mytasklist, -- Middle widget
        nil,
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
            spotify_widget_with_margin,
            netdownicon,
            netdowninfo,
            netupicon,
            netupinfo.widget,
            memicon,
            memory.widget,
            cpuicon,
            cpu.widget,
            --fsicon,
            --theme.fs.widget,
            weathericon,
            --theme.weather.widget,
            weather_widget,
            tempicon,
            temp.widget,
            volicon,
            theme.volume.widget,
            baticon,
            bat.widget,
            clockicon,
            mytextclock,
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
