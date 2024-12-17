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
--config.enable_wayland = true
config.enable_wayland = false -- Required for hyprland?
-- config.font = wezterm.font('Hack')
--config.font = wezterm.font('Monaspace Neon')

local user_domain = os.getenv("USERDOMAIN") or ""
if string.lower(user_domain):find("lenovo2") then
  config.font_size = 10.0
else
  config.font_size = 11.0
end

-- https://wezfurlong.org/wezterm/config/lua/config/max_fps.html
config.max_fps = 240

-- https://wezfurlong.org/wezterm/hyperlinks.html#implicit-hyperlinks
config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
  regex = [[\b[tt](\d+)\b]],
  format = 'https://example.com/tasks/?t=$1',
})

table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = 'https://www.github.com/$1/$3',
})

-- https://wezfurlong.org/wezterm/quickselect.html
-- https://wezfurlong.org/wezterm/config/lua/keyassignment/QuickSelect.html
-- config.quick_select_patterns = {
--   -- match things that look like sha1 hashes
--   -- (this is actually one of the default patterns)
--   '[0-9a-f]{7,40}',
-- }
-- Filenames
config.quick_select_patterns = {
  -- Match filenames with an optional path (e.g., test.txt, /path/to/init.lua)
  '[^\\s]+\\.[a-zA-Z0-9]+',
}

config.hide_tab_bar_if_only_one_tab = true
config.mouse_bindings = {
  -- Open URLs with Ctrl+Click
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  }
}

config.unzoom_on_switch_pane = true
config.pane_focus_follows_mouse = false
config.scrollback_lines = 5000 -- Default is 3500
config.use_dead_keys = false
config.warn_about_missing_glyphs = false
--config.window_decorations = 'TITLE | RESIZE'
--config.window_decorations = 'NONE'
config.window_decorations = 'RESIZE'
if wezterm.target_triple == 'x86_64-pc-windows-msvc' or wezterm.target_triple == 'x86_64-pc-windows-gnu' then
  config.show_close_tab_button_in_tabs = false

  -- The leader is similar to how tmux defines a set of keys to hit in order to
  -- invoke tmux bindings. Binding to ctrl-a here to mimic tmux
  config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

  config.window_padding = {
    left = 15,
    right = 5,
    top = 20,
    bottom = 10,
  }
  --config.use_fancy_tab_bar = true
  config.use_fancy_tab_bar = false
else
  config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 1000 }
  --config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

  config.window_padding = {
    left = 10,
    right = -3,
    top = 10,
    bottom = 0,
  }
  config.window_close_confirmation = "NeverPrompt"
  --config.enable_tab_bar = false
  config.use_fancy_tab_bar = false
end

-- Tab bar
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
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

-- https://wezfurlong.org/wezterm/config/default-keys.html
-- config.disable_default_key_bindings = true,

-- Session manager
wezterm.on("save_session", function(window) session_manager.save_state(window) end)
wezterm.on("load_session", function(window) session_manager.load_state(window) end)
wezterm.on("restore_session", function(window) session_manager.restore_state(window) end)

-- Seamless vim pane integration
-- I have a somewhat customized version of these that 
-- enable me to navigate panes via wezterm-tmux-nvim
-- https://github.com/letieu/wezterm-move.nvim
-- https://github.com/mrjones2014/smart-splits.nvim

-- Next and Prev is also available as dir keys
local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local resize_keys = {
  y = "Left",
  u = "Down",
  i = "Up",
  o = "Right",
}

-- Log to a simple file
local log_file = (os.getenv("HOME") or os.getenv("USERPROFILE")) .. "/wez_test.txt"
local function log_to_file(message)
  local file = io.open(log_file, "a") -- Open in append mode
  if file then
    file:write(message .. "\n")
    file:close()
  else
    wezterm.log_error("Failed to open log file: " .. log_file)
  end
end

local function is_vim(pane)
  local process_info = pane:get_foreground_process_info()
  local process_name = process_info and process_info.name
  --wezterm.log_info("process_name: " .. (process_name or "nil"))
  --log_to_file("process_name: " .. (process_name or "nil"))

  return process_name == "nvim" or process_name == "vim"
end

