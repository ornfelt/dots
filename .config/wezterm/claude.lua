-- Claude Code integration: shows a robot icon on the tab that contains a Claude
-- Code pane whose response has finished, and clears it again once that tab is
-- visited. Also raises a status.notify() when a response finishes.
--
-- How the pane is identified:
--   Claude Code inherits WEZTERM_PANE from the shell it was started in, so the
--   "Stop" hook knows which wezterm pane it belongs to. It writes
--       <state_dir>/<WEZTERM_PANE>.done      (contents: a short label)
--   and the "UserPromptSubmit" hook removes that file again. See
--   ~/.claude/hooks/wezterm-claude-status.{ps1,sh}.
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
--   claude.tab_icon(tab)        -- from the "format-tab-title" event

local wezterm = require 'wezterm' --[[@as Wezterm]]
local status = require 'status'

local M = {}

-- Hard-coded switch: set to false to disable the tab marker and notification
M.enabled = true

-- Prefixed to the title of tabs with a finished, unvisited response.
-- Nerd font alternatives: '󰚩 ' (nf-md-robot), '🤖 ', '● '
M.icon = '🤖 '
-- Columns reserved for the icon when truncating the tab title
M.icon_width = 2

M.notification_title = 'Claude Code'
-- Prefixed to the notification text. Both the status line and the toast
-- fallback take plain text, so a glyph/emoji is the only icon either can show.
M.notification_icon = M.icon
-- Between the sessions that just finished and the ones still waiting
M.notification_separator = '  ·  '

local home = (os.getenv('HOME') or os.getenv('USERPROFILE') or '.'):gsub('\\', '/')
-- Kept in sync with the hook scripts in ~/.claude/hooks/
M.state_dir = home .. '/.wezterm/claude-status'

-- pane_id -> { path = ..., label = ... } for finished, unvisited responses
M.done = {}

--- Reads the short label (usually the project directory name) from a marker.
local function read_label(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  local line = file:read('*line')
  file:close()
  if not line then
    return nil
  end
  -- Strip a UTF-8 BOM and trailing whitespace
  line = line:gsub('^\239\187\191', ''):gsub('%s+$', '')
  return line ~= '' and line or nil
end

local function mux_pane_exists(pane_id)
  local ok, mux_pane = pcall(wezterm.mux.get_pane, pane_id)
  return ok and mux_pane ~= nil
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

--- The gui window the user is currently looking at, if any.
local function focused_gui_window()
  local ok, windows = pcall(function() return wezterm.gui.gui_windows() end)
  if not ok or not windows then
    return nil
  end
  for _, window in ipairs(windows) do
    if window_is_focused(window) then
      return window
    end
  end
  return nil
end

--- Turns { pane_id = ..., label = ... } entries into a de-duplicated, stable
-- list of labels for the notification text.
local function label_list(entries)
  table.sort(entries, function(a, b) return a.pane_id < b.pane_id end)

  local labels, seen = {}, {}
  for _, entry in ipairs(entries) do
    local label = entry.label or ('pane ' .. entry.pane_id)
    if not seen[label] then
      seen[label] = true
      table.insert(labels, label)
    end
  end
  return labels
end

--- One notification for every session that finished in the same tick, plus the
-- ones that finished earlier and still haven't been visited. status.lua only
-- keeps a single message, so nothing may be left to a second notify() call.
local function announce(fresh, fallback_window)
  local fresh_ids = {}
  for _, entry in ipairs(fresh) do
    fresh_ids[entry.pane_id] = true
  end

  local waiting = {}
  for pane_id, entry in pairs(M.done) do
    if not fresh_ids[pane_id] then
      table.insert(waiting, { pane_id = pane_id, label = entry.label })
    end
  end

  local message = M.notification_icon .. 'Finished in ' .. table.concat(label_list(fresh), ', ')

  local waiting_labels = label_list(waiting)
  if #waiting_labels > 0 then
    message = message .. M.notification_separator .. 'waiting: ' .. table.concat(waiting_labels, ', ')
  end

  -- Prefer the window the user is actually looking at; the message names every
  -- project, so it is useful there even when the pane lives somewhere else
  local target = focused_gui_window() or gui_window_for_pane(fresh[1].pane_id, fallback_window)
  status.notify(target, M.notification_title, message, true)
end

--- Drops the marker for a pane, in memory and on disk.
function M.clear(pane_id)
  local entry = M.done[pane_id]
  if not entry then
    return
  end
  M.done[pane_id] = nil
  if entry.path then
    os.remove(entry.path)
  end
end

--- Picks up new markers, notifies about them, and clears the ones whose tab the
-- user is now looking at. Call from "update-right-status".
function M.poll(window, pane)
  if not M.enabled then
    return
  end

  local ok, files = pcall(wezterm.glob, M.state_dir .. '/*.done')
  if not ok or not files then
    return
  end

  local present = {}
  -- Several sessions can finish within the same tick; collect them all
  local fresh = {}

  for _, path in ipairs(files) do
    local pane_id = tonumber((path:gsub('\\', '/')):match('([0-9]+)%.done$'))
    if pane_id then
      present[pane_id] = true
      if M.done[pane_id] == nil then
        local label = read_label(path)
        M.done[pane_id] = { path = path, label = label }

        if not mux_pane_exists(pane_id) then
          -- Pane is gone (closed before the marker was seen); just tidy up
          M.clear(pane_id)
          present[pane_id] = nil
        else
          table.insert(fresh, { pane_id = pane_id, label = label })
        end
      end
    end
  end

  -- Markers removed behind our back, e.g. by the UserPromptSubmit hook
  for pane_id in pairs(M.done) do
    if not present[pane_id] then
      M.done[pane_id] = nil
    end
  end

  if #fresh > 0 then
    announce(fresh, window)
  end

  if next(M.done) == nil or not window_is_focused(window) then
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

--- The icon to prefix to a tab title, or nil. Call from "format-tab-title"
-- with the TabInformation object.
function M.tab_icon(tab)
  if not M.enabled or next(M.done) == nil then
    return nil
  end
  for _, pane_info in ipairs(tab.panes or {}) do
    if M.done[pane_info.pane_id] then
      return M.icon
    end
  end
  return nil
end

return M
