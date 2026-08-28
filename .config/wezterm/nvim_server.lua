-- Headless Neovim servers for wezterm panes.
--
-- Starting nvim with a full config costs ~2.4s on this machine, while attaching
-- a UI to an already running headless server costs ~60ms. This module keeps
-- such servers around so the `vims`/`nvims` shell aliases can attach to one
-- instead of paying for a cold start every time.
--
-- Two modes, both off by default:
--
--   pane mode (M.use_pool = false)
--     One server per wezterm pane, named after this wezterm instance and the
--     pane id, so several wezterm instances never touch each other's servers.
--
--   pool mode (M.use_pool = true)
--     A pool of anonymous servers that outlive panes, tabs and wezterm itself.
--     `vims` leases a free one and hands it back when the editor exits, so
--     there is no pane/server mapping to keep in sync and the background job
--     below turns itself off.
--
-- Why there is a background job at all:
--   wezterm has no pane-closed, tab-closed or quit event (the event table in
--   wezterm-gui only holds gui-startup, gui-attached, window-config-reloaded,
--   window-focus-changed, window-resized, pane-focus-changed, pane-mode-changed,
--   user-var-changed, bell, open-uri, the format-* hooks and
--   augment-command-palette). Panes also die from `exit`, Ctrl-D, the window
--   close button and crashes, and are created by default bindings such as
--   CTRL+SHIFT+T, none of which a keybind can observe. The keybind hooks below
--   only keep latency down; the job is what actually keeps things in sync.
--
-- The shell side needs no configuration of its own: M.env() hands the mode,
-- the instance tag and the state directory to every pane wezterm spawns.
--
-- Usage from wezterm.lua:
--   config.set_environment_variables = nvim_server.env()
--   nvim_server.poll(window)                 -- from "update-right-status"
--   nvim_server.on_new_pane(action)          -- wraps a split/spawn-tab action
--   nvim_server.on_close_pane(action)        -- wraps a close-pane action
--   nvim_server.on_close_tab(action)         -- wraps a close-tab action
--   nvim_server.on_quit(action)              -- wraps QuitApplication
--   nvim_server.panes_added(window)          -- from a hand written callback
--   nvim_server.sync_now(window)             -- the manual trigger keybind
--   nvim_server.report(window)               -- read-only dump, changes nothing

local wezterm = require 'wezterm' --[[@as Wezterm]]
local status = require 'status'

local M = {}

local is_windows = wezterm.target_triple:find('windows') ~= nil

-- Hard-coded switch: nothing in this module does anything unless this is true
M.enabled = true

-- Forced off on linux, whatever the switch above says: the shell side that
-- actually attaches to a server is the `vim` function in the PowerShell
-- profile, so servers would be started here and then never used.
--if not is_windows then
--  M.enabled = false
--end

-- One switch for all three sides. WEZ_NVIM_SERVERS overrides everything above,
-- and the same variable is read by the `vim` function in the PowerShell
-- profile and in .zshrc, so servers can be turned on or off from one place
-- instead of three. Unset means "use the hard-coded switches"; 0/off/false/no
-- (any case) means off, anything else means on.
--
-- Set it where the whole session sees it, not in a shell rc: on Windows as a
-- user environment variable (setx WEZ_NVIM_SERVERS 0, then restart wezterm),
-- on linux in ~/.zshenv or ~/.profile - wezterm is started by the desktop and
-- never sources ~/.zshrc, so a value set there would reach the shell but not
-- this module.
M.env_switch = 'WEZ_NVIM_SERVERS'

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

local override = env_bool(M.env_switch)
if override ~= nil then
  M.enabled = override
end

-- Hard-coded switch: share a pool of long-lived servers instead of mapping one
-- server to each pane. Pool servers are never killed automatically; they stay
-- around when a pane, tab or the whole wezterm instance goes away.
M.use_pool = true

-- Hard-coded switch: run the reconciling background job. Ignored in pool mode,
-- where there is nothing to reconcile.
M.job_enabled = false

-- How often the background job runs, in seconds. Fractions are allowed:
M.job_interval_seconds = 1
--M.job_interval_seconds = 0.5   -- twice a second
--M.job_interval_seconds = 2     -- every other second

-- A server whose pane has disappeared is only killed once it has been missing
-- for this many consecutive ticks, so one bad mux read cannot kill a server
-- that is being edited in.
M.orphan_grace_ticks = 3

-- Servers delete their own pid file on exit, so that file is normally enough
-- to tell what is running. Confirming a pid against the process table costs a
-- syscall each, so it only happens every Nth tick (1 = every tick, 0 = never).
-- The manual trigger always verifies.
M.verify_pids_every_ticks = 5

-- How many warm servers to put in the pool at wezterm startup (pool mode only).
-- This is a one-off prefill, and it is what the pool costs while idle: every
-- one of them is a fully loaded nvim sitting around (~40MB here).
M.pool_size = 5

