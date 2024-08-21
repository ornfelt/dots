-- Pull in the wezterm API
local os              = require 'os'
local wezterm         = require 'wezterm'
local act             = wezterm.action
local mux             = wezterm.mux
local session_manager = require 'wezterm-session-manager/session-manager'

local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.enable_scroll_bar = true
config.enable_wayland = true
-- config.font = wezterm.font('Hack')
--config.font = wezterm.font('Monaspace Neon')
config.font_size = 11.0
config.hide_tab_bar_if_only_one_tab = true
-- The leader is similar to how tmux defines a set of keys to hit in order to
-- invoke tmux bindings. Binding to ctrl-a here to mimic tmux
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.mouse_bindings = {
    -- Open URLs with Ctrl+Click
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.OpenLinkAtMouseCursor,
    }
}
config.pane_focus_follows_mouse = false
config.scrollback_lines = 5000 -- Default is 3500
config.use_dead_keys = false
config.warn_about_missing_glyphs = false
--config.window_decorations = 'TITLE | RESIZE'
--config.window_decorations = 'NONE'
config.window_decorations = 'RESIZE'
config.window_padding = {
    left = 15,
    right = 5,
    top = 20,
    bottom = 10,
}

-- Tab bar
--config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_max_width = 15
config.colors = {
    tab_bar = {
        active_tab = {
            fg_color = '#3c3836',
            --bg_color = '#8ec07c',
            bg_color = '#458588',
        }
    }
}

-- Setup muxing by default
config.unix_domains = {
  {
    name = 'unix',
  },
}

-- Session manager
wezterm.on("save_session", function(window) session_manager.save_state(window) end)
wezterm.on("load_session", function(window) session_manager.load_state(window) end)
wezterm.on("restore_session", function(window) session_manager.restore_state(window) end)