local function is_tmux(pane)
  local process_info = pane:get_foreground_process_info()
  local process_name = process_info and process_info.name
  --wezterm.log_info("process_name: " .. (process_name or "nil"))
  --log_to_file("process_name: " .. (process_name or "nil"))

  return process_name and string.find(process_name, "tmux", 1, true) ~= nil
end

-- Handle pane split in wezterm, tmux, or vim
local function split_nav(key)
  return {
    key = key,
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      -- Check if there are multiple panes to navigate
      local dir = direction_keys[key]
      local tab = pane:tab()

      if is_tmux(pane) then
        win:perform_action({ SendKey = { key = key, mods = "ALT" } }, pane)
        return
      end

      local opposite_dir = dir == "Left" and "Right" or dir == "Right" and "Left" or dir == "Up" and "Down" or "Up"

      -- Use nvim pane switching if pane is zoomed
      -- https://wezfurlong.org/wezterm/config/lua/MuxTab/panes_with_info.html
      --local is_zoomed = pane.is_zoomed
      local is_zoomed = false
      for _, pane_info in ipairs(tab:panes_with_info()) do
        if pane_info.is_zoomed then
          is_zoomed = true
          break
        end
      end

      if tab:get_pane_direction(dir) and not is_zoomed then
        win:perform_action({ ActivatePaneDirection = dir }, pane)
      elseif tab:get_pane_direction(opposite_dir) and not is_zoomed then
        win:perform_action({ ActivatePaneDirection = opposite_dir }, pane)
      else
        -- Send the key sequence to process, e.g., vim
        -- win:perform_action({
        -- SendKey = { key = key, mods = "ALT" }
        -- }, pane)
        win:perform_action({
          SendKey = { key = "w", mods = "CTRL" },
        }, pane)
        win:perform_action({
          SendKey = { key = key },
        }, pane)
      end
    end),
  }
end

-- Handle resize in wezterm, tmux or vim
local function resize_pane(key)
  return {
    key = key,
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      local dir = resize_keys[key]
      local tab = pane:tab()

      if is_tmux(pane) then
        win:perform_action({ SendKey = { key = key, mods = "ALT" } }, pane)
        return
      end

      local is_zoomed = false
      for _, pane_info in ipairs(tab:panes_with_info()) do
        if pane_info.is_zoomed then
          is_zoomed = true
          break
        end
      end

      -- Check if there's a pane in either primary dir or opposite
      local opposite_dir = dir == "Left" and "Right" or dir == "Right" and "Left" or dir == "Up" and "Down" or "Up"
      if (tab:get_pane_direction(dir) or tab:get_pane_direction(opposite_dir)) and not is_zoomed then
        win:perform_action(act.AdjustPaneSize { dir, 5 }, pane)
      else
        -- Send ALT + SHIFT + key to Vim for resizing inside Vim
        -- win:perform_action({ SendKey = { key = key:upper(), mods = "ALT|SHIFT" } }, pane)
        win:perform_action({ SendKey = { key = key, mods = "ALT|CTRL" } }, pane)
      end
    end),
  }
end

