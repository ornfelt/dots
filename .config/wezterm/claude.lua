-- Claude Code integration: shows a robot icon on the tab that contains a Claude
-- Code pane whose response has finished, and clears it again once that tab is
-- visited. Also raises a status.notify() when a response finishes. A response
-- that ended on an API error (rate limit, out of funds, server error, ...) gets
-- a dead robot in the warning color instead, and a warning notification.
--
-- How the pane is identified:
--   Claude Code inherits WEZTERM_PANE and WEZTERM_UNIX_SOCKET from the shell it
--   was started in, so the "Stop" hook knows which wezterm pane, and which
--   wezterm instance, it belongs to. Every wezterm-gui process numbers its panes
--   from 0, so the pane id alone is not enough with two instances open; the
--   instance is the gui process pid at the end of WEZTERM_UNIX_SOCKET. It writes
--       <state_dir>/<instance>-<WEZTERM_PANE>.done
--   the "StopFailure" hook writes
--       <state_dir>/<instance>-<WEZTERM_PANE>.failed
--   (each removes the other one), and the "UserPromptSubmit" hook removes both
--   again. Both hold "key=value" lines: label, instance, pane, window, tab and
--   error. See ~/.claude/hooks/wezterm-claude-status.{ps1,sh}.
--
-- Every wezterm instance loads this file and sees every marker. All of them
-- show the status message; only the instance the pane lives in shows the tab
-- icon and clears the marker once that tab is visited.
--
-- Why polling instead of a pushed event:
--   wezterm can be pushed to via the SetUserVar OSC escape, but a hook process
--   has no usable handle on the pane's tty (no /dev/tty on Windows, and
--   `wezterm cli` has no set-user-var subcommand in every build). Polling a
--   directory from "update-right-status" costs one glob per second per window,
--   which is nothing, and behaves identically on Windows and Linux.
--
-- Usage from wezterm.lua:
--   claude.poll(window, pane)   -- from the "update-right-status" event
--   claude.tab_icon(tab)        -- from the "format-tab-title" event; returns
--                               -- the icon and its color (nil: tab default)

local wezterm = require 'wezterm' --[[@as Wezterm]]
local status = require 'status'

local M = {}

-- Hard-coded switch: set to false to disable the tab marker and notification
M.enabled = true

-- Prefixed to the title of tabs with a finished, unvisited response.
-- Nerd font alternatives: '󰚩 ' (nf-md-robot), '🤖 ', '● '
M.icon = '🤖 '
-- Prefixed instead when that response ended on an API error.
-- nf-md-robot_dead (U+F16A1), from the bundled Symbols Nerd Font Mono
M.failed_icon = '\u{f16a1} '
-- Gruvbox orange, same as status.colors.warning
M.failed_icon_color = status.colors.warning
-- Columns reserved for the icon when truncating the tab title
M.icon_width = 2

M.notification_title = 'Claude Code'
-- A finished response stays on the status line a second longer than the
-- other status messages
M.notification_timeout_ms = status.timeout_ms + 1000
-- Prefixed to the notification text. Both the status line and the toast
-- fallback take plain text, so a glyph/emoji is the only icon either can show.
M.notification_icon = M.icon
M.failed_notification_icon = M.failed_icon
-- Between the sessions that just finished and the ones still waiting
M.notification_separator = '  ·  '
-- Between the parts of "wezterm 5052, tab 3, pane 18"
M.location_separator = ', '

local home = (os.getenv('HOME') or os.getenv('USERPROFILE') or '.'):gsub('\\', '/')
-- Kept in sync with the hook scripts in ~/.claude/hooks/
M.state_dir = home .. '/.wezterm/claude-status'

local DONE_EXTENSION = 'done'
local FAILED_EXTENSION = 'failed'
-- What the hooks write when WEZTERM_UNIX_SOCKET doesn't name an instance
local UNKNOWN_INSTANCE = '0'

-- This wezterm instance: the pid its panes see in WEZTERM_UNIX_SOCKET
local ok_pid, pid = pcall(function() return wezterm.procinfo.pid() end)
M.instance = ok_pid and pid and tostring(pid) or nil

-- marker file name -> { path, kind, label, error, instance, pane_id, window,
-- tab, mine } for every marker on disk, of every wezterm instance
M.markers = {}