-- Custom key bindings
config.keys = {
    -- Copy/vim mode
    { key = 'v', mods = 'LEADER', action = act.ActivateCopyMode, },
    { key = 'f', mods = 'LEADER', action = wezterm.action.Search {CaseInSensitiveString = 'test' } },
    { key = 'f', mods = 'LEADER|CTRL', action = wezterm.action.Search {CaseSensitiveString = 'test' } },
    { key = 'g', mods = 'LEADER', action = wezterm.action.Search {Regex = 'test'} },

    -- ----------------------------------------------------------------
    -- TABS
    --
    -- Where possible, I'm using the same combinations as I would in tmux
    -- ----------------------------------------------------------------

    -- Show tab navigator; similar to listing panes in tmux
    {
        key = 'w',
        mods = 'LEADER',
        action = act.ShowTabNavigator,
    },
    -- Rename current tab; analagous to command in tmux
    {
        key = ',',
        mods = 'LEADER|ALT',
        action = act.PromptInputLine {
            description = 'Enter new name for tab',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        window:active_tab():set_title(line)
                    end
                end
            ),
        },
    },
    -- Move to next/previous TAB
    --{
    --    key = 'n',
    --    mods = 'LEADER',
    --    action = act.ActivateTabRelative(1),
    --},
    --{
    --    key = 'p',
    --    mods = 'LEADER',
    --    action = act.ActivateTabRelative(-1),
    --},
    -- Close tab
    {
        key = 'q',
        mods = 'LEADER|SHIFT',
        action = act.CloseCurrentTab{ confirm = true },
    },

    -- ----------------------------------------------------------------
    -- PANES
    --
    -- These are great and get me most of the way to replacing tmux
    -- entirely, particularly as you can use "wezterm ssh" to ssh to another
    -- server, and still retain Wezterm as your terminal there.
    -- ----------------------------------------------------------------

    -- Vertical split
    {
        key = 'Enter',
        mods = 'LEADER',
        action = act.SplitPane {
            direction = 'Right',
            size = { Percent = 50 },
        },
    },
    -- Horizontal split
    {
        key = '<',
        mods = 'LEADER',
        action = act.SplitPane {
            direction = 'Down',
            size = { Percent = 50 },
        },
    },
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = 'y', mods = 'LEADER', action = act.AdjustPaneSize { 'Left', 5 }, },
    { key = 'u', mods = 'LEADER', action = act.AdjustPaneSize { 'Down', 5 }, },
    { key = 'i', mods = 'LEADER', action = act.AdjustPaneSize { 'Up', 5 } },
    { key = 'o', mods = 'LEADER', action = act.AdjustPaneSize { 'Right', 5 }, },
    { key = "q", mods = "LEADER", action = act.CloseCurrentPane { confirm = false } },

    -- Swap active pane with another one
    {
        key = 'T',
        mods = 'LEADER|SHIFT',
        action = act.PaneSelect { mode = "SwapWithActiveKeepFocus" },
    },
    -- Zoom current pane (toggle)
    {
        key = 'z',
        mods = 'LEADER',
        action = act.TogglePaneZoomState,
    },
    {
        key = 'f',
        mods = 'LEADER|SHIFT',
        action = act.TogglePaneZoomState,
    },
    -- Move to next/previous pane
    --{
    --    key = ';',
    --    mods = 'LEADER',
    --    action = act.ActivatePaneDirection('Prev'),
    --},
    --{
    --    key = 'o',
    --    mods = 'LEADER',
    --    action = act.ActivatePaneDirection('Next'),
    --},

    ---- Attach to muxer
    {
        key = 'a',
        mods = 'LEADER',
        action = act.AttachDomain 'unix',
    },

    -- Detach from muxer
    {
        key = 'd',
        mods = 'LEADER',
        action = act.DetachDomain { DomainName = 'unix' },
    },

    -- Show list of workspaces
    {
        key = 's',
        mods = 'LEADER',
        action = act.ShowLauncherArgs { flags = 'WORKSPACES' },
    },
    -- Rename current session; analagous to command in tmux
    {
        key = '-',
        mods = 'LEADER|ALT',
        action = act.PromptInputLine {
            description = 'Enter new name for session',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        mux.rename_workspace(
                            window:mux_window():get_workspace(),
                            line
                        )
                    end
                end
            ),
        },
    },

    -- Scroll
    { key = 'J', mods = 'ALT|SHIFT', action = wezterm.action.ScrollByLine(1), },
    { key = 'K', mods = 'ALT|SHIFT', action = wezterm.action.ScrollByLine(-1), },

    -- Copying
    --if wezterm.target_triple ~= "x86_64-pc-windows-msvc" and wezterm.target_triple ~= "x86_64-pc-windows-gnu" then
    { key = 'C', mods = 'ALT|SHIFT', action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection', },
    { key = 'V', mods = 'ALT|SHIFT', action = wezterm.action.PasteFrom 'Clipboard', },

    -- Session manager
    {key = "m", mods = "LEADER", action = wezterm.action{EmitEvent = "save_session"}},
    {key = ".", mods = "LEADER", action = wezterm.action{EmitEvent = "restore_session"}},
    --{key = "p", mods = "LEADER", action = wezterm.action{EmitEvent = "load_session"}},

    -- Disable default
    { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'l', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'h', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'j', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },
    { key = 'k', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment, },

    -- Tabs
    { key = "1", mods = "LEADER", action = wezterm.action{ActivateTab=0}, },
    { key = "2", mods = "LEADER", action = wezterm.action{ActivateTab=1}, },
    { key = "3", mods = "LEADER", action = wezterm.action{ActivateTab=2}, },
    { key = "4", mods = "LEADER", action = wezterm.action{ActivateTab=3}, },
    { key = "5", mods = "LEADER", action = wezterm.action{ActivateTab=4}, },
    { key = "6", mods = "LEADER", action = wezterm.action{ActivateTab=5}, },
    { key = "7", mods = "LEADER", action = wezterm.action{ActivateTab=6}, },
    { key = "8", mods = "LEADER", action = wezterm.action{ActivateTab=7}, },
    { key = "9", mods = "LEADER", action = wezterm.action{ActivateTab=8}, },
    { key = "0", mods = "LEADER", action = wezterm.action{ActivateTab=9}, },
    { key = 't', mods = "LEADER", action = wezterm.action{SpawnTab="DefaultDomain"}, },
    { key = 'q', mods = 'LEADER|CTRL', action = wezterm.action.QuitApplication },
}

