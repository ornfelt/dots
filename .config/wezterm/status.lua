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

local wezterm = require 'wezterm'

local M = {}

-- Hard-coded switch: set to false to use the default toast notifications
M.enabled = true

-- How long a finished (success/failure) message stays on the status line
M.timeout_ms = 3000
-- Timeout used when falling back to toast notifications
M.toast_timeout_ms = 4000

-- The status line is part of the tab bar, so it is invisible while the tab bar
-- is hidden. Kept in sync with config.hide_tab_bar_if_only_one_tab from
-- wezterm.lua; when the bar is hidden we fall back to a toast instead.
M.tab_bar_hidden_with_single_tab = true

-- Drawn between the message and the regular right status content
M.separator = '  '

M.colors = {
  progress = '#83a598',
  success  = '#98971a',
  failure  = '#cc241d',
}

M.prefix = {
  progress = '',
  success  = '✓ ',
  failure  = '✗ ',
}

-- Current message: { text = ..., color = ..., expires_at = ..., window_id = ... }
local current = nil
-- Last regular right status content per window, so progress()/notify() can
-- repaint immediately without waiting for the next update-right-status tick.
local last_tail = {}

local function status_line_visible(window)
  if not M.tab_bar_hidden_with_single_tab then
    return true
  end
  local ok, tabs = pcall(function() return window:mux_window():tabs() end)
  return ok and tabs ~= nil and #tabs > 1
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
  if not M.enabled or not status_line_visible(window) then
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
-- @param ok boolean: true for success, false for failure
function M.notify(window, title, message, ok)
  if not M.enabled or not status_line_visible(window) then
    if current then
      current = nil
      redraw(window)
    end
    window:toast_notification(title, message, nil, M.toast_timeout_ms)
    return
  end

  current = {
    text = (ok and M.prefix.success or M.prefix.failure) .. message,
    color = ok and M.colors.success or M.colors.failure,
    expires_at = os.time() + math.max(1, math.ceil(M.timeout_ms / 1000)),
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

  if not M.enabled or (current and current.window_id ~= window:window_id()) then
    window:set_right_status(wezterm.format(tail))
    return
  end

  window:set_right_status(wezterm.format(compose(tail)))
end

return M