-- Low water mark. `vim` only starts a replacement once claiming a server would
-- leave this many or fewer free, instead of topping straight back up to
-- pool_size. That keeps a spare ready without spawning an nvim on every single
-- edit; if the pool does run dry, `vim` starts one and waits for it.
M.pool_min_free = 2

-- Also log every background tick, not just the manual trigger
M.log_background_ticks = false

-- How long to give a pool prefill batch to appear before allowing another
-- attempt. Prevents repeated status ticks from spawning duplicate batches.
M.pool_prefill_timeout_seconds = 8

-- Hard-coded switch: prefill the pool once per wezterm instance and never
-- again while it runs. The prefill is driven by "update-right-status", so
-- without this every tick that finds fewer than pool_size servers starts
-- replacements, and killing the pool by hand (kill_nvim_servers) refills it
-- within a second. Off: the pool is topped back up whenever it runs short.
-- Either way `vim` still replaces the server it claims (see pool_min_free).
M.prefill_once = true

-- wezterm only watches the main config file for changes, not the modules it
-- requires, so without this the switches above would need a restart (or a
-- touch of ~/.wezterm.lua) before they took effect.
pcall(function()
  wezterm.add_to_config_reload_watch_list(debug.getinfo(1, 'S').source:sub(2))
end)

local home = (os.getenv('HOME') or os.getenv('USERPROFILE') or '.'):gsub('\\', '/')

-- Holds one <name>.pid per server, plus the <name>.lease files that `vim`
-- uses to claim a pool server. Kept next to ~/.wezterm/claude-status.
M.state_dir = home .. '/.wezterm/nvim-servers'
M.log_file = home .. '/wez_nvim_log.txt'

M.notification_title = 'nvim servers'

local POOL_PREFIX = 'nvim-wez-pool-'
local NAME_PREFIX = 'nvim-wez-'

-- ---------------------------------------------------------------------------
-- Identity and paths
-- ---------------------------------------------------------------------------

--- A tag that is unique per wezterm instance and stable across config reloads.
-- The gui pid is preferred because reap_orphaned_instances() can then tell
-- whether the instance a leftover server belongs to is still running.
local function instance_id()
  local id = wezterm.GLOBAL.nvim_server_instance
  if id then
    return id
  end

  local ok, pid = pcall(function() return wezterm.procinfo.pid() end)
  if ok and type(pid) == 'number' then
    id = tostring(pid)
  else
    -- Every pane gets WEZTERM_UNIX_SOCKET=<runtime dir>/gui-sock-<pid>
    local sock = os.getenv('WEZTERM_UNIX_SOCKET')
    id = sock and sock:match('gui%-sock%-(%d+)') or nil
  end

  if not id then
    -- Not a pid, so reap_orphaned_instances() leaves these servers alone
    id = 'x' .. tostring(os.time()) .. (tostring({}):match('0x(%x+)') or '0')
  end

  wezterm.GLOBAL.nvim_server_instance = id
  return id
end

local function pane_server_name(pane_id)
  return NAME_PREFIX .. instance_id() .. '-' .. tostring(pane_id)
end

local function pool_server_name()
  local seq = (wezterm.GLOBAL.nvim_server_pool_seq or 0) + 1
  wezterm.GLOBAL.nvim_server_pool_seq = seq
  return POOL_PREFIX .. instance_id() .. '-' .. tostring(seq)
end

--- Windows uses a named pipe, everything else a socket in the state directory.
local function address_for(name)
  if is_windows then
    return '\\\\.\\pipe\\' .. name
  end
  return M.state_dir .. '/' .. name .. '.sock'
end

local function pid_path(name)
  return M.state_dir .. '/' .. name .. '.pid'
end