--config.default_gui_startup_args = { 'connect', 'unix' }
if wezterm.target_triple == 'x86_64-pc-windows-msvc' or wezterm.target_triple == 'x86_64-pc-windows-gnu' then
    --config.default_prog = { 'pwsh.exe', '-NoLogo' }
    config.default_prog = { 'powershell.exe' }

    wezterm.on('gui-startup', function(cmd)
        -- allow `wezterm start -- something` to affect what we spawn
        -- in our initial window
        local args = {}
        if cmd then
            args = cmd.args
        end

        ---- Set a workspace for coding on a current project
        ---- Top pane is for the editor, bottom pane is for the build tool
        --local project_dir = wezterm.home_dir .. '/wezterm'
        --local tab, build_pane, window = mux.spawn_window {
        --  workspace = 'coding',
        --  cwd = project_dir,
        --  args = args,
        --}
        --local editor_pane = build_pane:split {
        --  direction = 'Top',
        --  size = 0.6,
        --  cwd = project_dir,
        --}
        ---- may as well kick off a build in that pane
        --build_pane:send_text 'cargo build\n'

        ---- A workspace for interacting with a local machine that
        ---- runs some docker containners for home automation
        ----local tab, pane, window = mux.spawn_window {
        ----  workspace = 'automation',
        ----  args = { 'ssh', 'vault' },
        ----}

        ---- We want to startup in the coding workspace
        --mux.set_active_workspace 'coding'



        -- Try to attach...
        -- Check if the workspace 'coding' exists
        --local workspace_name = 'coding'
        --local existing_workspace = false
        --for _, workspace in ipairs(mux.get_workspaces()) do
        --  if workspace == workspace_name then
        --    existing_workspace = true
        --    break
        --  end
        --end

        --if existing_workspace then
        --    window = mux.attach_workspace(workspace_name)
        --else

        --local unix = mux.get_domain("unix")
        --mux.set_default_domain(unix)
        --unix:attach()
        --mux.set_active_workspace 'coding'

        --local code_root_dir = os.getenv("code_root_dir")
        --local full_path = code_root_dir .. "/Code2/C++"
        ----local tab1, pane, window = mux.spawn_window(cmd or {})
        local tab1, pane, window = mux.spawn_window{cwd = full_path, workspace = 'coding' }
        window:gui_window():maximize()
        --tab1:set_title("one - pwsh")

        --local code_root_dir = "~/"
        --local tab2, second_pane, _ = window:spawn_tab { cwd = code_root_dir, workspace = 'coding' }
        --tab2:set_title("two - pwsh")
        --local tab3, third_pane, _ = window:spawn_tab { cwd = "C:\\", workspace = 'coding' }
        --tab3:set_title("three - pwsh")
        ----third_pane:send_text ".cdc\n"
        --local tab4, fourth_pane, _ = window:spawn_tab { cwd = "~/", workspace = 'coding' }
        --tab4:set_title("four - pwsh")
        ----fourth_pane:send_text ".cdp\n"

        --tab1:activate()
        --end

        --session_manager.restore_state(window)

    end)
end

wezterm.on("format-tab-title", function(tab)
    local new_title = tostring(tab.active_pane.current_working_dir):gsub("^file:///", "")
    return {
        { Text = new_title }
    }
end)

-- Return config to wezterm
return config

