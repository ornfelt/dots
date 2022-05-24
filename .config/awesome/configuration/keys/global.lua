local awful = require('awful')
require('awful.autofocus')
local beautiful = require('beautiful')
local hotkeys_popup = require('awful.hotkeys_popup').widget

local modkey = require('configuration.keys.mod').modKey
local altkey = require('configuration.keys.mod').altKey
local apps = require('configuration.apps')

function poweroff_command()
    awful.spawn.with_shell('poweroff')
    awful.keygrabber.stop(_G.exit_screen_grabber)
end

-- Key bindings
local globalKeys = awful.util.table.join( -- Hotkeys
awful.key({modkey}, 'F1', hotkeys_popup.show_help,
          {description = 'show help', group = 'awesome'}), -- Tag browsing
awful.key({modkey}, 'w', awful.tag.viewprev,
          {description = 'view previous', group = 'tag'}),
awful.key({modkey}, 's', awful.tag.viewnext,
          {description = 'view next', group = 'tag'}),
awful.key({altkey, 'Control'}, 'Left', awful.tag.viewprev,
          {description = 'view previous', group = 'tag'}),
awful.key({altkey, 'Control'}, 'Right', awful.tag.viewnext,
          {description = 'view next', group = 'tag'}),
awful.key({modkey}, 'Escape', awful.tag.history.restore,
          {description = 'go back', group = 'tag'}), -- Default client focus
awful.key({modkey}, 'd', function() awful.client.focus.byidx(1) end,
          {description = 'focus next by index', group = 'client'}),
awful.key({modkey}, 'a', function() awful.client.focus.byidx(-1) end,
          {description = 'focus previous by index', group = 'client'}),
awful.key({modkey}, 'r', function() _G.awesome.spawn(apps.default.rofi) end,
          {description = 'show rofi menu', group = 'awesome'}),
awful.key({modkey}, 'd', function()
    local flag = false
    for _, c in ipairs(mouse.screen.selected_tag:clients()) do
        if c.minimized == true then flag = true end
        c.minimized = true
    end
    for _, c in ipairs(mouse.screen.selected_tag:clients()) do
        if flag == true then c.minimized = false end
    end
end, {description = 'minimize all clients', group = 'awesome'}),
awful.key({modkey}, 'u', awful.client.urgent.jumpto,
          {description = 'jump to urgent client', group = 'client'}),
awful.key({altkey}, 'Tab', function()
    -- awful.client.focus.history.previous()
    awful.client.focus.byidx(1)
    if _G.client.focus then _G.client.focus:raise() end
end, {description = 'Switch to next window', group = 'client'}),
awful.key({altkey, 'Shift'}, 'Tab', function()
    -- awful.client.focus.history.previous()
    awful.client.focus.byidx(-1)
    if _G.client.focus then _G.client.focus:raise() end
end, {description = 'Switch to previous window', group = 'client'}),
-- Programms
awful.key({modkey}, 'l', function() awful.spawn(apps.default.lock) end,
          {description = 'Lock the screen', group = 'awesome'}),
awful.key({'Control', 'Shift'}, 'Print', function()
    awful.util.spawn_with_shell(apps.default.delayed_screenshot)
end, {
    description = 'Mark an area and screenshot it (clipboard)',
    group = 'screenshots (clipboard)'
}), awful.key({altkey}, 'Print', function()
    awful.util.spawn_with_shell(apps.default.screenshot)
end, {
    description = 'Take a screenshot of your active monitor and copy it to clipboard',
    group = 'screenshots (clipboard)'
}), awful.key({'Control'}, 'Print', function()
    awful.util.spawn_with_shell(apps.default.region_screenshot)
end, {
    description = 'Mark an area and screenshot it to your clipboard',
    group = 'screenshots (clipboard)'
}),
awful.key({modkey}, 'c', function() awful.util.spawn(apps.default.editor) end,
          {description = 'open a text/code editor', group = 'launcher'}),
awful.key({modkey}, 'b', function() awful.util.spawn(apps.default.browser) end,
          {description = 'open a browser', group = 'launcher'}),
-- Open private browser/brave
awful.key({modkey}, 'p',
          function() awful.util.spawn_with_shell('brave-browser') end,
          {description = 'Open Brave', group = 'launcher'}),
-- Standard program
awful.key({modkey}, 't',
          function() awful.util.spawn_with_shell(apps.default.terminal) end,
          {description = 'open a terminal', group = 'launcher'}),
awful.key({modkey, 'Control'}, 'r', _G.awesome.restart,
          {description = 'reload awesome', group = 'awesome'}),
awful.key({modkey, 'Control'}, 'q', _G.awesome.quit,
          {description = 'quit awesome', group = 'awesome'}),
awful.key({modkey}, 'm', function() _G.dashboard_show() end,
          {description = 'toggle main menu', group = 'awesome'}),
awful.key({modkey, 'Shift'}, 'p', function() _G.exit_screen_show() end,
          {description = 'end session menu', group = 'awesome'}),
awful.key({altkey, 'Shift'}, 'Right', function() awful.tag.incmwfact(0.05) end,
          {description = 'increase master width factor', group = 'layout'}),
awful.key({altkey, 'Shift'}, 'Left', function() awful.tag.incmwfact(-0.05) end,
          {description = 'decrease master width factor', group = 'layout'}),
awful.key({altkey, 'Shift'}, 'Down', function() awful.client.incwfact(0.05) end,
          {description = 'decrease master height factor', group = 'layout'}),
awful.key({altkey, 'Shift'}, 'Up', function() awful.client.incwfact(-0.05) end,
          {description = 'increase master height factor', group = 'layout'}),
awful.key({modkey, 'Shift'}, 'Left',
          function() awful.tag.incnmaster(1, nil, true) end, {
    description = 'increase the number of master clients',
    group = 'layout'
}), awful.key({modkey, 'Shift'}, 'Right',
              function() awful.tag.incnmaster(-1, nil, true) end, {
    description = 'decrease the number of master clients',
    group = 'layout'
}), awful.key({modkey, 'Control'}, 'Left',
              function() awful.tag.incncol(1, nil, true) end, {
    description = 'increase the number of columns',
    group = 'layout'
}), awful.key({modkey, 'Control'}, 'Right',
              function() awful.tag.incncol(-1, nil, true) end, {
    description = 'decrease the number of columns',
    group = 'layout'
}), awful.key({modkey}, 'space', function() awful.layout.inc(1) end,
              {description = 'select next', group = 'layout'}),
awful.key({modkey, 'Shift'}, 'space', function() awful.layout.inc(-1) end,
          {description = 'select previous', group = 'layout'}),
awful.key({modkey, 'Control'}, 'n', function()
    local c = awful.client.restore()
    -- Focus restored client
    if c then
        _G.client.focus = c
        c:raise()
    end
end, {description = 'restore minimized', group = 'client'}),
-- Dropdown application
awful.key({altkey, 'Control'}, 'k', function() _G.toggle_quake() end,
          {description = 'dropdown application', group = 'launcher'}),
-- Widgets popups
--[[awful.key(
    {altkey},
    'h',
    function()
      if beautiful.fs then
        beautiful.fs.show(7)
      end
    end,
    {description = 'show filesystem', group = 'widgets'}
  ),
  awful.key(
    {altkey},
    'w',
    function()
      if beautiful.weather then
        beautiful.weather.show(7)
      end
    end,
    {description = 'show weather', group = 'widgets'}
  ),--]]
-- Brightness
awful.key({}, 'XF86MonBrightnessUp',
          function() awful.spawn('xbacklight -inc 10') end,
          {description = '+10%', group = 'hotkeys'}),
awful.key({}, 'XF86MonBrightnessDown',
          function() awful.spawn('xbacklight -dec 10') end,
          {description = '-10%', group = 'hotkeys'}), -- ALSA volume control
awful.key({}, 'XF86AudioRaiseVolume', function()
    awful.spawn.easy_async('amixer -D pulse sset Master 5%+', function() 
        _G.update_volume()
    end)
end, {description = 'volume up', group = 'hotkeys'}),
awful.key({}, 'XF86AudioLowerVolume', function()
    awful.spawn.easy_async('amixer -D pulse sset Master 5%-', function()
        _G.update_volume()
    end)
end, {description = 'volume down', group = 'hotkeys'}),
awful.key({}, 'XF86AudioMute', function()
    awful.spawn('amixer -D pulse set Master 1+ toggle')
    _G.update_volume()
end, {description = 'toggle mute', group = 'hotkeys'}),
awful.key({}, 'XF86AudioNext', function()
    --
end, {description = 'toggle mute', group = 'hotkeys'}),
awful.key({}, 'XF86PowerDown', function()
    --
end, {description = 'toggle mute', group = 'hotkeys'}),
awful.key({}, 'XF86PowerOff', function() _G.exit_screen_show() end,
          {description = 'toggle mute', group = 'hotkeys'}),
-- Screen management
awful.key({modkey}, 'o', awful.client.movetoscreen,
          {description = 'move window to next screen', group = 'client'}),
-- Open default program for tag
awful.key({modkey}, 'n', function()
    awful.spawn(awful.screen.focused().selected_tag.defaultApp, {
        tag = _G.mouse.screen.selected_tag,
        placement = awful.placement.bottom_right
    })
end, {description = 'open default program for tag/workspace', group = 'tag'}),
-- Custom hotkeys
-- vfio integration
awful.key({'Control', altkey}, 'space',
          function() awful.util.spawn_with_shell('vm-attach attach') end),
-- Emoji typing
-- setup info at https://gist.github.com/HikariKnight/8562837d28dec3674dba027c7892e6a5
awful.key({modkey}, 'e',
          function() awful.util.spawn_with_shell('emoji-toggle') end, {
    description = 'Toggle the ibus unimoji engine for writing emojis',
    group = 'hotkeys'
}))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = 'view tag #', group = 'tag'}
        descr_toggle = {description = 'toggle tag #', group = 'tag'}
        descr_move = {
            description = 'move focused client to tag #',
            group = 'tag'
        }
        descr_toggle_focus = {
            description = 'toggle focused client on tag #',
            group = 'tag'
        }
    end
    globalKeys = awful.util.table.join(globalKeys, -- View tag only.
    awful.key({modkey}, '#' .. i + 9, function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then tag:view_only() end
    end, descr_view), -- Toggle tag display.
    awful.key({modkey, 'Control'}, '#' .. i + 9, function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then awful.tag.viewtoggle(tag) end
    end, descr_toggle), -- Move client to tag.
    awful.key({modkey, 'Shift'}, '#' .. i + 9, function()
        if _G.client.focus then
            local tag = _G.client.focus.screen.tags[i]
            if tag then _G.client.focus:move_to_tag(tag) end
        end
    end, descr_move), -- Toggle tag on focused client.
    awful.key({modkey, 'Control', 'Shift'}, '#' .. i + 9, function()
        if _G.client.focus then
            local tag = _G.client.focus.screen.tags[i]
            if tag then _G.client.focus:toggle_tag(tag) end
        end
    end, descr_toggle_focus))
end

return globalKeys

