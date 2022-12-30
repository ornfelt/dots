local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

-- Standard awesome library
local gears         = require("gears") --Utilities such as color parsing and objects
local awful         = require("awful") --Everything related to window managment
                      require("awful.autofocus")
-- Widget and layout library
local wibox         = require("wibox")

-- Theme handling library
local beautiful     = require("beautiful")

-- Notification library
local naughty       = require("naughty")
naughty.config.defaults['icon_size'] = 100

local lain          = require("lain")
-- local freedesktop   = require("freedesktop")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
local my_table      = awful.util.table or gears.table -- 4.{0,1} compatibility

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

beautiful.init(require('theme'))
require('module.dashboard')

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

run_once({ "unclutter -root" }) -- entries must be comma-separated

local themes = {
    "powerarrow-blue", -- 1
    "powerarrow",      -- 2
    "multicolor",      -- 3
}

-- choose your theme here
local chosen_theme = themes[3]
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
beautiful.init(theme_path)

local modkey      = "Mod4"
local altkey      = "Mod1"
local ctrlkey     = "Control"
-- local terminal    = "urxvt"
local terminal    = "st"
local browser     = "firefox"
local editor      = os.getenv("EDITOR") or "vim"
local emacs       = "emacsclient -c -a 'emacs' "
local mediaplayer = "mpv"
local soundplayer = "ffplay -nodisp -autoexit " -- The program that will play system sounds

-- awesome variables
awful.util.terminal = terminal
awful.util.tagnames = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
-- awful.util.tagnames = { "", "", "", "", " ", " ", " ", " ", " " }
awful.layout.suit.tile.left.mirror = true
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    --awful.layout.suit.tile.left,
    --awful.layout.suit.tile.bottom,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    --awful.layout.suit.corner.nw,
    --awful.layout.suit.corner.ne,
    --awful.layout.suit.corner.sw,
    --awful.layout.suit.corner.se,
    --lain.layout.cascade,
    --lain.layout.cascade.tile,
    --lain.layout.centerwork,
    --lain.layout.centerwork.horizontal,
    --lain.layout.termfair,
    --lain.layout.termfair.center,
}

awful.util.taglist_buttons = my_table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = my_table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {raise = true})
        end
    end),
    awful.button({ }, 3, function ()
        local instance = nil

        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({theme = {width = 250}})
            end
        end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

beautiful.init(string.format(gears.filesystem.get_configuration_dir() .. "/themes/%s/theme.lua", chosen_theme))

local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e 'man awesome'" },
    { "edit config", "emacsclient -c -a emacs ~/.config/awesome/rc.lua" },
    { "arandr", "arandr" },
    { "restart", awesome.restart },
}

--awful.util.mymainmenu = freedesktop.menu.build({
--    icon_size = beautiful.menu_height or 16,
--    before = {
--        { "Awesome", myawesomemenu, beautiful.awesome_icon },
--        --{ "Atom", "atom" },
--        -- other triads can be put here
--    },
--    after = {
--        { "Terminal", terminal },
--        { "Log out", function() awesome.quit() end },
--        { "Sleep", "systemctl suspend" },
--        { "Restart", "systemctl reboot" },
--        { "Exit", "systemctl poweroff" },
--        -- other triads can be put here
--    }
--})
--menubar.utils.terminal = terminal -- Set the Menubar terminal for applications that require it

local soundDir = "/opt/dtos-sounds/" -- The directory that has the sound files

local startupSound  = soundDir .. "startup-01.mp3"
local shutdownSound = soundDir .. "shutdown-01.mp3"
local dmenuSound    = soundDir .. "menu-01.mp3"

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)
-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)

