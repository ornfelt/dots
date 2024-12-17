-- See original rc.lua:
-- https://awesomewm.org/doc/api/sample%20files/rc.lua.html
-- or in:
-- /etc/xdg/awesome/rc.lua

-- {{{ Required libraries

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
--local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")
                      require("awful.hotkeys_popup.keys")
local mytable       = awful.util.table or gears.table -- 4.{0,1} compatibility

-- }}}

-- {{{ Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify {
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    }
end

-- Handle runtime errors after startup
do
    local in_error = false

    awesome.connect_signal("debug::error", function (err)
        if in_error then return end

        in_error = true

        naughty.notify {
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        }

        in_error = false
    end)
end

-- }}}

-- {{{ Autostart windowless processes

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

--run_once({ "urxvtd", "unclutter -root" }) -- comma-separated entries
run_once({ "picom", "--animations" })

-- This function implements the XDG autostart specification
--[[
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart --search-paths ' ..
    '"${XDG_CONFIG_HOME:-$HOME/.config}/autostart:${XDG_CONFIG_DIRS:-/etc/xdg}/autostart";' -- https://github.com/jceb/dex
)
--]]

-- }}}

-- {{{ Variable definitions

local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex"           -- 10
}

local chosen_theme = themes[5]
local modkey       = "Mod4"
local altkey       = "Mod1"
local ctrlkey     = "Control"
--local terminal     = "urxvtc"

local vi_focus     = false -- vi-like client focus https://github.com/lcpz/awesome-copycats/issues/275
local cycle_prev   = true  -- cycle with only the previously focused client or all https://github.com/lcpz/awesome-copycats/issues/274
local editor       = os.getenv("EDITOR") or "nvim"
--local browser      = "librewolf"
local browser      = "firefox"

local terminal    = "wezterm"
local secterminal    = "alacritty"
--local filex    = "ranger"
local filex    = "yazi"

awful.util.terminal = terminal
awful.util.tagnames = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
awful.layout.layouts = {
    awful.layout.suit.spiral,
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier,
    --awful.layout.suit.corner.nw,
    --awful.layout.suit.corner.ne,
    --awful.layout.suit.corner.sw,
    --awful.layout.suit.corner.se,
    --lain.layout.cascade,
    --lain.layout.cascade.tile,
    --lain.layout.centerwork,
    --lain.layout.centerwork.horizontal,
    --lain.layout.termfair,
    --lain.layout.termfair.center
}

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

awful.util.taglist_buttons = mytable.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = mytable.join(
     awful.button({ }, 1, function(c)
         if c == client.focus then
             c.minimized = true
         else
             c:emit_signal("request::activate", "tasklist", { raise = true })
         end
     end),
     awful.button({ }, 3, function()
         awful.menu.client_list({ theme = { width = 250 } })
     end),
     awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
     awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)

beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))

-- }}}

