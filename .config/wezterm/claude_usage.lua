-- Claude Code subscription usage on the status line: the same text the awesome
-- bar widget draws (~/.config/awesome/claude_usage, "bare" style, see
-- themes/multicolor/theme.lua there):
--
--   ✻ 5h 6% · 7d 92% · F 99% +30.19€ ⚑
--
-- the 5 hour window, the 7 day window, every per model weekly limit (first
-- letter of the model), the extra usage spent (off by default, like
-- claude_show_spend in awesome) and a flag while a Claude Code session waits
-- for a permission or an answer. Claude orange, red from 90 % on, grey for an
-- error without data (!429, !auth, !net, ...).
--
-- The numbers come from the background worker (scripts/bg/wez_bg_tasks.py,
-- job 5), which fetches them off the gui thread every 5 minutes and soon after
-- every finished response, and hands them over in the state file bg_status.lua
-- already reads. Nothing here touches the network.
--
-- Toggle:
--   on by default (M.enabled). leader-c flips it at runtime and remembers the
--   choice in M.toggle_file, which then wins over M.enabled; delete that file to
--   go back to M.enabled. While it is on, the status tick keeps M.request_file
--   fresh, and the worker only fetches while that file is fresh - so toggled
--   off (or every wezterm closed) means no request at all. On a host
--   M.disabled_hostname_parts names it stays off whatever the toggle says.
--
-- Needs the worker, i.e. bg_status.enabled. On linux the usage is off until
-- leader-c turns it on (M.enabled_on_linux), and the worker's job waits for
-- that same toggle (CLAUDE_USAGE_ON_LINUX in wez_bg_tasks.py).
--
-- Usage from wezterm.lua:
--   claude_usage.poll(window)       -- from "update-right-status"
--   claude_usage.segments()         -- segments for set_right_status
--   claude_usage.toggle(window)     -- from a key binding

local wezterm = require 'wezterm' --[[@as Wezterm]]
local bg_status = require 'bg_status'
local status = require 'status'

local M = {}

-- Hard-coded default: show (and fetch) the usage. Only used while there is no
-- M.toggle_file, i.e. until leader-c is pressed the first time.
M.enabled = true

-- The same default on linux, where it is off for now. leader-c still turns it
-- on (the toggle file wins over both), and wez_bg_tasks.py only fetches on
-- linux while the toggle file says "on".
M.enabled_on_linux = false

-- Hosts the usage stays off on, whatever M.enabled and the toggle file say: a
-- windows computer name (%COMPUTERNAME%) containing one of these, case
-- insensitive. Same list as CLAUDE_USAGE_DISABLED_HOSTNAME_PARTS in
-- scripts/bg/wez_bg_tasks.py.
M.disabled_hostname_parts = { 'devpc' }

-- Append the extra usage spent (" +30.19€") while there is any. Same switch as
-- claude_show_spend in awesome's theme.lua, and off there too.
M.show_spend = false
-- Fixed marker instead of the amount, e.g. ' €'; nil shows the amount
M.spend_flag = nil

-- Append M.attention_flag while a Claude Code session waits for a permission
-- or an answer (awesome: sessions_in_bar)
M.show_attention = true
M.attention_flag = ' ⚑' -- U+2691, same as awesome

-- Windows in the bar, in order: 'five_hour', 'seven_day', 'scoped' (every per
-- model limit) or 'scoped:<Model>' (just that one). Same as awesome's default.
M.bar_windows = { 'five_hour', 'seven_day', 'scoped' }
M.window_separator = ' · '

-- Awesome draws a starburst; ✻ (U+273B) is the one Claude Code spins itself
M.icon = '✻'
M.icon_gap = ' '
-- Drawn between this module's output and the rest of the right status
M.separator = '  '

-- Percentages from which the text turns warn / crit colored (highest window)
M.thresholds = { warn = 75, crit = 90 }

-- Claude orange, about 8 % darker than the awesome config's
local CLAUDE_ORANGE = '#C86D50'
-- local CLAUDE_ORANGE = '#D97757' -- the awesome config's (linux dotfiles)

-- Same as the awesome config: warn is the normal orange there as well, so the
-- text always matches the icon until it goes red
M.colors = {
  icon   = CLAUDE_ORANGE,
  normal = CLAUDE_ORANGE,
  warn   = CLAUDE_ORANGE,
  crit   = '#C8442E',
  error  = '#9C9A93',
}