--- The "key=value" lines of a marker.
local function read_marker(path)
  local fields = {}
  local file = io.open(path, 'r')
  if not file then
    return fields
  end
  for line in file:lines() do
    -- Strip a UTF-8 BOM and surrounding whitespace
    line = line:gsub('^\239\187\191', ''):gsub('^%s+', ''):gsub('%s+$', '')
    local key, value = line:match('^([%w_]+)=(.*)$')
    if key and value ~= '' then
      fields[key] = value
    end
  end
  file:close()
  return fields
end

local function mux_pane_exists(pane_id)
  local ok, mux_pane = pcall(wezterm.mux.get_pane, pane_id)
  return ok and mux_pane ~= nil
end

--- True for a marker of a pane in this wezterm instance. With the instance
-- unknown on either side, a pane that exists here is taken to be ours.
local function is_mine(instance, pane_id)
  if instance ~= UNKNOWN_INSTANCE and M.instance then
    return instance == M.instance
  end
  return mux_pane_exists(pane_id)
end

--- The gui window owning pane_id, so the notification lands where the pane is.
local function gui_window_for_pane(pane_id, fallback)
  local ok, window = pcall(function()
    local mux_pane = wezterm.mux.get_pane(pane_id)
    if not mux_pane then
      return nil
    end
    return mux_pane:window():gui_window()
  end)
  if ok and window then
    return window
  end
  return fallback
end

local function window_is_focused(window)
  local ok, focused = pcall(function() return window:is_focused() end)
  if ok and focused ~= nil then
    return focused
  end
  -- Older wezterm without window:is_focused(): treat the window as focused
  return true
end

--- The gui window of this instance the user is looking at, else its first one.
local function target_gui_window()
  local ok, windows = pcall(function() return wezterm.gui.gui_windows() end)
  if not ok or not windows then
    return nil
  end
  for _, window in ipairs(windows) do
    if window_is_focused(window) then
      return window
    end
  end
  return windows[1]
end

--- 1-based index of the element whose id(element) is <id>, or nil.
local function index_of(list, id, get_id)
  for index, element in ipairs(list) do
    if get_id(element) == id then
      return index
    end
  end
  return nil
end

--- "tab 3, pane 18" for a pane of this instance, from the live mux (tabs may
-- have moved since the hook ran), with the window only when there are several.
local function live_location(entry)
  local parts = {}
  pcall(function()
    local mux_pane = wezterm.mux.get_pane(entry.pane_id)
    local mux_window = mux_pane:window()
    local windows = wezterm.mux.all_windows()
    if #windows > 1 then
      local window_index = index_of(windows, mux_window:window_id(), function(w) return w:window_id() end)
      table.insert(parts, 'window ' .. window_index)
    end
    local tab_index = index_of(mux_window:tabs(), mux_pane:tab():tab_id(), function(t) return t:tab_id() end)
    table.insert(parts, 'tab ' .. tab_index)
  end)
  table.insert(parts, 'pane ' .. entry.pane_id)
  return table.concat(parts, M.location_separator)
end

--- "wezterm 5052, tab 3, pane 18" for a pane of another instance, from what
-- its hook wrote down.
local function remote_location(entry)
  local parts = { 'wezterm ' .. entry.instance }
  if entry.window and entry.window ~= '1' then
    table.insert(parts, 'window ' .. entry.window)
  end
  if entry.tab then
    table.insert(parts, 'tab ' .. entry.tab)
  end
  table.insert(parts, 'pane ' .. entry.pane_id)
  return table.concat(parts, M.location_separator)
end

--- "gfx (rate_limit, tab 3, pane 18)" for every entry, in a stable order.
local function describe(entries)
  table.sort(entries, function(a, b) return a.name < b.name end)
  local descriptions = {}
  for _, entry in ipairs(entries) do
    local details = {}
    if entry.error then
      table.insert(details, entry.error)
    end
    table.insert(details, entry.mine and live_location(entry) or remote_location(entry))
    table.insert(descriptions, (entry.label or 'claude code') .. ' (' .. table.concat(details, M.location_separator) .. ')')
  end
  return descriptions
end

