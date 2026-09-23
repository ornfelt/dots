-- Small helper for showing transient status messages in the tab bar, drawn to
-- the left of the regular right-status content, instead of using toasts.
--
-- Usage:
--   status.progress(window, "Saving session...")            -- no timeout
--   status.notify(window, "WezTerm", "Saved", true)         -- success/failure
--
-- status.render(window, segments) must be called from the "update-right-status"
-- event instead of window:set_right_status(); that event fires roughly once a
-- second, which is what expires messages.

local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

-- Hard-coded switch: set to false to use the default toast notifications
M.enabled = true

-- How long a finished (success/failure) message stays on the status line
M.timeout_ms = 3000
-- Timeout used when falling back to toast notifications
M.toast_timeout_ms = 4000

-- The status line is part of the tab bar, so it is invisible while the tab bar
-- is hidden. Kept in sync with config.hide_tab_bar_if_only_one_tab from
-- wezterm.lua; when the bar is hidden we show it for as long as the message
-- lasts (see M.show_tab_bar_for_messages), or fall back to a toast.
M.tab_bar_hidden_with_single_tab = true

-- Show the tab bar, and with it the status line, while a message is up in a
-- window that would otherwise hide it. Without this a single-tab window can
-- only fall back to a toast, and a toast is dropped without a trace when
-- windows notifications are turned off - so nothing at all is reported.
M.show_tab_bar_for_messages = true

-- Drawn between the message and the regular right status content
M.separator = '  '

M.colors = {
  progress = '#83a598',
  success  = '#98971a',
  failure  = '#cc241d',
  warning  = '#fe8019',
}

M.prefix = {
  progress = '',
  success  = '✓ ',
  failure  = '✗ ',
  warning  = '⚠ ',
}

-- Current message: { text = ..., color = ..., expires_at = ..., window_id = ... }
local current = nil
-- Last regular right status content per window, so progress()/notify() can
-- repaint immediately without waiting for the next update-right-status tick.
local last_tail = {}

--- True when a message would be drawn on the status line rather than raised as
-- a toast. Callers can use it to pick plain text over glyphs, since a toast is
-- rendered by the desktop notification daemon and has no access to wezterm's
-- font fallback (nerd font glyphs come out as tofu there).
function M.visible(window)
  if not M.enabled then
    return false
  end
  if not M.tab_bar_hidden_with_single_tab then
    return true
  end
  local ok, tabs = pcall(function() return window:mux_window():tabs() end)
  return ok and tabs ~= nil and #tabs > 1
end

-- Windows whose tab bar we turned on to make room for a message
local forced_tab_bar = {}

--- Turns the tab bar on (hide = false) or hands it back to the config (nil).
local function override_tab_bar(window, hide)
  local ok, overrides = pcall(function() return window:get_config_overrides() end)
  overrides = (ok and overrides) or {}
  overrides.hide_tab_bar_if_only_one_tab = hide
  pcall(function() window:set_config_overrides(overrides) end)
end

--- Makes the status line available in a window that hides its tab bar.
local function claim_status_line(window)
  if not M.show_tab_bar_for_messages then
    return false
  end
  local id = window:window_id()
  if not forced_tab_bar[id] then
    forced_tab_bar[id] = true
    override_tab_bar(window, false)
  end
  return true
end

--- Gives the tab bar back once the message it was shown for is gone.
local function release_status_line(window)
  local id = window:window_id()
  if forced_tab_bar[id] then
    forced_tab_bar[id] = nil
    override_tab_bar(window, nil)
  end
end

--- Prepends the current message to the regular right status segments.
local function compose(tail)
  local segments = {}

  if current then
    table.insert(segments, { Foreground = { Color = current.color } })
    table.insert(segments, { Text = current.text })
    table.insert(segments, 'ResetAttributes')
    table.insert(segments, { Text = M.separator })
  end

  for _, segment in ipairs(tail or {}) do
    table.insert(segments, segment)
  end

  return segments
end

local function redraw(window)
  window:set_right_status(wezterm.format(compose(last_tail[window:window_id()])))
end

--- Shows a message while an operation is running (stays until notify/render).
function M.progress(window, message)
  if not M.visible(window) and not claim_status_line(window) then
    return
  end
  current = {
    text = M.prefix.progress .. message,
    color = M.colors.progress,
    expires_at = nil,
    window_id = window:window_id(),
  }
  redraw(window)
end

--- Shows the result of an operation; falls back to a toast when disabled.
-- @param ok boolean|string: true for success, false for failure, 'warning' for
-- something that went wrong outside wezterm (drawn in the warning color)
-- @param toast boolean|nil: false skips the toast fallback, for a message that
-- another wezterm instance already raises one for
-- @param timeout_ms number|nil: how long the status line message stays,
-- defaults to M.timeout_ms
function M.notify(window, title, message, ok, toast, timeout_ms)
  if not M.visible(window) and not claim_status_line(window) then
    if current then
      current = nil
      redraw(window)
    end
    if toast ~= false then
      window:toast_notification(title, message, nil, M.toast_timeout_ms)
    end
    return
  end

  local kind = ok == 'warning' and 'warning' or (ok and 'success' or 'failure')
  current = {
    text = M.prefix[kind] .. message,
    color = M.colors[kind],
    expires_at = os.time() + math.max(1, math.ceil((timeout_ms or M.timeout_ms) / 1000)),
    window_id = window:window_id(),
  }
  redraw(window)
end

--- Sets the right status, with any pending message in front of it, and expires
-- finished messages. Call from "update-right-status" with the segments you
-- would otherwise have passed to window:set_right_status().
function M.render(window, tail)
  tail = tail or {}
  last_tail[window:window_id()] = tail

  if current and current.expires_at and os.time() >= current.expires_at then
    current = nil
  end

  if not current then
    release_status_line(window)
  end

  if not M.enabled or (current and current.window_id ~= window:window_id()) then
    window:set_right_status(wezterm.format(tail))
    return
  end

  window:set_right_status(wezterm.format(compose(tail)))
end

return M