M.notification_title = 'Claude usage'

local home = (os.getenv('HOME') or os.getenv('USERPROFILE') or '.'):gsub('\\', '/')

-- "on" / "off", written by M.toggle
M.toggle_file = home .. '/.wezterm/claude-usage.toggle'
-- Touched while the usage is on; keep in sync with CLAUDE_USAGE_REQUEST_FILE
-- in wez_bg_tasks.py, which stops fetching once it is older than
-- CLAUDE_USAGE_REQUEST_MAX_AGE_SECONDS (60)
M.request_file = home .. '/.wezterm/claude-usage.request'
M.request_every_seconds = 10

-- The status event fires about once a second per window, and every wezterm
-- instance reads the toggle file; once a second is plenty
M.cache_seconds = 1

-- wezterm only watches the main config file, not the modules it requires
pcall(function()
  wezterm.add_to_config_reload_watch_list(debug.getinfo(1, 'S').source:sub(2))
end)

-- ---------------------------------------------------------------------------
-- Toggle
-- ---------------------------------------------------------------------------

local toggle_cache = { value = nil, read_at = 0 }
local last_request = 0

--- true / false from the toggle file, nil when there is none
local function read_toggle()
  local file = io.open(M.toggle_file, 'r')
  if not file then
    return nil
  end
  local contents = (file:read('*a') or ''):gsub('%s', ''):lower()
  file:close()
  if contents == 'on' then
    return true
  elseif contents == 'off' then
    return false
  end
  return nil
end

local is_windows = wezterm.target_triple:find('windows') ~= nil

--- true on a host M.disabled_hostname_parts matches (windows only)
local function host_disabled()
  if not is_windows then
    return false
  end
  local name = (os.getenv('COMPUTERNAME') or ''):lower()
  for _, part in ipairs(M.disabled_hostname_parts) do
    if name:find(part:lower(), 1, true) then
      return true
    end
  end
  return false
end

--- Whether the usage is shown (and fetched) right now.
function M.is_enabled()
  if host_disabled() then
    return false
  end
  local now = os.time()
  if now - toggle_cache.read_at >= M.cache_seconds then
    toggle_cache.read_at = now
    toggle_cache.value = read_toggle()
  end
  if toggle_cache.value == nil then
    if not is_windows then
      return M.enabled_on_linux
    end
    return M.enabled
  end
  return toggle_cache.value
end

local function write_file(path, contents)
  local file = io.open(path, 'w')
  if not file then
    return false
  end
  file:write(contents)
  file:close()
  return true
end

local function touch_request(now)
  last_request = now
  if not write_file(M.request_file, tostring(now)) then
    wezterm.log_error('claude_usage: cannot write ' .. M.request_file)
  end
end

--- Flips the toggle and remembers it. Turning it off removes the request file
-- straight away, so the worker stops on its next tick instead of after
-- CLAUDE_USAGE_REQUEST_MAX_AGE_SECONDS (unless another wezterm instance still
-- has it on, which touches it again).
function M.toggle(window)
  if host_disabled() then
    status.notify(window, M.notification_title,
      'Claude usage is off on this host (' .. (os.getenv('COMPUTERNAME') or '?') .. ')',
      'warning')
    return
  end
  local enabled = not M.is_enabled()
  if not write_file(M.toggle_file, enabled and 'on' or 'off') then
    status.notify(window, M.notification_title, 'Cannot write ' .. M.toggle_file, false)
    return
  end
  toggle_cache.value = enabled
  toggle_cache.read_at = os.time()

  if not enabled then
    os.remove(M.request_file)
    status.notify(window, M.notification_title, 'Claude usage off', true)
    return
  end

  if not bg_status.enabled then
    status.notify(window, M.notification_title,
      'Claude usage on, but the worker is off (' .. bg_status.linux_env_switch .. ')',
      'warning')
    return
  end
  touch_request(os.time())
  status.notify(window, M.notification_title, 'Claude usage on', true)
end

--- Keeps the request file fresh while the usage is on. Call from the status
-- tick; rate limited, so every window may call it.
function M.poll(_window)
  if not bg_status.enabled or not M.is_enabled() then
    return
  end
  local now = os.time()
  if now - last_request >= M.request_every_seconds then
    touch_request(now)
  end
end

-- ---------------------------------------------------------------------------
-- Text, a port of bar_text / color_for in claude_usage/format.lua
-- ---------------------------------------------------------------------------