-- {{{ Menu

-- Create a launcher widget and a main menu
local myawesomemenu = {
   { "Hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "Manual", string.format("%s -e man awesome", terminal) },
   { "Edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
   { "Restart", awesome.restart },
   { "Quit", function() awesome.quit() end },
}

awful.util.mymainmenu = freedesktop.menu.build {
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
}

-- Hide the menu when the mouse leaves it
--[[
awful.util.mymainmenu.wibox:connect_signal("mouse::leave", function()
    if not awful.util.mymainmenu.active_child or
       (awful.util.mymainmenu.wibox ~= mouse.current_wibox and
       awful.util.mymainmenu.active_child.wibox ~= mouse.current_wibox) then
        awful.util.mymainmenu:hide()
    else
        awful.util.mymainmenu.active_child.wibox:connect_signal("mouse::leave",
        function()
            if awful.util.mymainmenu.wibox ~= mouse.current_wibox then
                awful.util.mymainmenu:hide()
            end
        end)
    end
end)
--]]

-- Set the Menubar terminal for applications that require it
--menubar.utils.terminal = terminal

-- }}}

-- {{{ Screen

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

-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function (s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if only_one and not c.floating or c.maximized or c.fullscreen then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width
        end
    end
end)

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)

-- }}}

-- {{{ Mouse bindings

root.buttons(mytable.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- }}}

-- {{{ Key bindings
globalkeys = mytable.join(
    -- {{{ Personal keybindings

    -- Awesome keybindings
    awful.key({ modkey,         }, "Return", function () awful.spawn.with_shell( "~/.local/bin/my_scripts/term_wd.sh ".. terminal) end,
              {description = "Launch terminal wd", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "Return", function () awful.spawn( terminal ) end,
              {description = "Launch terminal", group = "awesome"}),
    awful.key({ modkey, ctrlkey }, "Return", function () awful.spawn.with_shell( "~/.local/bin/my_scripts/term_wd.sh " .. secterminal ) end,
              {description = "Launch terminal", group = "awesome"}),

    awful.key({ modkey, ctrlkey }, "r", awesome.restart,
              {description = "Reload awesome", group = "awesome"}),

    awful.key({ modkey, "Shift" }, "q",   awesome.quit,
              {description = "Quit awesome", group = "awesome"}),

    awful.key({ }, "F1",      hotkeys_popup.show_help,
        {description = "Show help", group="awesome"}),

    --awful.key({ modkey, "Shift" }, "w", function () awful.spawn( browser ) end,
    --          {description = "Launch firefox", group = "awesome"}),
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

    awful.key({ modkey, ctrlkey }, "p", function() toggle_widget_visibility() end,
              { description = "toggle widgets visibility", group = "custom" }),

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
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/code_helper.sh old " .. terminal)   end,
              {description = "code launcher", group = "launcher"}),

    awful.key({ modkey },            "r",     function ()
    awful.util.spawn("dmenu_run -fn 'Linux Libertine Mono'")    end,
              {description = "run dmenu", group = "launcher"}),

    awful.key({ modkey },            "w",     function ()
    awful.util.spawn(terminal.. " -e " .. filex .. " ~/")    end,
              {description = "run ranger", group = "launcher"}),

    awful.key({ modkey },            "e",        function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/file_explorer_wd.sh " .. terminal .. " " .. filex )   end,
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
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/clip_history.sh greenclip")   end,
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
    awful.util.spawn(terminal .. " -e sudo ytop")    end,
              {description = "Ytop", group = "launcher"}),

    awful.key({ modkey },            "n",     function ()
    awful.util.spawn("/home/jonas/.local/bin/my_scripts/files_wd.sh")     end,
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
    --awful.key({ altkey,         }, "Tab", awful.tag.viewnext,
    --    {description = "view next", group = "tag"}),
    --awful.key({ altkey, "Shift" }, "Tab", awful.tag.viewprev,
    --    {description = "view previous", group = "tag"}),

    -- Non-empty tag browsing CTRL+TAB (CTRL+SHIFT+TAB)
     awful.key({ altkey }, "Tab", function () lain.util.tag_view_nonempty(-1) end,
               {description = "view  previous nonempty", group = "tag"}),
     awful.key({ altkey, "Shift" }, "Tab", function () lain.util.tag_view_nonempty(1) end,
               {description = "view  previous nonempty", group = "tag"}),

    -- Default client focus
    awful.key({ modkey,         }, "j", function () awful.client.focus.byidx( 1) end,
        {description = "Focus next by index", group = "client"}),
    awful.key({ modkey,         }, "k", function () awful.client.focus.byidx(-1) end,
        {description = "Focus previous by index", group = "client"}),

    -- By direction client focus
    --awful.key({ altkey, "Shift" }, "j", function() awful.client.focus.global_bydirection("down")
    --    if client.focus then client.focus:raise() end end,
    --    {description = "Focus down", group = "client"}),
    --awful.key({ altkey, "Shift" }, "k", function() awful.client.focus.global_bydirection("up")
    --    if client.focus then client.focus:raise() end end,
    --    {description = "Focus up", group = "client"}),
    --awful.key({ altkey, "Shift" }, "h", function() awful.client.focus.global_bydirection("left")
    --    if client.focus then client.focus:raise() end end,
    --    {description = "Focus left", group = "client"}),
    --awful.key({ altkey, "Shift" }, "l", function() awful.client.focus.global_bydirection("right")
    --    if client.focus then client.focus:raise() end end,
    --    {description = "Focus right", group = "client"}),

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

    awful.key({ modkey, "Shift" }, "a", function() awful.spawn("picom-trans -c -5") end,
        {description = "decrease transparency", group = "custom"}),

    awful.key({ modkey, "Control" }, "a", function() awful.spawn("picom-trans -c +5") end,
        {description = "increase transparency", group = "custom"}),

    -- Dynamic tagging
    -- awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
    --     {description = "add new tag", group = "tag"}),
    -- awful.key({ modkey, "Shift" }, "r", function () lain.util.rename_tag() end,
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
    -- awful.key({ modkey, "Shift" }, "Up", function () awful.tag.incnmaster( 1, nil, true) end,
    --     {description = "increase the number of master clients", group = "layout"}),
    -- awful.key({ modkey, "Shift" }, "Down", function () awful.tag.incnmaster(-1, nil, true) end,
    --     {description = "decrease the number of master clients", group = "layout"}),
    -- awful.key({ modkey, ctrlkey }, "h", function () awful.tag.incncol( 1, nil, true) end,
    --     {description = "increase the number of columns", group = "layout"}),
    -- awful.key({ modkey, ctrlkey }, "l", function () awful.tag.incncol(-1, nil, true) end,
    --     {description = "decrease the number of columns", group = "layout"}),
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

clientkeys = mytable.join(
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

    --awful.key({ modkey,         }, "space", awful.client.floating.toggle,
    --  {description = "toggle floating", group = "client"}),

    awful.key(
      { modkey }, "space",
      function(c)
        awful.client.floating.toggle(c)

        -- If the client is now floating, center it
        if c.floating then
          awful.placement.centered(c, {honor_workarea = true})
        end
      end,
      {description = "toggle floating and center", group = "client"}
    ),

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
        end, {description = "move client to prev screen", group = "client"}),

    -- awful.key({ modkey,         }, "n",
    --     function (c)
    --         -- The client currently has the input focus, so it cannot be
    --         -- minimized, since minimized clients can't have the focus.
    --         c.minimized = true
    --     end ,
    -- {description = "minimize", group = "client"}),

     awful.key({ modkey, "Shift", ctrlkey           }, "m",
         function (c)
             c.maximized = not c.maximized
             c:raise()
         end ,
     {description = "maximize", group = "client"})
)

-- Toggleable Tag Switching
local last_tag = {}

local function toggle_tag(tag)
    local screen = awful.screen.focused()
    if screen.selected_tag == tag then
        if last_tag[screen] then
            last_tag[screen]:view_only()
        end
    else
        last_tag[screen] = screen.selected_tag
        tag:view_only()
    end
end

local binary_mask = 341

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = mytable.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                      local num_screens = screen:count()
                      if num_screens == 2 then
                          -- Determine the screen and tag based on binary mask and tag index
                          for s in awful.screen do
                              if s.index == 1 and (binary_mask & (1 << (i - 1))) ~= 0 then
                                  awful.screen.focus(s.index)
                                  local tag = s.tags[i]
                                  toggle_tag(tag)
                              elseif s.index == 2 and (binary_mask & (1 << (i - 1))) == 0 then
                                  awful.screen.focus(s.index)
                                  local tag = s.tags[i]
                                  toggle_tag(tag)
                              end
                          end
                      else
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           --tag:view_only()
                           toggle_tag(tag)
                        end
                      end
                  end,
                  {description = "view tag #"..i.." on appropriate monitor", group = "tag"}),

        -- Toggle tag display.
        --awful.key({ modkey, "Control" }, "#" .. i + 9,
        --          function ()
        --              local screen = awful.screen.focused()
        --              local tag = screen.tags[i]
        --              if tag then
        --                 awful.tag.viewtoggle(tag)
        --              end
        --          end,
        --          {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag and view it.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                              toggle_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = mytable.join(
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

-- }}}

-- {{{ Rules

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    {
        rule = { class = "firefox" },
        properties = {
            --maximized = false, -- Ensure Firefox is not always maximized
            floating = false,  -- Ensure it respects tiled layouts
            tag = "2",
        },
    },
    {
        rule = { class = "thunar" },
        properties = {
            maximized = false,
            floating = false,
        },
    },

    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     callback = awful.client.setslave,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Floating clients.
  --{
  --  rule_any = {
  --    instance = {
  --      "DTA", -- Firefox addon DownThemAll.
  --      "copyq", -- Includes session name in class.
  --      "pinentry",
  --    },
  --    class = {
  --      "Arandr",
  --      "Blueman-manager",
  --      "Gpick",
  --      "Kruler",
  --      "MessageWin", -- kalarm.
  --      "Sxiv",
  --      "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
  --      "Wpa_gui",
  --      "veromix",
  --      "xtightvncviewer"},
  --
  --    -- Note that the name property shown in xprop might be set slightly after creation of the client
  --    -- and the name shown there might not match defined rules here.
  --    name = {
  --      "Event Tester",  -- xev.
  --    },
  --    role = {
  --      "AlarmWindow",  -- Thunderbird's calendar.
  --      "ConfigManager",  -- Thunderbird's about:config.
  --      "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
  --    }
  --  }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}

-- }}}

-- {{{ Signals

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
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
    local buttons = mytable.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, { size = 16 }) : setup {
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

-- Enable sloppy focus, so that focus follows mouse.
--client.connect_signal("mouse::enter", function(c)
--    c:emit_signal("request::activate", "mouse_enter", {raise = vi_focus})
--end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- switch to parent after closing child window
local function backham()
    local s = awful.screen.focused()
    local c = awful.client.focus.history.get(s, 0)
    if c then
        client.focus = c
        c:raise()
    end
end

-- attach to minimized state
client.connect_signal("property::minimized", backham)
-- attach to closed state
client.connect_signal("unmanage", backham)
-- ensure there is always a selected client during tag switching or logins
tag.connect_signal("property::selected", backham)

-- }}}

for s in screen do
    s:connect_signal("arrange", function(scr)
        local clients = scr.clients
        local firefox_clients = {}
        
        -- Collect all Firefox clients
        for _, c in ipairs(clients) do
            if c.class == "firefox" then
                table.insert(firefox_clients, c)
            end
        end

        -- If there's only one client on the screen and it's Firefox, maximize it.
        -- Otherwise, if there are multiple clients, ensure Firefox is not maximized.
        if #clients == 1 and #firefox_clients == 1 then
            firefox_clients[1].maximized = true
        else
            for _, fc in ipairs(firefox_clients) do
                fc.maximized = false
            end
        end
    end)
end

-- Multiple monitor taglist setup
-- See: {code_root_dir}/Code2/Lua/my_lua/testing/awsm_tag_testing.lua

local function setup_tags_for_monitors()
    local num_screens = screen.count()

    for s in screen do
        s.tags = {}

        if num_screens == 2 then
            for i = 1, 9 do
                if s.index == 1 and (binary_mask & (1 << (i - 1))) ~= 0 then
                  awful.tag.add(i, { screen = s, layout = awful.layout.suit.spiral })
                elseif s.index == 2 and (binary_mask & (1 << (i - 1))) == 0 then
                  awful.tag.add(i, { screen = s, layout = awful.layout.suit.spiral })
                end
            end
        else
            -- Cyclical tag distribution for 3 or more monitors
            for i = 1, 9 do
                -- Assign tag `i` to the monitor `((i - 1) % num_screens) + 1`
                local target_screen = ((i - 1) % num_screens) + 1
                if s.index == target_screen then
                    awful.tag.add(i, {
                        screen = s,
                        layout = awful.layout.suit.spiral,
                    })
                end
            end
        end
    end
end

local function move_clients_cyclically()
    local screens = screen:count()
    if screens < 3 then return end

    -- Move clients cyclically across all monitors based on tag index
    for _, c in ipairs(client.get()) do
        local tags = c:tags()
        for _, tag in ipairs(tags) do
            local tag_index = tonumber(tag.name)
            if tag_index then
                local target_screen_index = ((tag_index - 1) % screens) + 1
                local target_screen = screen[target_screen_index]

                if target_screen and c.screen ~= target_screen then
                    c:move_to_screen(target_screen)
                end

                --tag:view_only()
                break
            end
        end
    end
end

local EVEN_TAG_MASK = 170

local function move_even_tag_clients()
    local screens = screen:count()
    if screens ~= 2 then return end

    local primary_screen = screen[1]
    local secondary_screen = screen[2]

    for _, c in ipairs(client.get()) do
        local tags = c:tags()
        for _, tag in ipairs(tags) do
            local tag_index = tonumber(tag.name)
            if tag_index and (EVEN_TAG_MASK & (1 << (tag_index - 1))) ~= 0 then
                c:move_to_screen(secondary_screen)
                --tag:view_only()
                break
            end
        end
    end
end

--awful.screen.connect_for_each_screen(function(s)
--    if screen:count() == 2 then
--        move_even_tag_clients()
--    end
--end)

screen.connect_signal("added", function()
    setup_tags_for_monitors()
    -- One monitor case is handled automatically?
    move_even_tag_clients()
    move_clients_cyclically()
end)

screen.connect_signal("removed", function()
    setup_tags_for_monitors()
end)

setup_tags_for_monitors()