--- One notification for every session that finished or failed in the same
-- tick, plus this instance's ones that finished earlier and still haven't been
-- visited. status.lua only keeps a single message, so nothing may be left to a
-- second notify() call. Failures lead and turn the whole message into a
-- warning. Shown in this instance's focused window (else its first one); every
-- other instance shows the same news itself, but only the pane's own instance
-- falls back to a toast.
local function announce(fresh, fallback_window)
  local fresh_done, fresh_failed, fresh_names = {}, {}, {}
  local any_mine = false
  for _, entry in ipairs(fresh) do
    fresh_names[entry.name] = true
    any_mine = any_mine or entry.mine
    table.insert(entry.kind == FAILED_EXTENSION and fresh_failed or fresh_done, entry)
  end

  local waiting = {}
  for name, entry in pairs(M.markers) do
    if entry.mine and not fresh_names[name] then
      table.insert(waiting, entry)
    end
  end

  local parts = {}
  if #fresh_failed > 0 then
    table.insert(parts, M.failed_notification_icon .. 'Error in ' .. table.concat(describe(fresh_failed), ', '))
  end
  if #fresh_done > 0 then
    table.insert(parts, M.notification_icon .. 'Finished in ' .. table.concat(describe(fresh_done), ', '))
  end
  if #waiting > 0 then
    table.insert(parts, 'waiting: ' .. table.concat(describe(waiting), ', '))
  end

  local target = target_gui_window()
  if not target then
    local first = fresh[1]
    target = first.mine and gui_window_for_pane(first.pane_id, fallback_window) or fallback_window
  end
  status.notify(target, M.notification_title, table.concat(parts, M.notification_separator),
    #fresh_failed > 0 and 'warning' or true, any_mine, M.notification_timeout_ms)
end

--- Drops the markers for a pane of this instance, in memory and on disk.
function M.clear(pane_id)
  for name, entry in pairs(M.markers) do
    if entry.mine and entry.pane_id == pane_id then
      M.markers[name] = nil
      os.remove(entry.path)
    end
  end
end

--- Picks up new markers into M.markers, returning the fresh ones.
local function scan()
  local fresh, present = {}, {}
  for _, kind in ipairs({ DONE_EXTENSION, FAILED_EXTENSION }) do
    local ok, files = pcall(wezterm.glob, M.state_dir .. '/*.' .. kind)
    if ok and files then
      for _, path in ipairs(files) do
        local name = (path:gsub('\\', '/')):match('([^/]+)$')
        local instance, pane = name:match('^(%d+)%-(%d+)%.' .. kind .. '$')
        local pane_id = tonumber(pane)
        if pane_id then
          present[name] = true
          if M.markers[name] == nil then
            local fields = read_marker(path)
            local entry = {
              name = name,
              path = path,
              kind = kind,
              label = fields.label,
              error = kind == FAILED_EXTENSION and (fields.error or 'unknown') or nil,
              instance = instance,
              pane_id = pane_id,
              window = fields.window,
              tab = fields.tab,
              mine = is_mine(instance, pane_id),
            }
            M.markers[name] = entry

            if entry.mine and not mux_pane_exists(pane_id) then
              -- Our pane is gone (closed before the marker was seen); tidy up
              M.markers[name] = nil
              os.remove(path)
              present[name] = nil
            else
              table.insert(fresh, entry)
            end
          end
        end
      end
    end
  end

  -- Markers removed behind our back, e.g. by the UserPromptSubmit hook or by
  -- the instance they belong to
  for name in pairs(M.markers) do
    if not present[name] then
      M.markers[name] = nil
    end
  end
  return fresh
end

--- Picks up new markers, notifies about them, and clears the ones whose tab the
-- user is now looking at. Call from "update-right-status".
function M.poll(window, pane)
  if not M.enabled then
    return
  end

  -- Several sessions can finish within the same tick; collect them all
  local fresh = scan()
  if #fresh > 0 then
    announce(fresh, window)
  end

  if next(M.markers) == nil or not window_is_focused(window) then
    return
  end

  -- The user is looking at this window; clear every marker in the active tab
  local tab_ok, tab = pcall(function() return pane:tab() end)
  if not tab_ok or not tab then
    return
  end

  local panes_ok, panes = pcall(function() return tab:panes() end)
  if not panes_ok or not panes then
    return
  end

  for _, tab_pane in ipairs(panes) do
    M.clear(tab_pane:pane_id())
  end
end

--- The icon to prefix to a tab title and its color (nil for the tab's own), or
-- nil. Only markers of this instance count, and a failed pane wins over a
-- finished one. Call from "format-tab-title" with the TabInformation object.
function M.tab_icon(tab)
  if not M.enabled or next(M.markers) == nil then
    return nil
  end
  local in_tab = {}
  for _, pane_info in ipairs(tab.panes or {}) do
    in_tab[pane_info.pane_id] = true
  end
  local icon = nil
  for _, entry in pairs(M.markers) do
    if entry.mine and in_tab[entry.pane_id] then
      if entry.kind == FAILED_EXTENSION then
        return M.failed_icon, M.failed_icon_color
      end
      icon = M.icon
    end
  end
  return icon
end

return M