local SHORT_ERROR = {
  unauthorized = '!auth',
  no_credentials = '!cred',
  rate_limited = '!429',
  network = '!net',
  parse = '!parse',
}

local function round(x)
  return math.floor(x + 0.5)
end

local function is_window(w)
  return type(w) == 'table' and type(w.percent) == 'number'
end

local function scoped_of(usage)
  return type(usage.scoped) == 'table' and usage.scoped or {}
end

local function has_data(usage)
  return is_window(usage.five_hour) or is_window(usage.seven_day) or #scoped_of(usage) > 0
end

local function pct_text(w)
  if is_window(w) then
    return string.format('%d%%', round(w.percent))
  end
  return '--'
end

--- First character of a model name, to keep the bar short ("Fable" -> "F")
local function short_name(name)
  name = tostring(name)
  return name:match('^' .. utf8.charpattern) or name
end

local function find_scoped(usage, name)
  for _, w in ipairs(scoped_of(usage)) do
    if w.name == name then
      return w
    end
  end
  return nil
end

local function money(amount, currency)
  if currency == 'USD' then
    return string.format('$%.2f', amount)
  elseif currency == 'EUR' then
    return string.format('%.2f€', amount)
  end
  return string.format('%.2f%s', amount, currency or '')
end

local function max_percent(usage)
  local best = nil
  local function consider(w)
    if is_window(w) and (best == nil or w.percent > best) then
      best = w.percent
    end
  end
  consider(usage.five_hour)
  consider(usage.seven_day)
  for _, w in ipairs(scoped_of(usage)) do
    consider(w)
  end
  return best
end

--- The bar text for the worker's claude_usage block.
function M.bar_text(usage)
  if not has_data(usage) then
    if type(usage.error) == 'table' then
      return SHORT_ERROR[usage.error.code] or '!err'
    end
    -- Nothing fetched yet
    return usage.fetched_at == nil and '…' or '--'
  end

  local parts = {}
  for _, key in ipairs(M.bar_windows) do
    if key == 'scoped' then
      for _, w in ipairs(scoped_of(usage)) do
        table.insert(parts, short_name(w.name) .. ' ' .. pct_text(w))
      end
    elseif key == 'five_hour' then
      table.insert(parts, '5h ' .. pct_text(usage.five_hour))
    elseif key == 'seven_day' then
      table.insert(parts, '7d ' .. pct_text(usage.seven_day))
    else
      local name = key:match('^scoped:(.+)$')
      if name then
        table.insert(parts, short_name(name) .. ' ' .. pct_text(find_scoped(usage, name)))
      end
    end
  end
  local text = table.concat(parts, M.window_separator)

  local spend = type(usage.spend) == 'table' and usage.spend or nil
  local used = spend and tonumber(spend.used) or 0
  local percent = spend and tonumber(spend.percent) or 0
  if M.show_spend and spend and spend.enabled and (percent > 0 or used > 0) then
    local amount = used > 0 and money(used, spend.currency)
        or string.format('%d%%', round(percent))
    text = text .. (M.spend_flag or (' +' .. amount))
  end

  if M.show_attention and (tonumber(usage.attention) or 0) > 0 then
    text = text .. M.attention_flag
  end
  return text
end

--- Text color: error without data > crit > warn > normal
function M.color_for(usage)
  if not has_data(usage) then
    return type(usage.error) == 'table' and M.colors.error or M.colors.normal
  end
  local pct = max_percent(usage) or 0
  if pct >= M.thresholds.crit then
    return M.colors.crit
  elseif pct >= M.thresholds.warn then
    return M.colors.warn
  end
  return M.colors.normal
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

--- Segments to put in front of the worker's icons, possibly empty.
function M.segments()
  if not bg_status.enabled or not M.is_enabled() then
    return {}
  end
  -- Worker not running or not answering: say nothing, like bg_status
  local state = bg_status.current_state()
  if not state then
    return {}
  end

  local usage = state.claude_usage
  local text, color
  if type(usage) ~= 'table' or not usage.enabled then
    -- Just toggled on; the worker has not picked up the request file yet
    text, color = '…', M.colors.normal
  else
    text, color = M.bar_text(usage), M.color_for(usage)
  end

  return {
    { Foreground = { Color = M.colors.icon } },
    { Text = M.icon .. M.icon_gap },
    { Foreground = { Color = color } },
    { Text = text },
    'ResetAttributes',
    { Text = M.separator },
  }
end

return M