--- Splits a server name back into what it is for; nil for anything else.
local function parse_name(name)
  if name:sub(1, #POOL_PREFIX) == POOL_PREFIX then
    return { kind = 'pool', name = name }
  end
  local instance, pane_id = name:match('^nvim%-wez%-(.-)%-(%d+)$')
  if instance then
    return { kind = 'pane', name = name, instance = instance, pane_id = tonumber(pane_id) }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Logging
-- ---------------------------------------------------------------------------

--- Error handler for xpcall; keeps the stack so a failure in here is
-- diagnosable from the log rather than vanishing into wezterm's dispatcher.
local function traceback(err)
  if debug and debug.traceback then
    return debug.traceback(tostring(err), 2)
  end
  return tostring(err)
end

local function log_lines(lines)
  local file = io.open(M.log_file, 'a')
  if not file then
    wezterm.log_error('nvim_server: failed to open log file: ' .. M.log_file)
    return
  end
  for _, line in ipairs(lines) do
    file:write(line .. '\n')
  end
  file:close()
end

-- ---------------------------------------------------------------------------
-- Process handling
-- ---------------------------------------------------------------------------

local function read_pid(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  local line = file:read('*line')
  file:close()
  return tonumber(line and line:match('%d+'))
end

--- True when pid is a live nvim. The name check guards against pid reuse.
local function nvim_alive(pid)
  if not pid then
    return false
  end
  local ok, info = pcall(wezterm.procinfo.get_info_for_pid, pid)
  if not ok or not info then
    return false
  end
  return ((info.name or ''):lower()):find('nvim', 1, true) ~= nil
end

local function wezterm_alive(pid)
  local ok, info = pcall(wezterm.procinfo.get_info_for_pid, pid)
  if not ok or not info then
    return false
  end
  return ((info.name or ''):lower()):find('wezterm', 1, true) ~= nil
end

--- Whether pids can be checked at all. Without this every pid would look dead,
-- which would wipe the pid files of running servers and reap the servers of
-- other instances that are very much alive. Probed against our own instance,
-- which is by definition running.
local procinfo_ok = nil
local function procinfo_usable()
  if procinfo_ok == nil then
    local self_pid = tonumber(instance_id())
    procinfo_ok = self_pid ~= nil and wezterm_alive(self_pid)
    if not procinfo_ok then
      wezterm.log_error('nvim_server: cannot inspect pids, falling back to pid files only')
    end
  end
  return procinfo_ok
end

--- Starts a headless server. It creates the state directory, records its own
-- pid and removes that file again on exit, which is what lets us find and kill
-- it later without holding on to a child handle.
local function spawn(name)
  local address = address_for(name)
  local pidfile = pid_path(name)

  if not is_windows then
    -- A socket left behind by a crashed server would make --listen fail
    os.remove(address)
  end

  local bootstrap = string.format(
    'lua local d=[[%s]] local p=[[%s]] vim.fn.mkdir(d,[[p]]) ' ..
    'vim.fn.writefile({tostring(vim.fn.getpid())},p) ' ..
    "vim.api.nvim_create_autocmd('VimLeavePre',{callback=function() vim.fn.delete(p) end})",
    M.state_dir, pidfile)

  local ok, err = pcall(wezterm.background_child_process,
    { 'nvim', '--headless', '--listen', address, '--cmd', bootstrap })
  if not ok then
    wezterm.log_error('nvim_server: failed to spawn ' .. name .. ': ' .. tostring(err))
    return false
  end
  return true
end

--- Kills servers by pid in a single child process. The quit path has to be
-- synchronous, because wezterm is about to go away.
local function kill_servers(servers, synchronous)
  local argv
  if is_windows then
    argv = { 'taskkill', '/F' }
  else
    argv = { 'kill', '-9' }
  end

  local count = 0
  for _, server in ipairs(servers) do
    if server.pid then
      if is_windows then
        table.insert(argv, '/PID')
      end
      table.insert(argv, tostring(server.pid))
      count = count + 1
    end
    os.remove(pid_path(server.name))
    if not is_windows then
      os.remove(address_for(server.name))
    end
    os.remove(M.state_dir .. '/' .. server.name .. '.lease')
  end

  if count == 0 then
    return
  end

  if synchronous then
    pcall(wezterm.run_child_process, argv)
  else
    pcall(wezterm.background_child_process, argv)
  end
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

--- Everything the state directory currently claims is running.
-- @param verify boolean: also confirm each pid against the process table
-- @param verify boolean: confirm each pid against the process table
-- @param readonly boolean: never delete anything, and keep dead servers in the
--   result with alive=false, so report() can describe them
local function scan_servers(verify, readonly)
  local result = { pane = {}, pool = {}, stale = {} }
  verify = verify and procinfo_usable()

  local ok, files = pcall(wezterm.glob, M.state_dir .. '/*.pid')
  if not ok or not files then
    return result
  end

  for _, path in ipairs(files) do
    local name = (path:gsub('\\', '/')):match('([^/]+)%.pid$')
    local parsed = name and parse_name(name)
    if parsed then
      local pid = read_pid(path)
      local alive = (not verify) or nvim_alive(pid)
      if not alive then
        table.insert(result.stale, { name = name, pid = pid })

        if not readonly then
          os.remove(path)

          -- A hard-killed Unix server cannot remove its socket itself.
          if not is_windows then
            os.remove(address_for(name))
          end

          -- A crashed/killed client may also leave its lease behind.
          os.remove(M.state_dir .. '/' .. name .. '.lease')
        end
      end
      if alive or readonly then
        local server = { name = name, pid = pid, alive = alive }
        if parsed.kind == 'pool' then
          table.insert(result.pool, server)
        else
          result.pane[parsed.instance] = result.pane[parsed.instance] or {}
          result.pane[parsed.instance][parsed.pane_id] = server
        end
      end
    end
  end

  return result
end

--- Contents of the lease a pooled server is claimed with, or nil when free.
-- Written by the `vim` shell function as "pid=<shell pid> pane=<wezterm pane>".
local function read_lease(name)
  local file = io.open(M.state_dir .. '/' .. name .. '.lease', 'r')
  if not file then
    return nil
  end
  local line = file:read('*line')
  file:close()
  return line and line:gsub('%s+$', '') or ''
end

--- Tabs and panes of this wezterm instance.
-- Scope is the process, not a single window: a pane in another window of the
-- same instance still needs its server, and would otherwise look orphaned.
-- The per window breakdown is only used for the debug log.
local function collect_panes()
  local snapshot = { windows = {}, pane_ids = {}, total_panes = 0, total_tabs = 0 }

  local ok, windows = pcall(wezterm.mux.all_windows)
  if not ok or not windows then
    return nil
  end

  for _, mux_window in ipairs(windows) do
    local entry = { id = mux_window:window_id(), tabs = {} }
    local tabs_ok, tabs = pcall(function() return mux_window:tabs() end)
    if tabs_ok and tabs then
      for _, tab in ipairs(tabs) do
        local tab_entry = { id = tab:tab_id(), pane_ids = {} }
        local panes_ok, panes = pcall(function() return tab:panes() end)
        if panes_ok and panes then
          for _, pane in ipairs(panes) do
            local pane_id = pane:pane_id()
            table.insert(tab_entry.pane_ids, pane_id)
            snapshot.pane_ids[pane_id] = true
            snapshot.total_panes = snapshot.total_panes + 1
          end
        end
        table.insert(entry.tabs, tab_entry)
        snapshot.total_tabs = snapshot.total_tabs + 1
      end
    end
    table.insert(snapshot.windows, entry)
  end

  return snapshot
end

--- Orphan strike counts, keyed by pane id or by "instance:<pid>".
--
-- Deliberately NOT kept in wezterm.GLOBAL. A table stored there reads back as
-- a proxy whose fields are mlua Values rather than native numbers, so
-- `strikes[key] + 1` dies with "attempt to perform arithmetic on a Value
-- value". Top-level scalars in GLOBAL are converted back properly, which is
-- why the instance tag and the counters below are still kept there. The only
-- thing lost by holding these module-locally is that a config reload resets
-- them, which merely delays a kill by a few ticks.
local strike_counts = {}

local function get_strikes()
  return strike_counts
end

local function set_strikes(strikes)
  strike_counts = strikes
end

-- ---------------------------------------------------------------------------
-- Reconciling (pane mode)
-- ---------------------------------------------------------------------------

local tick_count = 0

--- Servers belonging to a wezterm instance that is no longer running. This is
-- the only cleanup that survives an instance being closed with the window
-- button or killed, neither of which raises an event we could hook.
local function reap_orphaned_instances(servers, strikes, killed, log)
  local self_id = instance_id()
  if not procinfo_usable() then
    return
  end

  for instance, panes in pairs(servers.pane) do
    local pid = tonumber(instance)
    -- Instances without a numeric tag cannot be checked, so leave them alone
    if instance ~= self_id and pid and not wezterm_alive(pid) then
      local key = 'instance:' .. instance
      local strike = (strikes[key] or 0) + 1
      if strike >= M.orphan_grace_ticks then
        local dead = {}
        for _, server in pairs(panes) do
          table.insert(dead, server)
          table.insert(killed, server.name)
        end
        kill_servers(dead, false)
        if log then
          table.insert(log, ('  reaped %d server(s) of dead instance %s'):format(#dead, instance))
        end
      else
        strikes[key] = strike
      end
    end
  end
end

--- Brings the set of servers in line with the set of panes.
-- @param opts { verify = bool, log = table|nil, reason = string }
-- @return { spawned, killed, panes, servers, in_sync }
local function reconcile(opts)
  opts = opts or {}
  local log = opts.log
  local self_id = instance_id()

  local snapshot = collect_panes()
  if not snapshot then
    if log then
      table.insert(log, '  mux unavailable, skipping')
    end
    return { spawned = 0, killed = 0, panes = 0, servers = 0, in_sync = true, skipped = true }
  end

  local servers = scan_servers(opts.verify)
  local mine = servers.pane[self_id] or {}
  local strikes = get_strikes()
  local next_strikes = {}
  local spawned, killed = {}, {}

  -- Carry over strikes that are not about panes of this instance
  for key, value in pairs(strikes) do
    if key:sub(1, 9) == 'instance:' then
      next_strikes[key] = value
    end
  end

  -- A pane without a server
  for pane_id in pairs(snapshot.pane_ids) do
    if not mine[pane_id] then
      local name = pane_server_name(pane_id)
      if spawn(name) then
        table.insert(spawned, name)
      end
    end
  end

  -- A server without a pane, killed only once the grace period has run out
  local orphans = {}
  for pane_id, server in pairs(mine) do
    if not snapshot.pane_ids[pane_id] then
      local key = tostring(pane_id)
      local strike = (strikes[key] or 0) + 1
      if strike >= M.orphan_grace_ticks then
        table.insert(orphans, server)
        table.insert(killed, server.name)
      else
        next_strikes[key] = strike
        if log then
          table.insert(log, ('  orphan %s: strike %d/%d'):format(server.name, strike, M.orphan_grace_ticks))
        end
      end
    end
  end
  if #orphans > 0 then
    kill_servers(orphans, false)
  end

  reap_orphaned_instances(servers, next_strikes, killed, log)
  set_strikes(next_strikes)

  local server_count = 0
  for _ in pairs(mine) do
    server_count = server_count + 1
  end

  if log then
    for _, window in ipairs(snapshot.windows) do
      table.insert(log, ('window %d: %d tab(s)'):format(window.id, #window.tabs))
      for index, tab in ipairs(window.tabs) do
        table.insert(log, ('  tab %d (id %d): %d pane(s) [%s]')
          :format(index, tab.id, #tab.pane_ids, table.concat(tab.pane_ids, ', ')))
      end
    end
    table.insert(log, ('total: %d tab(s), %d pane(s)'):format(snapshot.total_tabs, snapshot.total_panes))
    table.insert(log, ('servers for this instance (%s): %d'):format(self_id, server_count))
    for pane_id, server in pairs(mine) do
      table.insert(log, ('  pane %-4d %s  pid=%s'):format(pane_id, server.name, tostring(server.pid)))
    end
    for _, server in ipairs(servers.stale) do
      table.insert(log, ('  stale pid file removed: %s (pid=%s)'):format(server.name, tostring(server.pid)))
    end
    if #spawned > 0 then
      table.insert(log, 'spawned: ' .. table.concat(spawned, ', '))
    end
    if #killed > 0 then
      table.insert(log, 'killed: ' .. table.concat(killed, ', '))
    end
  end

  return {
    spawned = #spawned,
    killed = #killed,
    panes = snapshot.total_panes,
    tabs = snapshot.total_tabs,
    servers = server_count,
    in_sync = #spawned == 0 and #killed == 0,
  }
end

-- ---------------------------------------------------------------------------
-- Pool
-- ---------------------------------------------------------------------------

--- Tops the pool up to M.pool_size. With M.prefill_once it really does run
-- only once per wezterm instance; from then on `vim` replaces the server it
-- takes, so the pool stays warm without a background job.
--
-- The flag lives in wezterm.GLOBAL rather than in a local: this module is
-- re-evaluated on every config reload, and a local would let a reload prefill
-- the pool all over again.
local function prefill_pool()
  if M.prefill_once and wezterm.GLOBAL.nvim_server_prefilled then
    return
  end

  local servers = scan_servers(true)

  -- Pool is already large enough.
  if #servers.pool >= M.pool_size then
    wezterm.GLOBAL.nvim_server_prefill_retry_after = nil
    -- Started with a full pool (it outlives wezterm), so this instance is done
    wezterm.GLOBAL.nvim_server_prefilled = true
    return
  end

  -- background_child_process() is asynchronous. While a previous batch is
  -- starting, scan_servers() may not see its pid files yet.
  local now = os.time()
  local retry_after =
    tonumber(wezterm.GLOBAL.nvim_server_prefill_retry_after) or 0

  if now < retry_after then
    return
  end

  local missing = M.pool_size - #servers.pool

  wezterm.GLOBAL.nvim_server_prefill_retry_after =
    now + M.pool_prefill_timeout_seconds

  for _ = 1, missing do
    spawn(pool_server_name())
  end

  -- One batch is all this instance starts; a spawn that failed is left to
  -- `vim`, which starts a server itself when the pool runs dry
  wezterm.GLOBAL.nvim_server_prefilled = true
end

-- ---------------------------------------------------------------------------
-- Background job
-- ---------------------------------------------------------------------------

local job_started = false
local job_error_logged = false

local function run_tick()
  tick_count = tick_count + 1
  local verify = M.verify_pids_every_ticks > 0
    and (tick_count % M.verify_pids_every_ticks) == 0

  local log = M.log_background_ticks and {} or nil
  if log then
    table.insert(log, ('=== %s  background tick %d  instance=%s ===')
      :format(wezterm.strftime('%Y-%m-%d %H:%M:%S'), tick_count, instance_id()))
  end

  local result = reconcile({ verify = verify, log = log })

  if log then
    table.insert(log, ('result: %d pane(s), %d server(s), spawned %d, killed %d')
      :format(result.panes, result.servers, result.spawned, result.killed))
    log_lines(log)
  end
end

local function start_job()
  if job_started or not M.enabled or M.use_pool or not M.job_enabled then
    return
  end
  job_started = true

  -- A config reload re-runs this file while the previous timer chain is still
  -- armed; bumping the generation makes the old chain stop at its next tick.
  local generation = (wezterm.GLOBAL.nvim_server_job_gen or 0) + 1
  wezterm.GLOBAL.nvim_server_job_gen = generation

  local function tick()
    if wezterm.GLOBAL.nvim_server_job_gen ~= generation then
      return
    end
    local ok, err = xpcall(run_tick, traceback)
    if not ok and not job_error_logged then
      -- Once only: a failure that repeats every tick would flood the log
      job_error_logged = true
      log_lines({
        ('=== %s  background tick failed  instance=%s ==='):format(
          wezterm.strftime('%Y-%m-%d %H:%M:%S'), instance_id()),
        'ERROR: ' .. tostring(err),
        '',
      })
    end
    wezterm.time.call_after(M.job_interval_seconds, tick)
  end

  wezterm.time.call_after(M.job_interval_seconds, tick)
end

--- Reconciles shortly after a keybind, once the pane it created or closed has
-- actually appeared or gone.
local function schedule_sync()
  wezterm.time.call_after(0.15, function()
    pcall(reconcile, { verify = false })
  end)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Environment handed to every pane wezterm spawns, so `vims`/`nvims` need no
-- configuration of their own. Feed into config.set_environment_variables.
function M.env()
  if not M.enabled then
    return {}
  end
  return {
    WEZ_NVIM_MODE = M.use_pool and 'pool' or 'pane',
    WEZ_NVIM_INSTANCE = instance_id(),
    WEZ_NVIM_DIR = M.state_dir,
    WEZ_NVIM_POOL_SIZE = tostring(M.pool_size),
    WEZ_NVIM_POOL_MIN_FREE = tostring(M.pool_min_free),
  }
end

--- Starts the background job and fills the pool the first time it is called.
-- Doing this from "update-right-status" rather than "gui-startup" keeps the
-- startup path untouched, and it runs about a second after launch anyway.
function M.poll(_window)
  if not M.enabled then
    return
  end
  if M.use_pool then
    prefill_pool()
    return
  end
  start_job()
end

--- Reconcile after a pane was created outside of on_new_pane().
function M.panes_added(_window)
  if not M.enabled or M.use_pool then
    return
  end
  schedule_sync()
end

--- Wraps an action that creates a pane or tab.
function M.on_new_pane(action)
  if not M.enabled or M.use_pool then
    return action
  end
  return wezterm.action_callback(function(window, pane)
    window:perform_action(action, pane)
    schedule_sync()
  end)
end

--- Wraps an action that closes the current pane. The server is killed straight
-- away instead of waiting for the grace period; if a confirmation prompt is
-- cancelled the background job simply spawns it again.
function M.on_close_pane(action)
  if not M.enabled or M.use_pool then
    return action
  end
  return wezterm.action_callback(function(window, pane)
    local servers = scan_servers(false)
    local mine = servers.pane[instance_id()] or {}
    local server = mine[pane:pane_id()]
    if server then
      kill_servers({ server }, false)
    end
    window:perform_action(action, pane)
    schedule_sync()
  end)
end

--- Wraps an action that closes the current tab.
function M.on_close_tab(action)
  if not M.enabled or M.use_pool then
    return action
  end
  return wezterm.action_callback(function(window, pane)
    local servers = scan_servers(false)
    local mine = servers.pane[instance_id()] or {}
    local doomed = {}

    local ok, panes = pcall(function() return pane:tab():panes() end)
    if ok and panes then
      for _, tab_pane in ipairs(panes) do
        local server = mine[tab_pane:pane_id()]
        if server then
          table.insert(doomed, server)
        end
      end
    end

    if #doomed > 0 then
      kill_servers(doomed, false)
    end
    window:perform_action(action, pane)
    schedule_sync()
  end)
end

--- Wraps QuitApplication. This has to happen before the action is performed
-- and synchronously, because there is no event after wezterm decides to quit.
function M.on_quit(action)
  if not M.enabled or M.use_pool then
    return action
  end
  return wezterm.action_callback(function(window, pane)
    M.quitting()
    window:perform_action(action, pane)
  end)
end

--- Kills every server of this instance, synchronously.
function M.quitting()
  if not M.enabled or M.use_pool then
    return
  end
  local servers = scan_servers(false)
  local doomed = {}
  for _, server in pairs(servers.pane[instance_id()] or {}) do
    table.insert(doomed, server)
  end
  if #doomed > 0 then
    kill_servers(doomed, true)
  end
end

--- Read-only counterpart to sync_now(). Describes what is actually there --
-- tabs, panes, every server and how they map to each other, what is missing or
-- redundant, the pool, and the leftovers of other wezterm instances -- without
-- spawning, killing or deleting anything, including stale pid files. Works the
-- same in both modes and regardless of M.enabled, so it can be used to work out
-- why nothing is happening. The full dump goes to M.log_file; the status line
-- only gets a one line summary.
local function report_impl(window)
  local self_id = instance_id()
  local out = {}
  local function add(line)
    table.insert(out, line)
  end

  add(('=== %s  report (read-only)  instance=%s  mode=%s ==='):format(
    wezterm.strftime('%Y-%m-%d %H:%M:%S'), self_id, M.use_pool and 'pool' or 'pane'))
  add(('settings: enabled=%s  use_pool=%s  job_enabled=%s  interval=%ss'):format(
    tostring(M.enabled), tostring(M.use_pool), tostring(M.job_enabled),
    tostring(M.job_interval_seconds)))
  add(('          orphan_grace_ticks=%d  verify_pids_every_ticks=%d  pool_size=%d  pool_min_free=%d'):format(
    M.orphan_grace_ticks, M.verify_pids_every_ticks, M.pool_size, M.pool_min_free))
  add(('paths:    state_dir=%s'):format(M.state_dir))
  add(('          log_file=%s'):format(M.log_file))
  add(('          address=%s'):format(address_for('<name>')))
  add(('procinfo: %s'):format(procinfo_usable() and 'usable'
    or 'UNAVAILABLE - pids cannot be checked, liveness below is a guess'))

  local snapshot = collect_panes()
  add('')
  if not snapshot then
    add('windows: mux unavailable')
  else
    add(('windows / tabs / panes (this instance, %d window(s)):'):format(#snapshot.windows))
    for _, mux_window in ipairs(snapshot.windows) do
      add(('  window %d: %d tab(s)'):format(mux_window.id, #mux_window.tabs))
      for index, tab in ipairs(mux_window.tabs) do
        add(('    tab %d (id %d): %d pane(s) [%s]'):format(
          index, tab.id, #tab.pane_ids, table.concat(tab.pane_ids, ', ')))
      end
    end
    add(('  total: %d tab(s), %d pane(s)'):format(snapshot.total_tabs, snapshot.total_panes))
  end

  local servers = scan_servers(true, true)
  local mine = servers.pane[self_id] or {}

  -- Pane to server mapping for this instance
  add('')
  if M.use_pool then
    add(('pane servers for this instance (%s): not used in pool mode'):format(self_id))
  else
    add(('pane servers for this instance (%s):'):format(self_id))
  end

  local pane_ids = {}
  if snapshot then
    for pane_id in pairs(snapshot.pane_ids) do
      table.insert(pane_ids, pane_id)
    end
  end
  table.sort(pane_ids)

  local missing, redundant = 0, 0
  for _, pane_id in ipairs(pane_ids) do
    local server = mine[pane_id]
    if server then
      add(('  pane %-4d -> %-28s pid=%-7s %s'):format(
        pane_id, server.name, tostring(server.pid),
        server.alive and 'alive' or 'PID NOT RUNNING'))
    elseif not M.use_pool then
      missing = missing + 1
      add(('  pane %-4d -> %-28s MISSING'):format(pane_id, '(no server)'))
    end
  end

  local orphan_ids = {}
  for pane_id in pairs(mine) do
    if not (snapshot and snapshot.pane_ids[pane_id]) then
      table.insert(orphan_ids, pane_id)
    end
  end
  table.sort(orphan_ids)
  for _, pane_id in ipairs(orphan_ids) do
    local server = mine[pane_id]
    redundant = redundant + 1
    add(('  (no pane %-3d) %-28s pid=%-7s %-16s REDUNDANT'):format(
      pane_id, server.name, tostring(server.pid),
      server.alive and 'alive' or 'PID NOT RUNNING'))
  end

  local strikes = get_strikes()
  local strike_lines = {}
  for key, value in pairs(strikes) do
    table.insert(strike_lines, ('    %s: %s/%d'):format(key, tostring(value), M.orphan_grace_ticks))
  end
  table.sort(strike_lines)
  if #strike_lines > 0 then
    add('  orphan strikes so far (killed once they reach the limit):')
    for _, line in ipairs(strike_lines) do
      add(line)
    end
  end
  local server_count = 0
  for _ in pairs(mine) do
    server_count = server_count + 1
  end
  add(('  summary: %d pane(s), %d server(s), %d missing, %d redundant'):format(
    #pane_ids, server_count, missing, redundant))

  -- Pool
  add('')
  -- Counted before the header: pool_size is the number of FREE servers to keep
  -- ready, not a total, so the total grows by one per pane holding a server
  local pool_lines, free_pool = {}, 0
  table.sort(servers.pool, function(a, b) return a.name < b.name end)
  for _, server in ipairs(servers.pool) do
    local lease = read_lease(server.name)
    if not lease then
      free_pool = free_pool + 1
    end
    table.insert(pool_lines, ('  %-32s pid=%-7s %-16s %s'):format(
      server.name, tostring(server.pid),
      server.alive and 'alive' or 'PID NOT RUNNING',
      lease and ('in use by ' .. lease) or 'free'))
  end
  add(('pool servers: %d total = %d free + %d in use  [shared between instances]'):format(
    #servers.pool, free_pool, #servers.pool - free_pool))
  add(('              prefill %d at startup, `vim` starts one more only when free <= %d'):format(
    M.pool_size, M.pool_min_free))
  for _, line in ipairs(pool_lines) do
    add(line)
  end
  if M.use_pool and free_pool <= M.pool_min_free then
    add('  note: at the low water mark; the next claim will start a replacement')
  end

  -- Anything belonging to another wezterm
  add('')
  local other_ids = {}
  for instance in pairs(servers.pane) do
    if instance ~= self_id then
      table.insert(other_ids, instance)
    end
  end
  table.sort(other_ids)
  if #other_ids == 0 then
    add('other wezterm instances: none')
  else
    add('other wezterm instances:')
    for _, instance in ipairs(other_ids) do
      local pid = tonumber(instance)
      local live = pid and wezterm_alive(pid)
      local count = 0
      for _ in pairs(servers.pane[instance]) do
        count = count + 1
      end
      add(('  instance %-8s %-6s %d server(s)  %s'):format(
        instance, live and 'alive' or 'DEAD', count,
        live and 'left alone' or 'leaked, reaped by sync after the grace period'))
      for pane_id, server in pairs(servers.pane[instance]) do
        add(('    pane %-4d %-28s pid=%-7s %s'):format(
          pane_id, server.name, tostring(server.pid),
          server.alive and 'alive' or 'PID NOT RUNNING'))
      end
    end
  end

  -- Pid files whose process is gone; left in place, this is a read-only report
  add('')
  if #servers.stale == 0 then
    add('stale pid files: none')
  else
    add(('stale pid files (process gone, file left behind): %d'):format(#servers.stale))
    for _, server in ipairs(servers.stale) do
      add(('  %-32s pid=%s'):format(server.name .. '.pid', tostring(server.pid)))
    end
    add('  not removed: this report never changes anything')
  end

  local summary
  if not M.enabled then
    summary = 'switched off; ' .. #pane_ids .. ' pane(s)'
  elseif M.use_pool then
    summary = ('pool: %d free (min %d), %d total, %d pane(s)'):format(
      free_pool, M.pool_min_free, #servers.pool, #pane_ids)
  elseif missing == 0 and redundant == 0 then
    summary = ('in sync: %d pane(s), %d server(s)'):format(#pane_ids, server_count)
  else
    summary = ('%d pane(s), %d server(s): %d missing, %d redundant'):format(
      #pane_ids, server_count, missing, redundant)
  end

  add('')
  add('verdict: ' .. summary)
  add('')
  log_lines(out)

  status.notify(window, M.notification_title, summary,
    M.use_pool and true or (missing == 0 and redundant == 0))
end

--- Public entry point; a failure in the report itself must be visible too.
function M.report(window)
  local ok, err = xpcall(function() report_impl(window) end, traceback)
  if ok then
    return
  end
  log_lines({
    ('=== %s  report failed  instance=%s ==='):format(
      wezterm.strftime('%Y-%m-%d %H:%M:%S'), instance_id()),
    'ERROR: ' .. tostring(err),
    '',
  })
  status.notify(window, M.notification_title, 'report failed, see ' .. M.log_file, false)
end

--- The manual trigger. Deliberately independent of M.job_enabled, so it still
-- reconciles when the background job is switched off; writes a full breakdown
-- to M.log_file and reports through the status line.
--
-- It always writes the header line first, even when there is nothing to do,
-- and reports errors with a traceback instead of letting wezterm's event
-- dispatch swallow them. Without that a press that hit an early return, a
-- stale in-memory copy of this file, or a crash all look identical: nothing
-- happens at all. The status line only holds one message at a time and falls
-- back to a short toast when the tab bar is hidden, so the log is the reliable
-- channel here, not the notification.
function M.sync_now(window)
  local header = ('=== %s  manual sync  instance=%s  mode=%s  enabled=%s job_enabled=%s ==='):format(
    wezterm.strftime('%Y-%m-%d %H:%M:%S'), instance_id(),
    M.use_pool and 'pool' or 'pane', tostring(M.enabled), tostring(M.job_enabled))

  if not M.enabled then
    log_lines({ header, 'result: switched off, nothing to do', '' })
    status.notify(window, M.notification_title, 'nvim servers are disabled', false)
    return
  end

  -- Panes and servers are not mapped to each other in pool mode, so there is
  -- nothing to reconcile; still say so rather than returning silently
  if M.use_pool then
    log_lines({ header, 'result: pool mode, nothing to reconcile', '' })
    status.notify(window, M.notification_title, 'pool mode: nothing to reconcile', true)
    return
  end

  local log = { header }
  local ok, result = xpcall(function()
    return reconcile({ verify = true, log = log })
  end, traceback)

  if not ok then
    table.insert(log, 'ERROR: ' .. tostring(result))
    table.insert(log, '')
    log_lines(log)
    status.notify(window, M.notification_title, 'sync failed, see ' .. M.log_file, false)
    return
  end

  local summary
  if result.skipped then
    summary = 'mux unavailable'
  elseif result.in_sync then
    summary = ('in sync: %d pane(s), %d server(s)'):format(result.panes, result.servers)
  else
    summary = ('%d pane(s), %d server(s): spawned %d, killed %d')
      :format(result.panes, result.servers, result.spawned, result.killed)
  end

  table.insert(log, 'result: ' .. summary)
  table.insert(log, '')
  log_lines(log)

  status.notify(window, M.notification_title, summary, result.in_sync and not result.skipped)
end

return M
