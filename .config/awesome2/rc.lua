local gears = require('gears')
local awful = require('awful')
require('awful.autofocus')
local beautiful = require('beautiful')

-- Theme
beautiful.init(require('theme'))

-- Layout
require('layout')

-- Init all modules
require('module.notifications')
require('module.auto-start')
require('module.decorate-client')
-- require('module.quake-terminal')
-- Backdrop causes bugs on some gtk3 applications
-- require('module.backdrop')
-- require('module.exit-screen')
require('module.dashboard')

-- Setup all configurations
-- require('configuration.client')
-- require('configuration.tags')
-- _G.root.keys(require('configuration.keys.global'))

-- NEW Setup all configs...
local modkey = 'Mod4'
local altkey = 'Mod1'

local clientKeys =
  awful.util.table.join(
  awful.key(
    {modkey},
    'f',
    function(c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    {description = 'toggle fullscreen', group = 'client'}
  ),
  awful.key(
    {modkey},
    'q',
    function(c)
      c:kill()
    end,
    {description = 'close', group = 'client'}
  )
)

-- return clientKeys

return awful.util.table.join(
  awful.button(
    {},
    1,
    function(c)
      _G.client.focus = c
      c:raise()
    end
  ),
  awful.button({modkey}, 1, awful.mouse.client.move),
  awful.button({modkey}, 3, awful.mouse.client.resize),
  awful.button(
    {modkey},
    4,
    function()
      awful.layout.inc(1)
    end
  ),
  awful.button(
    {modkey},
    5,
    function()
      awful.layout.inc(-1)
    end
  )
)

local icons = require('theme.icons')
local apps = require('configuration.apps')

local tags = {
    {
        icon = icons.firefox,
        type = 'firefox',
        defaultApp = apps.default.browser,
        screen = 1
    }, {
        icon = icons.code,
        type = 'code',
        defaultApp = apps.default.editor,
        screen = 1
    }, {
        icon = icons.folder,
        type = 'files',
        defaultApp = apps.default.files,
        screen = 1
    }, {
        icon = icons.console,
        type = 'console',
        defaultApp = apps.default.terminal,
        screen = 1
    }, {
        icon = icons.social,
        type = 'social',
        defaultApp = apps.default.social,
        screen = 1
    },
    {icon = icons.lab, type = 'any', defaultApp = apps.default.rofi, screen = 1}
}

awful.layout.layouts = {
    awful.layout.suit.tile, awful.layout.suit.max, awful.layout.suit.floating
}

awful.screen.connect_for_each_screen(function(s)
    for i, tag in pairs(tags) do
        awful.tag.add(i, {
            icon = tag.icon,
            icon_only = true,
            layout = awful.layout.suit.tile,
            gap_single_client = true,
            gap = 4,
            screen = s,
            defaultApp = tag.defaultApp,
            selected = i == 1
        })
    end
end)

_G.tag.connect_signal('property::layout', function(t)
    local currentLayout = awful.tag.getproperty(t, 'layout')
    if (currentLayout == awful.layout.suit.max) then
        t.gap = 4
    else
        t.gap = 4
    end
end)

--- END

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s)
    -- If wallpaper is a function, call it with the screen
    if beautiful.wallpaper then
        if type(beautiful.wallpaper) == "string" then
            if beautiful.wallpaper:sub(1, #"#") == "#" then
                gears.wallpaper.set(beautiful.wallpaper)
            elseif beautiful.wallpaper:sub(1, #"/") == "/" then
                gears.wallpaper.maximized(beautiful.wallpaper, s)
            end
        else
            beautiful.wallpaper(s)
        end
    end
end)

-- Signal function to execute when a new client appears.
_G.client.connect_signal('manage', function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not _G.awesome.startup then awful.client.setslave(c) end

    if _G.awesome.startup and not c.size_hints.user_position and
        not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
_G.client.connect_signal('mouse::enter', function(c)
    c:emit_signal('request::activate', 'mouse_enter', {raise = true})
end)

-- Make the focused window have a glowing border
_G.client.connect_signal('focus', function(c)
    c.border_color = beautiful.border_focus
end)
_G.client.connect_signal('unfocus', function(c)
    c.border_color = beautiful.border_normal
end)