root.buttons(my_table.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

globalkeys = my_table.join(

    -- {{{ Personal keybindings

    -- Awesome keybindings
    awful.key({ modkey,         }, "Return", function () awful.spawn.with_shell( "~/.local/bin/my_scripts/term_wd.sh "..terminal ) end,
              {description = "Launch terminal wd", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "Return", function () awful.spawn( terminal ) end,
              {description = "Launch terminal", group = "awesome"}),
    awful.key({ modkey, ctrlkey }, "Return", function () awful.spawn.with_shell( "~/.local/bin/my_scripts/term_wd.sh urxvt" ) end,
              {description = "Launch terminal", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "r", awesome.restart,
              {description = "Reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "q",   awesome.quit,
              {description = "Quit awesome", group = "awesome"}),
    awful.key({ }, "F1",      hotkeys_popup.show_help,
        {description = "Show help", group="awesome"}),
    awful.key({ modkey, "Shift" }, "w", function () awful.spawn( browser ) end,
              {description = "Launch firefox", group = "awesome"}),
    -- awful.key({ modkey, ctrlkey }, "w", function () awful.util.mymainmenu:show() end,
    --     {description = "Show main menu", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "p", function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
                if s.mybottomwibox then
                    s.mybottomwibox.visible = not s.mybottomwibox.visible
                end
            end
        end,
        {description = "Show/hide wibox (bar)", group = "awesome"}),

    -- Run launcher
    awful.key({ modkey },            "a",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/tmux_attach.sh "..terminal)  end,
              {description = "run tmux", group = "launcher"}),

    awful.key({ modkey },            "g",     function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/nvim_fzf.sh "..terminal)   end,
              {description = "nvim_fzf", group = "launcher"}),

    awful.key({ modkey },            "d",     function ()
    awful.util.spawn("rofi -show run -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi")   end,
              {description = "run rofi", group = "launcher"}),

    awful.key({ modkey },            "c",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/term_calc.sh "..terminal)   end,
              {description = "calculator", group = "launcher"}),

    awful.key({ modkey, "Shift" },            "c",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/code_helper.sh new "..terminal)   end,
              {description = "code launcher", group = "launcher"}),

    awful.key({ modkey, "Control" },            "c",     function ()
    awful.util.spawn("GTK_THEME=Adwaita:dark gnome-calendar")   end,
              {description = "calendar", group = "launcher"}),

    awful.key({ modkey, "Shift" },            "d",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/code_helper.sh old "..terminal)   end,
              {description = "code launcher", group = "launcher"}),

    awful.key({ modkey },            "r",     function ()
    awful.util.spawn("dmenu_run -fn 'Linux Libertine Mono'")    end,
              {description = "run dmenu", group = "launcher"}),

    awful.key({ modkey },            "w",     function ()
    awful.util.spawn(terminal.. " -e sh ranger")    end,
              {description = "run ranger", group = "launcher"}),

    awful.key({ modkey },            "e",        function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/ranger_wd.sh "..terminal )   end,
              {description = "run ranger in wd", group = "launcher"}),

    awful.key({ modkey, "Shift"     },            "e",        function ()
    awful.util.spawn("sh /home/jonas/.local/bin/my_scripts/sysmenu_awsm.sh")  end,
              {description = "Run sysmenu", group = "launcher"}),

    awful.key({ modkey, "Shift"     },            "s",        function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/win_screenshot_awsm.sh")    end,
              {description = "Screenshot to cb", group = "launcher"}),

    awful.key({ modkey, "Control"     },            "s",        function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/tesseract_ocr.sh")    end,
              {description = "Screenshot ocr", group = "launcher"}),

	-- Lock screen 
    awful.key({ modkey, "Shift"    },            "x",     function ()
    awful.spawn("i3lock")     end,
              {description = "i3lock", group = "launcher"}),

    awful.key({ modkey, "Control"     },            "x",        function ()
    awful.spawn("i3lock -i /home/jonas/Downloads/lock-wallpaper.png")  end,
              {description = "i3lock pic", group = "launcher"}),
	-- Suspend 
    awful.key({ modkey, "Shift"    },            "comma",     function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/suspend_awsm.sh")   end,
              {description = "Suspend", group = "launcher"}),

    awful.key({ modkey, "Shift"    },            "period",     function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/suspend_awsm_lock.sh")    end,
              {description = "Suspend", group = "launcher"}),

	-- Nice things
    awful.key({modkey},            "v",        function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/clip_history.sh")   end,
              {description = "clip_history", group = "launcher"}),

    awful.key({modkey},            "period",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/emojipick/emojipick")   end,
              {description = "Emojipick", group = "launcher"}),

	-- Program shortcuts
    awful.key({modkey},            "b",     function ()
    awful.util.spawn(terminal.. " -e sudo htop")    end,
              {description = "Htop", group = "launcher"}),

    awful.key({ modkey, "Shift"    },            "b",     function ()
    awful.util.spawn(terminal.. " -e sudo bashtop") end,
              {description = "Bashtop", group = "launcher"}),

    awful.key({ modkey, "Control"    },            "b",     function ()
    awful.util.spawn(terminal.. " -e sudo ytop")    end,
              {description = "Ytop", group = "launcher"}),

    awful.key({ modkey },            "n",     function ()
    awful.util.spawn("sh /home/jonas/.local/bin/my_scripts/nautilus_wd.sh")     end,
              {description = "run file manager in wd", group = "launcher"}),

    awful.key({ modkey, "Shift"    },            "n",     function ()
    awful.util.spawn("thunar")  end,
              {description = "run thunar", group = "launcher"}),

    awful.key({ modkey, "Control"    },            "n",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/open_notes.sh 1 "..terminal)    end,
              {description = "Ytop", group = "launcher"}),

    awful.key({modkey},            "m",     function ()
    awful.util.spawn("nm-connection-editor")  end,
              {description = "Network connections", group = "launcher"}),

    awful.key({ modkey, "Shift"    },            "m",     function ()
    awful.util.spawn("spotify")      end,
              {description = "Spotify", group = "launcher"}),

    awful.key({ modkey, "Control"    },            "m",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/open_notes.sh 2 "..terminal)   end,
              {description = "Ytop", group = "launcher"}),

    awful.key({modkey},            "p",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/xrandr_helper.sh")  end,
              {description = "Xrandr", group = "launcher"}),

    awful.key({modkey},            "t",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/script_copy.sh")  end,
              {description = "Script_copy", group = "launcher"}),

    awful.key({ modkey, "Shift"    },           "t",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/script_helper.sh "..terminal)      end,
              {description = "Script_helper", group = "launcher"}),

    awful.key({modkey },            "section",     function ()
    awful.util.spawn("sh /home/jonas/.local/bin/my_scripts/loadEww.sh")  end,
              {description = "Load Eww", group = "launcher"}),

    awful.key({modkey, "Shift" }, 'section', function() _G.dashboard_show() end,
              {description = 'toggle dashboard', group = 'awesome'}),

    awful.key({ "Shift" },            "F1",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/show_keys.sh vim "..terminal)   end,
              {description = "vim keybinds", group = "launcher"}),

	-- Print
    awful.key({ },  "Print",     function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/screenshot_select.sh")   end,
              {description = "Screenshot", group = "launcher"}),

    awful.key({ "Shift"  },  "Print",     function ()
    awful.spawn("sh /home/jonas/.local/bin/my_scripts/screenshot.sh")  end,
              {description = "Screenshot", group = "launcher"}),

    awful.key({ "Control" },  "Print",     function ()
    awful.spawn("/home/jonas/.local/bin/my_scripts/screenshot_ocr.sh")  end,
              {description = "Screenshot", group = "launcher"}),

    -- Tag browsing with modkey
    awful.key({ modkey,         }, "Left",   awful.tag.viewprev,
        {description = "view previous", group = "tag"}),
    awful.key({ modkey,         }, "Right",  awful.tag.viewnext,
        {description = "view next", group = "tag"}),
    -- awful.key({ altkey,         }, "Escape", awful.tag.history.restore,
    --     {description = "go back", group = "tag"}),

     -- Tag browsing ALT+TAB (ALT+SHIFT+TAB)
    awful.key({ altkey,         }, "Tab", awful.tag.viewnext,
        {description = "view next", group = "tag"}),
    awful.key({ altkey, "Shift" }, "Tab", awful.tag.viewprev,
        {description = "view previous", group = "tag"}),

    -- Non-empty tag browsing CTRL+TAB (CTRL+SHIFT+TAB)
    -- awful.key({ ctrlkey }, "Tab", function () lain.util.tag_view_nonempty(-1) end,
    --           {description = "view  previous nonempty", group = "tag"}),
    -- awful.key({ ctrlkey, "Shift" }, "Tab", function () lain.util.tag_view_nonempty(1) end,
    --           {description = "view  previous nonempty", group = "tag"}),

    -- Default client focus
    awful.key({ modkey,         }, "j", function () awful.client.focus.byidx( 1) end,
        {description = "Focus next by index", group = "client"}),
    awful.key({ modkey,         }, "k", function () awful.client.focus.byidx(-1) end,
        {description = "Focus previous by index", group = "client"}),

    -- By direction client focus
    awful.key({ altkey, "Shift" }, "j", function() awful.client.focus.global_bydirection("down")
        if client.focus then client.focus:raise() end end,
        {description = "Focus down", group = "client"}),
    awful.key({ altkey, "Shift" }, "k", function() awful.client.focus.global_bydirection("up")
        if client.focus then client.focus:raise() end end,
        {description = "Focus up", group = "client"}),
    awful.key({ altkey, "Shift" }, "h", function() awful.client.focus.global_bydirection("left")
        if client.focus then client.focus:raise() end end,
        {description = "Focus left", group = "client"}),
    awful.key({ altkey, "Shift" }, "l", function() awful.client.focus.global_bydirection("right")
        if client.focus then client.focus:raise() end end,
        {description = "Focus right", group = "client"}),

        -- By direction client focus with arrows
    awful.key({ ctrlkey, modkey }, "Down", function() awful.client.focus.global_bydirection("down")
        if client.focus then client.focus:raise() end end,
        {description = "Focus down", group = "client"}),
    awful.key({ ctrlkey, modkey }, "Up", function() awful.client.focus.global_bydirection("up")
        if client.focus then client.focus:raise() end end,
        {description = "Focus up", group = "client"}),
    awful.key({ ctrlkey, modkey }, "Left", function() awful.client.focus.global_bydirection("left")
        if client.focus then client.focus:raise() end end,
        {description = "Focus left", group = "client"}),
    awful.key({ ctrlkey, modkey }, "Right", function() awful.client.focus.global_bydirection("right")
        if client.focus then client.focus:raise() end end,
        {description = "Focus right", group = "client"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "j", function () awful.client.swap.byidx(1) end,
        {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift" }, "k", function () awful.client.swap.byidx( -1) end,
        {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey          }, "l", function () awful.screen.focus_relative(1) end,
        {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey          }, "h", function () awful.screen.focus_relative(-1) end,
        {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,         }, "u", awful.client.urgent.jumpto,
        {description = "jump to urgent client", group = "client"}),
    -- awful.key({ ctrlkey,        }, "Tab", function () awful.client.focus.history.previous()
    --     if client.focus then client.focus:raise() end end,
    --     {description = "go back", group = "client"}),

    -- On the fly useless gaps change
    awful.key({ modkey }, "+", function () lain.util.useless_gaps_resize(1) end,
        {description = "increment useless gaps", group = "tag"}),
    awful.key({ modkey }, "-", function () lain.util.useless_gaps_resize(-1) end,
        {description = "decrement useless gaps", group = "tag"}),
    awful.key({ modkey }, "z", function () lain.util.useless_gaps_resize(-8) end,
        {description = "No gaps", group = "tag"}),
    awful.key({ modkey }, "x", function () lain.util.useless_gaps_resize(8) end,
        {description = "Default gaps", group = "tag"}),

    awful.key({ modkey }, "o", function () awful.tag.incmwfact( 0.05) end,
        {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey }, "y", function () awful.tag.incmwfact(-0.05) end,
        {description = "decrease master width factor", group = "layout"}),

    -- Dynamic tagging
    -- awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
    --     {description = "add new tag", group = "tag"}),
    -- awful.key({ modkey, ctrlkey }, "r", function () lain.util.rename_tag() end,
    --     {description = "rename tag", group = "tag"}),
    -- awful.key({ modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end,
    --     {description = "move tag to the left", group = "tag"}),
    -- awful.key({ modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end,
    --     {description = "move tag to the right", group = "tag"}),
    -- awful.key({ modkey, "Shift" }, "d", function () lain.util.delete_tag() end,
    --     {description = "delete tag", group = "tag"}),

    -- awful.key({ modkey, "Shift" }, "l", function () awful.tag.incmwfact( 0.05) end,
    --     {description = "increase master width factor", group = "layout"}),
    -- awful.key({ modkey, "Shift" }, "h", function () awful.tag.incmwfact(-0.05) end,
    --     {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift" }, "Up", function () awful.tag.incnmaster( 1, nil, true) end,
        {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift" }, "Down", function () awful.tag.incnmaster(-1, nil, true) end,
        {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, ctrlkey }, "h", function () awful.tag.incncol( 1, nil, true) end,
        {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, ctrlkey }, "l", function () awful.tag.incncol(-1, nil, true) end,
        {description = "decrease the number of columns", group = "layout"}),
    -- awful.key({ modkey,         }, "Tab", function () awful.layout.inc( 1) end,
    --     {description = "select next", group = "layout"}),
    -- awful.key({ modkey, "Shift" }, "Tab", function () awful.layout.inc(-1) end,
    --     {description = "select previous", group = "layout"}),

    -- awful.key({ modkey, ctrlkey }, "n",
    --           function ()
    --               local c = awful.client.restore()
    --               -- Focus restored client
    --               if c then
    --                   client.focus = c
    --                   c:raise()
    --               end
    --           end,
    --           {description = "restore minimized", group = "client"}),

    -- Dropdown application
    awful.key({ modkey, }, "F12", function () awful.screen.focused().quake:toggle() end,
              {description = "dropdown application", group = "super"}),

    -- Widgets popups
    -- awful.key({ modkey, altkey, }, "c", function () lain.widget.cal.show(7) end,
    --     {description = "show calendar", group = "widgets"}),
    -- awful.key({ altkey, }, "h", function () if beautiful.fs then beautiful.fs.show(7) end end,
    --     {description = "show filesystem", group = "widgets"}),
    -- awful.key({ altkey, }, "w", function () if beautiful.weather then beautiful.weather.show(7) end end,
    --     {description = "show weather", group = "widgets"}),

    -- Brightness
    awful.key({ }, "XF86MonBrightnessUp", function () os.execute("xbacklight -inc 10") end,
        {description = "+10%", group = "hotkeys"}),
    awful.key({ }, "XF86MonBrightnessDown", function () os.execute("xbacklight -dec 10") end,
        {description = "-10%", group = "hotkeys"}),

    -- ALSA volume control
    --awful.key({ ctrlkey }, "Up",
    awful.key({ }, "XF86AudioRaiseVolume",
        function ()
            os.execute(string.format("amixer -q set %s 1%%+", beautiful.volume.channel))
            beautiful.volume.update()
        end),
    --awful.key({ ctrlkey }, "Down",
    awful.key({ }, "XF86AudioLowerVolume",
        function ()
            os.execute(string.format("amixer -q set %s 1%%-", beautiful.volume.channel))
            beautiful.volume.update()
        end),
    awful.key({ }, "XF86AudioMute",
        function ()
            os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
            beautiful.volume.update()
        end)

    -- Copy primary to clipboard (terminals to gtk)
    -- awful.key({ modkey }, "c", function () awful.spawn.with_shell("xsel | xsel -i -b") end,
    --     {description = "copy terminal to gtk", group = "hotkeys"}),
    -- Copy clipboard to primary (gtk to terminals)
    -- awful.key({ modkey }, "v", function () awful.spawn.with_shell("xsel -b | xsel") end,
    --     {description = "copy gtk to terminal", group = "hotkeys"}),
    -- awful.key({ altkey, "Shift" }, "x",
    --           function ()
    --               awful.prompt.run {
    --                 prompt       = "Run Lua code: ",
    --                 textbox      = awful.screen.focused().mypromptbox.widget,
    --                 exe_callback = awful.util.eval,
    --                 history_path = awful.util.get_cache_dir() .. "/history_eval"
    --               }
    --           end,
    --           {description = "lua execute prompt", group = "awesome"})
    --]]
)

clientkeys = my_table.join(
    -- awful.key({ altkey, "Shift" }, "m",      lain.util.magnify_client,
    --           {description = "magnify client", group = "client"}),
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey }, "q", function (c) c:kill() end,
      {description = "close", group = "hotkeys"}),
    awful.key({ modkey,         }, "space", awful.client.floating.toggle,
      {description = "toggle floating", group = "client"}),
    -- awful.key({ modkey, ctrlkey }, "Return", function (c) c:swap(awful.client.getmaster()) end,
    --   {description = "move to master", group = "client"}),
    -- awful.key({ modkey, "Shift" }, "t", function (c) c.ontop = not c.ontop end,
    --   {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey, "Shift"}, "l",
        function ()
            local c = client.focus
            if c then c:move_to_screen() end
        end, {description = "move client to next screen", group = "client"}),
    awful.key({ modkey, "Shift"}, "h",
        function ()
            local c = client.focus
            if c then c:move_to_screen(c.screen.index-1) end
        end, {description = "move client to prev screen", group = "client"})

    -- awful.key({ modkey,         }, "n",
    --     function (c)
    --         -- The client currently has the input focus, so it cannot be
    --         -- minimized, since minimized clients can't have the focus.
    --         c.minimized = true
    --     end ,
    -- {description = "minimize", group = "client"}),

    -- awful.key({ modkey,           }, "m",
    --     function (c)
    --         c.maximized = not c.maximized
    --         c:raise()
    --     end ,
    -- {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = "view tag #", group = "tag"}
        descr_toggle = {description = "toggle tag #", group = "tag"}
        descr_move = {description = "move focused client to tag #", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #", group = "tag"}
    end
    globalkeys = my_table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  descr_view),

        -- Toggle tag display.
        -- awful.key({ modkey, ctrlkey }, "#" .. i + 9,
        --           function ()
        --               local screen = awful.screen.focused()
        --               local tag = screen.tags[i]
        --               if tag then
        --                  awful.tag.viewtoggle(tag)
        --               end
        --           end,
        --           descr_toggle),

            -- Move client to tag and view.
            awful.key({ modkey, "Shift" }, "#" .. i + 9,
                function ()
                    if client.focus then
                        local tag = client.focus.screen.tags[i]
                        if tag then
                            client.focus:move_to_tag(tag)
                            local screen = awful.screen.focused()
                            local tag2 = screen.tags[i]
                            tag2:view_only()
                        end
                    end
                end,
                { description = "move focused client to tag #"..i, group = "tag" }
            ),

        -- Move client to tag.
        awful.key({ modkey, ctrlkey }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  descr_move),

        -- Toggle tag on focused client.
        awful.key({ modkey, ctrlkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  descr_toggle_focus)
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Titlebars
    { rule_any = { type = { "dialog", "normal" } },
      properties = { titlebars_enabled = false } },

    -- Set applications to always map on the tag 1 on screen 1.
    -- find class or role via xprop command
    --{ rule = { class = browser1 },
      --properties = { screen = 1, tag = awful.util.tagnames[1] } },

    --{ rule = { class = editorgui },
        --properties = { screen = 1, tag = awful.util.tagnames[2] } },

    --{ rule = { class = "Geany" },
        --properties = { screen = 1, tag = awful.util.tagnames[2] } },

    -- Set applications to always map on the tag 3 on screen 1.
    --{ rule = { class = "Inkscape" },
        --properties = { screen = 1, tag = awful.util.tagnames[3] } },

    -- Set applications to always map on the tag 4 on screen 1.
    --{ rule = { class = "Gimp" },
        --properties = { screen = 1, tag = awful.util.tagnames[4] } },

    -- Set applications to be maximized at startup.
    -- find class or role via xprop command

    -- { rule = { class = "Gimp*", role = "gimp-image-window" },
    --       properties = { maximized = true } },

    -- { rule = { class = "inkscape" },
    --       properties = { maximized = true } },

    -- { rule = { class = mediaplayer },
    --       properties = { maximized = true } },

    -- { rule = { class = "Vlc" },
    --       properties = { maximized = true } },

    -- { rule = { class = "VirtualBox Manager" },
    --       properties = { maximized = true } },

    -- { rule = { class = "VirtualBox Machine" },
    --       properties = { maximized = true } },

    -- { rule = { class = "Xfce4-settings-manager" },
    --       properties = { floating = false } },


    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Blueberry",
          "Galculator",
          "Gnome-font-viewer",
          "Gpick",
          "Imagewriter",
          "Font-manager",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Oblogout",
          "Peek",
          "Skype",
          "System-config-printer.py",
          "Sxiv",
          "Unetbootin.elf",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
          "Preferences",
          "setup",
        }
      }, properties = { floating = true }},

}

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = my_table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = 21}) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = true})
end)

-- No border for maximized clients
function border_adjust(c)
    if c.maximized then -- no borders if only 1 client visible
        c.border_width = 0
    elseif #awful.screen.focused().clients > 1 then
        c.border_width = beautiful.border_width
        c.border_color = beautiful.border_focus
    end
end

client.connect_signal("focus", border_adjust)
client.connect_signal("property::maximized", border_adjust)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- awful.spawn.with_shell(soundplayer .. startupSound)
-- awful.spawn.with_shell("lxsession")
awful.spawn.with_shell("picom")
awful.spawn.with_shell("diodon")
-- awful.spawn.with_shell("nm-applet")
-- awful.spawn.with_shell("volumeicon")
-- awful.spawn.with_shell("sleep 2 && conky -c $HOME/.config/conky/awesome/" .. "doom-one" .. "-01.conkyrc")
-- awful.spawn.with_shell("/usr/bin/emacs --daemon")
-- awful.spawn.with_shell("xargs xwallpaper --stretch < ~/.cache/wall")
-- awful.spawn.with_shell("feh --bg-fill --randomize ~/Pictures/Wallpapers/*")
--awful.spawn.with_shell("feh --randomize --bg-fill /usr/share/backgrounds/dtos-backgrounds/*") -- feh sets random wallpaper
--awful.spawn.with_shell("nitrogen --restore") -- if you prefer nitrogen to feh/xwallpaper
