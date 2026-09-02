-- Status line for the background worker, scripts/bg/wez_bg_tasks.py.
--
-- The worker ticks every other second and writes what it found to a small json
-- file; this module starts it and renders that file in the status line. It is
-- deliberately one way: wezterm only ever reads the file, so a worker that is
-- missing, slow or dead can never block or slow down the status line.
--
-- Why a file and not an environment variable or a wezterm user var:
--   the worker is a separate process, so it cannot change wezterm's
--   environment after the fact, and a user var would need a handle on a pane's
--   tty (see the same note in claude.lua). A json file that is replaced
--   atomically is the cheapest thing that works the same on Windows and Linux.
--
-- Starting the worker:
--   the worker itself makes sure only one copy runs (a named mutex on Windows,
--   an flock'ed file elsewhere), so every wezterm instance may call start().
--   The freshness check below only avoids the pointless interpreter start.
--
-- Usage from wezterm.lua:
--   bg_status.start()                 -- from "gui-startup"
--   bg_status.poll(window)            -- from "update-right-status"
--   bg_status.segments()              -- segments for set_right_status

local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

local is_windows = wezterm.target_triple:find('windows') ~= nil

-- Hard-coded switch: nothing in this module does anything unless this is true
M.enabled = true

--- Reads a boolean environment variable: nil when unset or empty, false for
-- 0/off/false/no in any case, true for anything else. Same helper as in
-- ~/.wezterm/nvim_server.lua, which reads the linux switch below as well.
local function env_bool(name)
  local value = os.getenv(name)
  if value == nil then
    return nil
  end
  value = value:lower():gsub('%s', '')
  if value == '' then
    return nil
  end
  return not (value == '0' or value == 'off' or value == 'false' or value == 'no')
end

-- Opt in to running the wezterm side of this on linux. The same variable
-- enables nvim_server.lua, so one export covers both modules.
M.linux_env_switch = 'WEZ_ENABLE_ON_LINUX'

-- Forced off on linux unless that variable says otherwise: the keyboard half
-- of the worker is AutoHotkey, i.e. windows only whatever this says, and the
-- headless nvim servers it reports on are off there by default too (see
-- nvim_server.lua). With the switch set, the worker still runs and reports on
-- the nvim servers; the keyboard icon simply never appears.
if not is_windows and not env_bool(M.linux_env_switch) then
  M.enabled = false
end

-- Hard-coded switch: how the status line shows what the worker found.
--   false  only a warning text, and only while the nvim servers are out of
--          date; nothing about the keyboard is ever shown (default)
--   true   two permanently visible icons, colored by state: one for the nvim
--          servers, one for the keyboard
M.use_icons = true

-- Text drawn in warning color in the default (non icon) mode
M.warning_text = 'nvim servers out of date'
-- Shown instead of it, in info color, while a lua file in the dotfiles copy of
-- the config is newer than a running server (see M.colors.info below)
M.dotfiles_warning_text = 'nvim dotfiles newer than servers'
-- Also show how many servers are out of date. Text mode spells it out as
-- "(2/5)" after the warning; icon mode only puts the number of stale servers
-- next to the icon, and nothing at all while they are in sync, so the icons
-- keep the same width they have with this turned off.
M.show_counts = false
M.text_count_format = ' (%d/%d)'
M.icon_count_format = ' %d'

-- Hard-coded switch: draw a dim question mark in icon mode while the worker is
-- not running, or its last result is older than M.stale_seconds. Off by
-- default; there is a short gap between wezterm starting the worker and its
-- first tick, and a marker for it is noise rather than information. Turn it on
-- when you want to see that the worker is not answering.
M.show_unknown_icon = false

-- Drawn between this module's output and the rest of the right status
M.separator = '  '
-- Between the two icons
M.icon_separator = ' '

-- Nerd font glyphs; wezterm falls back to its bundled Symbols Nerd Font when
-- the main font has no glyph, so these render without configuring a font.
M.icons = {
  -- nf-dev-vim; alternatives: 0xe6ae (nf-custom-neovim), or plain 'V'
  nvim = utf8.char(0xe62b),
  -- nf-fa-keyboard_o; alternatives: 0xf030c (nf-md-keyboard), or plain 'K'
  keyboard = utf8.char(0xf11c),
  -- Shown instead of both when the worker is not running
  unknown = utf8.char(0xf128), -- nf-fa-question
}

-- Gruvbox, to match the branch colors in wezterm.lua
M.colors = {
  ok      = '#98971a', -- green, everything in sync
  warn    = '#fe8019', -- orange, servers older than the config
  bad     = '#cc241d', -- red, unused by default
  info    = '#83a598', -- blue, the keychron remaps itself / dotfiles are newer
  dim     = '#665c54', -- grey, nothing to say / worker not running
}

local home = (os.getenv('HOME') or os.getenv('USERPROFILE') or '.'):gsub('\\', '/')

-- Written by the worker; keep in sync with STATE_FILE in wez_bg_tasks.py
M.state_file = home .. '/.wezterm/bg-status.json'

-- The worker, under {my_notes_path}/scripts/bg/
local notes_dir = (os.getenv('my_notes_path') or (home .. '/my_notes')):gsub('\\', '/')
M.script_path = notes_dir .. '/scripts/bg/wez_bg_tasks.py'

-- Interpreter used to start it. nil = work it out (pythonw.exe on Windows, so
-- no console window flashes up; python3 elsewhere).
M.python = nil

-- A state file older than this means the worker died, so start() may run
-- another one and the status line stops trusting what it says. Has to be well
-- above the worker's own STATE_HEARTBEAT_SECONDS.
M.stale_seconds = 20

-- The status event fires about once a second per window; re-reading the file
-- more often than this would only repeat work for the second window.
M.cache_seconds = 1

-- How often start() is allowed to look at whether the worker is still alive.
-- Only matters when it died mid-session; the normal start happens at launch.
M.restart_check_seconds = 60

-- wezterm only watches the main config file, not the modules it requires
pcall(function()
  wezterm.add_to_config_reload_watch_list(debug.getinfo(1, 'S').source:sub(2))
end)

-- ---------------------------------------------------------------------------
-- State file
-- ---------------------------------------------------------------------------

local cache = { state = nil, read_at = 0 }

local function read_state()
  local file = io.open(M.state_file, 'r')
  if not file then
    return nil
  end
  local contents = file:read('*a')
  file:close()
  if not contents or contents == '' then
    return nil
  end
  local ok, state = pcall(wezterm.json_parse, contents)
  if not ok or type(state) ~= 'table' then
    return nil
  end
  return state
end

--- The worker's last result, or nil when it is missing or too old to trust.
local function current_state()
  local now = os.time()
  if now - cache.read_at >= M.cache_seconds then
    cache.read_at = now
    cache.state = read_state()
  end

  local state = cache.state
  if not state or type(state.updated) ~= 'number' then
    return nil
  end
  -- Clock skew would otherwise make a fresh file look ancient
  if math.abs(now - state.updated) > M.stale_seconds then
    return nil
  end
  return state
end

-- ---------------------------------------------------------------------------
-- Starting the worker
-- ---------------------------------------------------------------------------

local last_start_attempt = 0

local function resolve_python()
  if M.python then
    return M.python
  end
  if not is_windows then
    return 'python3'
  end
  -- Prefer a real installation over the WindowsApps alias, and pythonw over
  -- python so that no console window appears
  local local_app_data = (os.getenv('LOCALAPPDATA') or ''):gsub('\\', '/')
  local ok, matches = pcall(wezterm.glob,
    local_app_data .. '/Programs/Python/Python*/pythonw.exe')
  if ok and matches and #matches > 0 then
    table.sort(matches)
    return matches[#matches] -- highest version
  end
  return 'pythonw.exe'
end

--- Starts the worker unless one is clearly already running. Safe to call from
-- every wezterm instance and after every config reload: a second worker exits
-- by itself, this check only avoids paying for the interpreter start.
--
-- Called on every status tick, but the rate limit below means it does nothing
-- at all except once a minute, when it re-checks the state file and starts a
-- replacement if the worker died.
function M.start()
  if not M.enabled then
    return
  end

  local now = os.time()
  if now - last_start_attempt < M.restart_check_seconds then
    return
  end
  last_start_attempt = now

  if current_state() then
    return -- a worker updated the state file moments ago
  end

  local script = io.open(M.script_path, 'r')
  if not script then
    wezterm.log_error('bg_status: worker not found at ' .. M.script_path)
    return
  end
  script:close()

  local python = resolve_python()
  local ok, err = pcall(wezterm.background_child_process, { python, M.script_path })
  if not ok then
    wezterm.log_error('bg_status: failed to start ' .. python .. ' ' ..
      M.script_path .. ': ' .. tostring(err))
  end
end

--- Start on the status tick as well, which is what covers linux (where
-- "gui-startup" is not registered) and a worker that died while wezterm kept
-- running. Rate limited by M.restart_check_seconds, so this is nearly free.
function M.poll(_window)
  if not M.enabled then
    return
  end
  M.start()
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

--- "(2/5)" for the warning text, or "" when the counts are turned off.
local function text_counts(nvim)
  if not M.show_counts or not nvim then
    return ''
  end
  return M.text_count_format:format(nvim.stale_servers or 0, nvim.servers or 0)
end

--- Just the number of stale servers for the icon row, or nil when there is
-- nothing to count. Kept out of the icon string on purpose: the glyph comes
-- from the fallback symbols font, and hanging text off it makes the whole
-- icon wide. As its own segment the icon stays exactly as it looks without
-- the counts.
local function icon_counts(nvim)
  if not M.show_counts or not nvim then
    return nil
  end
  local stale = nvim.stale_servers or 0
  if stale == 0 then
    return nil
  end
  return M.icon_count_format:format(stale)
end

--- Icon, color and optional count for the nvim servers, or nil for no icon.
-- blue   a lua file in the dotfiles copy is newer than a running server
-- orange the servers predate the live config
-- green  in sync
-- Nothing is drawn while no server is running: with the headless servers
-- switched off there is nothing that could be out of sync, and an icon for it
-- would just be noise. (Return M.icons.nvim, M.colors.dim here instead to get
-- a greyed out icon in that case.)
local function nvim_icon(nvim)
  if not nvim or not nvim.enabled or (nvim.servers or 0) == 0 then
    return nil
  end
  -- Checked first: this is the one thing the worker knows about the dotfiles
  -- copy itself, and orange would say the live config is stale instead
  if nvim.reference_newer then
    return M.icons.nvim, M.colors.info, icon_counts(nvim)
  end
  if nvim.out_of_date then
    return M.icons.nvim, M.colors.warn, icon_counts(nvim)
  end
  return M.icons.nvim, M.colors.ok
end

--- Icon and color for the keyboard.
-- blue   the keychron is plugged in and does the remapping itself
-- green  no keychron, ahk is doing it instead
-- orange neither or both, i.e. caps lock is unmapped or mapped twice; that
--        normally lasts for a single tick while the worker catches up
local function keyboard_icon(keyboard)
  if not keyboard or not keyboard.enabled or keyboard.keychron == nil then
    return nil
  end
  local ahk_running = (keyboard.ahk or 0) > 0
  if keyboard.keychron and not ahk_running then
    return M.icons.keyboard, M.colors.info
  end
  if not keyboard.keychron and ahk_running then
    return M.icons.keyboard, M.colors.ok
  end
  return M.icons.keyboard, M.colors.warn
end

--- Segments to put in front of the regular right status, possibly empty.
function M.segments()
  if not M.enabled then
    return {}
  end

  local state = current_state()
  local segments = {}

  local function add(text, color)
    table.insert(segments, { Foreground = { Color = color } })
    table.insert(segments, { Text = text })
    table.insert(segments, 'ResetAttributes')
  end

  if not M.use_icons then
    -- Say something only when the dotfiles or the servers are out of date
    if state and state.nvim and state.nvim.reference_newer then
      add(M.dotfiles_warning_text .. text_counts(state.nvim), M.colors.info)
      table.insert(segments, { Text = M.separator })
    elseif state and state.nvim and state.nvim.out_of_date then
      add(M.warning_text .. text_counts(state.nvim), M.colors.warn)
      table.insert(segments, { Text = M.separator })
    end
    return segments
  end

  if not state then
    -- Worker not running or not answering; say nothing unless asked to
    if M.show_unknown_icon then
      add(M.icons.unknown, M.colors.dim)
      table.insert(segments, { Text = M.separator })
    end
    return segments
  end

  local icons = {}
  local nvim_text, nvim_color, nvim_count = nvim_icon(state.nvim)
  if nvim_text then
    table.insert(icons, { text = nvim_text, color = nvim_color, count = nvim_count })
  end
  local keyboard_text, keyboard_color = keyboard_icon(state.keyboard)
  if keyboard_text then
    table.insert(icons, { text = keyboard_text, color = keyboard_color })
  end

  for index, icon in ipairs(icons) do
    add(icon.text, icon.color)
    if icon.count then
      -- Own segment, so the glyph above is never laid out together with digits
      add(icon.count, icon.color)
    end
    if index < #icons then
      table.insert(segments, { Text = M.icon_separator })
    end
  end

  if #segments > 0 then
    table.insert(segments, { Text = M.separator })
  end
  return segments
end

return M