-- Custom key bindings
config.keys = {
  -- Leader is defined as Ctrl-A but this allows it to be sent to programs like vim when pressed twice
  { key = 'a', mods = 'LEADER|CTRL', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' }, },

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
  { key = "q", mods = "LEADER|CTRL", action = act.CloseCurrentPane { confirm = false } },

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
  { key = 'q', mods = 'LEADER|SHIFT', action = wezterm.action.QuitApplication },
  -- Seamless vim pane integration
  split_nav("h"),
  split_nav("j"),
  split_nav("k"),
  split_nav("l"),
  resize_pane("y"),
  resize_pane("u"),
  resize_pane("i"),
  resize_pane("o"),
  -- QuickSelect
  -- shift-ctrl-space is provided by default
  -- https://wezfurlong.org/wezterm/config/default-keys.html
  -- { key = ' ', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
  --{ key = ' ', mods = 'ALT|SHIFT', action = wezterm.action.QuickSelect },

  -- Customizing QuickSelect
  -- https://wezfurlong.org/wezterm/config/lua/keyassignment/QuickSelectArgs.html
  {
    key = ' ',
    mods = 'ALT|SHIFT',
    action = wezterm.action.QuickSelectArgs {
      label = 'open url',
      patterns = {
        'https?://\\S+',
      },
      action = wezterm.action_callback(function(window, pane)
        local url = window:get_selection_text_for_pane(pane)
        wezterm.log_info('opening: ' .. url)
        wezterm.open_with(url)
      end),
    },
  },

  -- Make ctrl-tab cycle tabs / windows for both wezterm and tmux
  {
    key = "Tab",
    mods = "CTRL",
    action = wezterm.action.Multiple({
      act.ActivateTabRelative(1),
      wezterm.action.SendKey({ key = "Tab", mods = "CTRL" }),
    }),
  },

  {
    key = "Tab",
    mods = "CTRL|SHIFT",
    action = wezterm.action.Multiple({
      act.ActivateTabRelative(-1),
      wezterm.action.SendKey({ key = "Tab", mods = "CTRL|SHIFT" }),
    }),
  },
}

-- Read dir path and start a split pane
local function split_to_directory_with_delay(win, pane)
  -- Save dir under cursor into file in vim...
  win:perform_action({
    SendKey = { key = "w", mods = "CTRL" },
  }, pane)
  win:perform_action({
    SendKey = { key = "d" },
  }, pane)

  wezterm.sleep_ms(500)

  -- Open the saved dir in wezterm pane
  local userprofile = os.getenv("HOME") or os.getenv("USERPROFILE")
  local file_path = userprofile .. "/new_wez_dir.txt"

  -- print("file_path:" .. file_path)
  -- win:toast_notification("WezTerm Notification", "file_path: " .. file_path, nil, 4000)

  local file = io.open(file_path, "r")
  if not file then
    -- wezterm.log_info("File not found: " .. file_path)
    win:toast_notification("WezTerm Notification", "File not found: " .. file_path, nil, 4000)
    return
  end

  -- Read dir path from file
  local directory = file:read("*line")
  file:close()

  -- Validate path
  -- Might be in: %TEMP%\wezterm.log or /tmp/wezterm.log
  -- https://wezfurlong.org/wezterm/troubleshooting.html
  if directory and directory ~= "" then --and wezterm.path.exists(directory) then
    -- wezterm.log_info("Splitting to directory: " .. directory)
    -- win:toast_notification("WezTerm Notification", "Splitting to dir: " .. directory, nil, 4000)

    local command = {
      cwd = directory
    }

    win:perform_action(
      wezterm.action.SplitPane {
        direction = "Right",
        size = { Percent = 50 },
        command = command
        -- command = { cwd = directory }
      },
      pane
    )
    --else
    --    wezterm.log_info("Invalid directory path: " .. (directory or "nil"))
    --    win:toast_notification("WezTerm Notification", "Invalid directory path: " .. (directory or "nil"), nil, 4000)
  end
end

table.insert(config.keys, {
  key = "d",
  mods = "LEADER",
  action = wezterm.action_callback(split_to_directory_with_delay),
})

-- Open github repo in firefox
local function open_github_repo(win, pane)
  local cwd_uri = tostring(pane:get_current_working_dir())
  if not cwd_uri then
    wezterm.log_error("Failed to determine current working directory.")
    return
  end

  local cwd = cwd_uri:gsub("file://ornf", "")
  cwd = cwd:gsub("file://", "")
  cwd = cwd:gsub("^/([A-Za-z]:)", "%1")

  -- Debug
  --log_to_file(cwd)
  -- See file logs via:
  -- vim $env:USERPROFILE/wez_test.txt

  local is_windows = wezterm.target_triple:find("windows") ~= nil
  local git_remote_cmd, git_branch_cmd

  if is_windows then
    -- ps
    --git_remote_cmd = string.format('cd "%s"; git remote get-url origin', cwd)
    --git_branch_cmd = string.format('cd "%s"; git rev-parse --abbrev-ref HEAD', cwd)
    -- cmd
    git_remote_cmd = string.format('cd /d %s & git remote get-url origin', cwd)
    git_branch_cmd = string.format('cd /d %s & git rev-parse --abbrev-ref HEAD', cwd)
  else
    git_remote_cmd = string.format('cd %s && git remote get-url origin 2>/dev/null', cwd)
    git_branch_cmd = string.format('cd %s && git rev-parse --abbrev-ref HEAD 2>/dev/null', cwd)
  end

  -- Debug
  --log_to_file("git_remote_cmd: " .. (git_remote_cmd or "nil"))

  local success, stdout, stderr = wezterm.run_child_process({
    -- ps
    --is_windows and "powershell.exe" or "bash",
    --is_windows and "-Command" or "-c",
    -- cmd
    is_windows and "cmd.exe" or "bash",
    is_windows and "/c" or "-c",
    git_remote_cmd,
  })
  -- Debug
  --log_to_file("success: " .. (tostring(success) or "nil"))
  --log_to_file("stdout: " .. (tostring(stdout) or "nil"))
  --log_to_file("stderr: " .. (tostring(stderr) or "nil"))
  local remote = stdout

  success, stdout, stderr = wezterm.run_child_process({
    -- ps
    --is_windows and "powershell.exe" or "bash",
    --is_windows and "-Command" or "-c",
    -- cmd
    is_windows and "cmd.exe" or "bash",
    is_windows and "/c" or "-c",
    git_branch_cmd,
  })
  -- Debug
  --log_to_file("success: " .. (tostring(success) or "nil"))
  --log_to_file("stdout: " .. (tostring(stdout) or "nil"))
  --log_to_file("stderr: " .. (tostring(stderr) or "nil"))
  local branch = stdout

  if not remote or not branch or remote == "" or branch == "" then
    --wezterm.log_error("Failed to determine Git repository or branch.")
    win:toast_notification("WezTerm Notification", "Failed to determine Git repository or branch.", nil, 4000)
    return
  end

  remote = remote:gsub("%.git$", ""):gsub("^git@github%.com:", "https://github.com/"):gsub("\r", ""):gsub("\n", "")
  remote = remote:gsub("%.git$", "")
  branch = branch:gsub("\r", ""):gsub("\n", "")
  local github_url = remote .. "/tree/" .. branch

  -- Debug
  --log_to_file("github_url: " .. (git_remote_cmd or "nil"))

  wezterm.run_child_process({ "firefox", github_url })
end

table.insert(config.keys, {
  key = "g",
  mods = "LEADER",
  action = wezterm.action_callback(open_github_repo),
})

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
  --local max_title_len = 20 -- If use_fancy_tab_bar
  local max_title_len = 15
  if #new_title > max_title_len then
    --new_title = ".." .. new_title:sub(-(max_title_len-3)) -- If use_fancy_tab_bar
    new_title = ".." .. new_title:sub(-(max_title_len-3)) .. " "
  end
  return {
    { Text = new_title }
  }
end)

-- Testing right-status: https://wezfurlong.org/wezterm/config/lua/window/set_right_status.html
--wezterm.on('update-right-status', function(window, pane)
--  local date = wezterm.strftime '%Y-%m-%d %H:%M:%S'
--  -- Make it italic and underlined
--  window:set_right_status(wezterm.format {
--    { Attribute = { Underline = 'Single' } },
--    { Attribute = { Italic = true } },
--    { Text = date },
--  })
--end)

wezterm.on("update-right-status", function(window, pane)
  local cwd_uri = tostring(pane:get_current_working_dir())

  local cwd = cwd_uri:gsub("file://ornf", "")
  cwd = cwd:gsub("file://", "")
  cwd = cwd:gsub("^/([A-Za-z]:)", "%1")

  local git_branch = nil
  local is_windows = wezterm.target_triple:find("windows") ~= nil

  if cwd then
    local git_cmd
    if is_windows then
      git_cmd = string.format(
        'cd "%s"; git rev-parse --abbrev-ref HEAD 2>$null',
        cwd:gsub("\\", "/")
      )
    else
      git_cmd = string.format(
        "cd '%s' && git rev-parse --abbrev-ref HEAD 2>/dev/null",
        cwd
      )
    end

    local success, stdout, stderr = wezterm.run_child_process({
      is_windows and "powershell" or "bash",
      is_windows and "-Command" or "-c",
      git_cmd,
    })

    if success and stdout and stdout:match("%S") then
      git_branch = stdout:gsub("%s+$", "") -- Trim trailing whitespace
    end
  end

  local right_status = git_branch or wezterm.hostname()

  window:set_right_status(wezterm.format({
    { Text = right_status },
  }))
end)

-- Return config to wezterm
return config

