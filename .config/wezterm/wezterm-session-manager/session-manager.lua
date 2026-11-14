local wezterm = require 'wezterm' --[[@as Wezterm]]
local status = require("status")
local session_manager = {}
-- Any windows triple (msvc, gnu, aarch64); the old exact x86_64 match missed those
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Every save and restore goes through this one session, whatever the active
-- workspace is called, so a renamed workspace or a fresh "default" window
-- still saves and restores the same layout
local SESSION_NAME = "coding"
-- Where the state files live: %USERPROFILE%\.wezterm on Windows (created by
-- update.ps1), ~/.config/wezterm everywhere else
local STATE_DIR = wezterm.home_dir .. (is_windows and "/.wezterm" or "/.config/wezterm") .. "/wezterm-session-manager"
local NOTIFY_TITLE = 'WezTerm Session Manager'
-- A save is skipped below these, so saving a near-empty window by accident
-- does not overwrite the real session
local MIN_TABS_TO_SAVE = 3
local MIN_UNIQUE_CWDS_TO_SAVE = 3
-- Foreground processes that count as an idle shell (by file name, without
-- .exe): the initial pane is only closed when it runs one, and a restored pane
-- does not start one again, since that would nest a second shell in it
local SHELLS = {
  sh = true, bash = true, zsh = true, fish = true, dash = true, ksh = true, nu = true,
  cmd = true, powershell = true, pwsh = true,
}
-- os.date format of the saved_at field
local SAVED_AT_FORMAT = "%Y-%m-%d %H:%M"
-- show_state: the notification replaces the previous one (same id) and stays
-- this long; the overlay is used when no notification could be sent
local SHOW_NOTIFY_ID = "7312"
local SHOW_NOTIFY_TIMEOUT_MS = 15000
local SHOW_APP_NAME = "wezterm-session"
-- Markers in show_state for the active tab / pane
local ACTIVE_MARK = "●"
local BRANCH_MID = "├ "
local BRANCH_LAST = "└ "
-- Pango colours for the notification (gruvbox, like the tmux one)
local SHOW_COLORS = {
  tab = "#fabd2f",
  active = "#8ec07c",
  command = "#d3869b",
  dim = "#928374",
}

--- Displays a notification in WezTerm.
-- @param message string: The notification message to be displayed.
local function display_notification(message)
  wezterm.log_info(message)
  -- Additional code to display a GUI notification can be added here if needed
end

local function decode_url(url)
  -- Every percent escape, not just %20: a dir like Code2/C#/BloogBot arrives
  -- from OSC 7 as Code2/C%23/BloogBot and would be restored verbatim otherwise
  return (url:gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end))
end

--- The state file of a session.
local function state_file_path(name)
  return STATE_DIR .. "/wezterm_state_" .. name .. ".json"
end

--- "/usr/bin/zsh" -> "zsh", "C:\Program Files\PowerShell\7\pwsh.exe" -> "pwsh"
local function process_basename(path)
  local name = path:match("[^/\\]+$") or path
  return (name:lower():gsub("%.exe$", ""))
end

--- The pane's cwd as a decoded file:// URI, or nil when wezterm does not know it
-- (tostring(nil) used to be saved as the cwd "nil")
local function pane_cwd(pane)
  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    return nil
  end
  return decode_url(tostring(cwd_uri))
end

--- Quotes an argument for a POSIX shell, leaving plain ones as they are.
local function shell_quote(arg)
  if arg:match("^[%w%._/:=@%%+,-]+$") then
    return arg
  end
  return "'" .. arg:gsub("'", "'\\''") .. "'"
end

--- The command line that starts a pane's saved foreground program again, or nil
-- when there is nothing to start: an idle shell or an unknown process.
local function restore_command(pane_data)
  local tty = pane_data.tty
  if type(tty) ~= "string" or tty == "" or tty == "nil" or SHELLS[process_basename(tty)] then
    return nil
  end

  local argv = pane_data.argv
  local command
  if type(argv) ~= "table" or #argv == 0 then
    -- State saved before the arguments were recorded: the bare program
    command = tty
  elseif #argv == 1 and argv[1]:find(" ") then
    -- A program that set its own process title (node does, e.g. "npm run dev")
    -- leaves its whole command line in argv[1]; quoting it would break it
    command = argv[1]
  else
    local parts = {}
    for _, arg in ipairs(argv) do
      table.insert(parts, shell_quote(arg))
    end
    command = table.concat(parts, " ")
  end

  -- nvim started without arguments opens the restored cwd
  if process_basename(tty) == "nvim" and (type(argv) ~= "table" or #argv <= 1) then
    command = command .. " ."
  end
  return command
end

--- Retrieves the current workspace data from the active window.
-- @return table or nil: The workspace data table, or nil and the reason when there is nothing worth saving.
local function retrieve_workspace_data(window)
  local workspace_data = {
    name = SESSION_NAME,
    -- Shown by show_state; the json has no other trace of when it was saved
    saved_at = os.date(SAVED_AT_FORMAT),
    tabs = {}
  }

  -- Skip saving if there are too few tabs
  local tabs = window:mux_window():tabs()
  if #tabs < MIN_TABS_TO_SAVE then
    return nil, "less than " .. MIN_TABS_TO_SAVE .. " tabs"
  end

  -- Skip saving unless enough unique cwds
  local unique_cwds = {}
  local cwd_map = {}

  for _, tab in ipairs(tabs) do
    for _, pane_info in ipairs(tab:panes_with_info()) do
      local cwd = pane_cwd(pane_info.pane)

      if cwd and not cwd_map[cwd] then
        cwd_map[cwd] = true
        table.insert(unique_cwds, cwd)
      end
    end
  end

  if #unique_cwds < MIN_UNIQUE_CWDS_TO_SAVE then
    return nil, "less than " .. MIN_UNIQUE_CWDS_TO_SAVE .. " unique dirs"
  end

  -- Save session data
  -- Iterate over tabs in the current window
  local active_tab = window:mux_window():active_tab()
  for _, tab in ipairs(tabs) do
    local tab_data = {
      tab_id = tostring(tab:tab_id()),
      -- So the restore activates this tab again rather than the first one
      is_active = active_tab ~= nil and tab:tab_id() == active_tab:tab_id(),
      panes = {}
    }

    -- Iterate over panes in the current tab
    for _, pane_info in ipairs(tab:panes_with_info()) do
      -- Collect pane details, including layout and process information
      local process_info = pane_info.pane:get_foreground_process_info()
      table.insert(tab_data.panes, {
        pane_id = tostring(pane_info.pane:pane_id()),
        index = pane_info.index,
        is_active = pane_info.is_active,
        is_zoomed = pane_info.is_zoomed,
        left = pane_info.left,
        top = pane_info.top,
        width = pane_info.width,
        height = pane_info.height,
        pixel_width = pane_info.pixel_width,
        pixel_height = pane_info.pixel_height,
        cwd = pane_cwd(pane_info.pane),
        -- cwd = tostring(pane_info.pane:get_current_working_dir()),
        --cwd = tostring(pane_info.pane:get_title()),
        tty = pane_info.pane:get_foreground_process_name(),
        -- The arguments too, so e.g. "npm run dev" is not restored as a bare node
        argv = process_info and process_info.argv
      })
    end

    table.insert(workspace_data.tabs, tab_data)
  end

  return workspace_data
end

--- Saves data to a JSON file.
-- @param data table: The workspace data to be saved.
-- @param file_path string: The file path where the JSON file will be saved.
-- @return boolean: true if saving was successful, false otherwise.
local function save_to_json_file(data, file_path)
  if not data then
    wezterm.log_info("No workspace data to log.")
    return false
  end

  local file = io.open(file_path, "w")
  if file then
    file:write(wezterm.json_encode(data))
    file:close()
    return true
  else
    return false
  end
end

--- Recreates the workspace based on the provided data.
-- @param workspace_data table: The data structure containing the saved workspace state.
-- @return boolean, string: true on success, otherwise false and the reason.
local function recreate_workspace(window, workspace_data)
  local function extract_path_from_dir(working_directory)
    -- Unknown cwd (or the "nil" older saves wrote): spawn in the default dir
    if type(working_directory) ~= "string" or not working_directory:find("^file://") then
      return nil
    end
    -- Strip the scheme and the host: 'file://{computer-name}/any/dir' -> '/any/dir'
    -- (the old match only worked below /home/ and /Users/)
    local path = working_directory:gsub("^file://[^/]*", "")
    -- On Windows, '/C:/path/to/dir' -> 'C:/path/to/dir'
    path = path:gsub("^/([A-Za-z]:)", "%1")
    return path
  end

  if not workspace_data or not workspace_data.tabs then
    wezterm.log_info("Invalid or empty workspace data provided.")
    return false, "invalid or empty state file"
  end

  local tabs = window:mux_window():tabs()

  if #tabs ~= 1 or #tabs[1]:panes() ~= 1 then
    wezterm.log_info(
      "Restoration can only be performed in a window with a single tab and a single pane, to prevent accidental data loss.")
    return false, "only possible in a window with a single tab and pane"
  end

  local initial_pane = window:active_pane()
  local foreground_process = initial_pane:get_foreground_process_name()

  -- Check if the foreground process is a shell (by name: a substring match on
  -- "sh" also hit ssh and anything below /usr/share)
  if foreground_process and SHELLS[process_basename(foreground_process)] then
    -- Safe to close
    initial_pane:send_text("exit\r")
  else
    wezterm.log_info("Active program detected. Skipping exit command for initial pane.")
  end

  --- The pane covering the top left corner of a group of saved panes: the one
  -- that keeps the group's pane when the group is split, since a split leaves
  -- the old pane on the left / top
  local function corner_pane(panes)
    local corner = panes[1]
    for _, p in ipairs(panes) do
      local top, left = p.top or 0, p.left or 0
      local corner_top, corner_left = corner.top or 0, corner.left or 0
      if top < corner_top or (top == corner_top and left < corner_left) then
        corner = p
      end
    end
    return corner
  end

  --- Finds a straight cut through a group of saved panes: a column (or row)
  -- that no pane crosses. wezterm layouts are binary split trees, so every
  -- group of more than one pane has one. Returns the panes before and after
  -- the cut, the direction to split in and the new pane's share of the group.
  local function find_cut(panes)
    local axes = {
      { pos = "left", extent = "width", direction = "Right" },
      { pos = "top", extent = "height", direction = "Bottom" },
    }
    for _, p in ipairs(panes) do
      for _, field in ipairs({ "left", "top", "width", "height" }) do
        if type(p[field]) ~= "number" then
          return nil
        end
      end
    end
    for _, axis in ipairs(axes) do
      local first_pos, last_end = math.huge, -math.huge
      for _, p in ipairs(panes) do
        first_pos = math.min(first_pos, p[axis.pos])
        last_end = math.max(last_end, p[axis.pos] + p[axis.extent])
      end
      for _, candidate in ipairs(panes) do
        local cut = candidate[axis.pos]
        local crossed = false
        for _, p in ipairs(panes) do
          if p[axis.pos] < cut and p[axis.pos] + p[axis.extent] > cut then
            crossed = true
            break
          end
        end
        if cut > first_pos and not crossed then
          local before, after = {}, {}
          for _, p in ipairs(panes) do
            table.insert(p[axis.pos] < cut and before or after, p)
          end
          -- A share, not a cell count, so the layout also fits a window of
          -- another size than the one it was saved from
          local share = (last_end - cut) / (last_end - first_pos)
          return before, after, axis.direction, share
        end
      end
    end
    return nil
  end

  --- Splits `pane` until it holds the saved `panes`, and records which new
  -- pane belongs to which saved one in `created`.
  local function split_into(pane, panes, created)
    if #panes == 1 then
      created[panes[1]] = pane
      return true
    end
    local before, after, direction, share = find_cut(panes)
    if not before then
      -- Pane data without a usable geometry: put the rest side by side
      before, after = { panes[1] }, { table.unpack(panes, 2) }
      direction, share = "Right", 1 - 1 / #panes
    end
    local new_pane = pane:split({
      direction = direction,
      size = share,
      cwd = extract_path_from_dir(corner_pane(after).cwd),
    })
    if not new_pane then
      wezterm.log_info("Failed to create a new pane.")
      return false
    end
    return split_into(pane, before, created) and split_into(new_pane, after, created)
  end

  -- Recreate tabs and panes from the saved state
  local first_tab = nil
  local active_tab = nil
  for _, tab_data in ipairs(workspace_data.tabs) do
    local cwd_path = extract_path_from_dir(corner_pane(tab_data.panes).cwd)

    local new_tab = window:mux_window():spawn_tab({ cwd = cwd_path })
    if not new_tab then
      wezterm.log_info("Failed to create a new tab.")
      break
    end

    if not first_tab then
      first_tab = new_tab
    end
    if tab_data.is_active then
      active_tab = new_tab
    end

    -- Activate the new tab before creating panes
    new_tab:activate()

    -- Recreate panes within this tab, from the saved geometry
    local created = {}
    split_into(new_tab:active_pane(), tab_data.panes, created)

    local active_pane = nil
    for _, pane_data in ipairs(tab_data.panes) do
      local new_pane = created[pane_data]
      if new_pane then
        if pane_data.is_active then
          active_pane = new_pane
        end

        -- Restore the foreground program (nvim and the like) on Linux and macOS
        -- NOTE: cwd is handled differently on windows. maybe extend functionality for windows later
        -- This could probably be handled better in general
        if not is_windows then
          local command = restore_command(pane_data)
          if command then
            new_pane:send_text(command .. "\n")
          end
        end
      end
    end

    if active_pane then
      active_pane:activate()
    end
  end

  -- The tab that was active when saving (older saves: the first)
  if active_tab or first_tab then
    (active_tab or first_tab):activate()
  end

  wezterm.log_info("Workspace recreated with new tabs and panes based on saved state.")
  return true
end

--- Loads data from a JSON file.
-- @param file_path string: The file path from which the JSON data will be loaded.
-- @return table or nil: The loaded data as a Lua table, or nil if loading failed.
local function load_from_json_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    wezterm.log_info("Failed to open file: " .. file_path)
    return nil
  end

  local file_content = file:read("*a")
  file:close()

  local data = wezterm.json_parse(file_content)
  if not data then
    wezterm.log_info("Failed to parse JSON data from file: " .. file_path)
  end
  return data
end

--- Loads the saved json file of the session.
function session_manager.restore_state(window)
  local workspace_name = SESSION_NAME
  local file_path = state_file_path(workspace_name)

  status.progress(window, "Restoring session: " .. workspace_name .. "...")

  local workspace_data = load_from_json_file(file_path)
  if not workspace_data then
    status.notify(window, NOTIFY_TITLE,
      'Workspace state file not found for workspace: ' .. workspace_name, false)
    return
  end

  local ok, reason = recreate_workspace(window, workspace_data)
  if ok then
    status.notify(window, NOTIFY_TITLE, 'Workspace state loaded for workspace: ' .. workspace_name, true)
  else
    status.notify(window, NOTIFY_TITLE,
      'Workspace state loading failed for workspace: ' .. workspace_name .. ' (' .. reason .. ')', false)
  end
end

--- Allows to select which workspace to load
function session_manager.load_state(window)
  -- TODO: Implement
  -- Placeholder for user selection logic
  -- ...
  -- TODO: Call the function recreate_workspace(workspace_data) to recreate the workspace
  -- Placeholder for recreation logic...
end

--- Orchestrator function to save the current workspace state.
-- Collects workspace data, saves it to a JSON file, and displays a notification.
function session_manager.save_state(window)
  status.progress(window, "Saving session: " .. SESSION_NAME .. "...")

  local data, skip_reason = retrieve_workspace_data(window)

  -- Skip saving if there is nothing worth saving
  if data == nil then
    status.notify(window, NOTIFY_TITLE, 'Skipping save: ' .. skip_reason .. '.', false)
    return
  end

  -- Construct file path based on session name
  local file_path = state_file_path(data.name)

  -- Save workspace data to JSON and display appropriate notification
  if save_to_json_file(data, file_path) then
    status.notify(window, NOTIFY_TITLE, 'Workspace state saved successfully', true)
  else
    status.notify(window, NOTIFY_TITLE, 'Failed to save workspace state. file_path: ' .. file_path, false)
  end
end

--- A path with ~ for the home dir, / as the separator.
local function tilde_path(path)
  path = path:gsub("\\", "/")
  local home = wezterm.home_dir:gsub("\\", "/"):gsub("/$", "")
  local head = path:sub(1, #home)
  local same = is_windows and head:lower() == home:lower() or head == home
  local rest = path:sub(#home + 1)
  if same and (rest == "" or rest:sub(1, 1) == "/") then
    path = "~" .. rest
  end
  return path
end

--- A saved cwd for display: a plain path, ~ for the home dir.
local function display_path(cwd)
  if type(cwd) ~= "string" or not cwd:find("^file://") then
    return "?"
  end
  -- No trailing slash (WecTerm reports cwds with one), except for the root
  local path = cwd:gsub("^file://[^/]*", ""):gsub("^/([A-Za-z]:)", "%1"):gsub("(.)/$", "%1")
  return tilde_path(path)
end

--- The saved session as rows: one per tab, then one per pane below it.
local function session_rows(workspace_data)
  local rows = {}
  for tab_number, tab_data in ipairs(workspace_data.tabs or {}) do
    local panes = tab_data.panes or {}
    table.insert(rows, { kind = "tab", text = "Tab " .. tab_number, active = tab_data.is_active == true })
    for pane_number, pane_data in ipairs(panes) do
      local tty = pane_data.tty
      local command = nil
      if type(tty) == "string" and tty ~= "" and tty ~= "nil" and not SHELLS[process_basename(tty)] then
        command = process_basename(tty)
      end
      table.insert(rows, {
        kind = "pane",
        branch = pane_number == #panes and BRANCH_LAST or BRANCH_MID,
        text = display_path(pane_data.cwd),
        -- Only worth marking when the tab has more than one pane
        active = #panes > 1 and pane_data.is_active == true,
        command = command,
      })
    end
  end
  return rows
end

--- "saved 2026-11-14 13:20 · 4 tabs, 6 panes"
local function session_summary(workspace_data)
  local tab_count, pane_count = 0, 0
  for _, tab_data in ipairs(workspace_data.tabs or {}) do
    tab_count = tab_count + 1
    pane_count = pane_count + #(tab_data.panes or {})
  end
  local counts = tab_count .. " tabs, " .. pane_count .. " panes"
  if type(workspace_data.saved_at) == "string" then
    return "saved " .. workspace_data.saved_at .. " · " .. counts
  end
  return counts
end

local function pango_escape(text)
  return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function pango_color(color, text)
  return '<span foreground="' .. color .. '">' .. text .. '</span>'
end

--- The notification body, in Pango markup (dunst is set to markup = full).
local function session_markup(workspace_data, file_path)
  local lines = { pango_color(SHOW_COLORS.dim, pango_escape(session_summary(workspace_data))) }
  for _, row in ipairs(session_rows(workspace_data)) do
    local line
    if row.kind == "tab" then
      line = pango_color(SHOW_COLORS.tab, "<b>" .. row.text .. "</b>")
    else
      line = pango_color(SHOW_COLORS.dim, row.branch) .. pango_escape(row.text)
      if row.command then
        line = line .. " " .. pango_color(SHOW_COLORS.command, "[" .. pango_escape(row.command) .. "]")
      end
    end
    if row.active then
      line = line .. " " .. pango_color(SHOW_COLORS.active, ACTIVE_MARK)
    end
    table.insert(lines, line)
  end
  table.insert(lines, pango_color(SHOW_COLORS.dim, pango_escape(tilde_path(file_path))))
  return table.concat(lines, "\n")
end

--- Raises the notification on Linux: dunstify first (it replaces the previous
-- one), then notify-send for another notification daemon. timeout keeps a
-- hung dbus from freezing the gui. Returns true when one was sent.
local function notify_session(title, body)
  if is_windows then
    return false
  end
  local commands = {
    { "timeout", "3", "dunstify", "-a", SHOW_APP_NAME, "-r", SHOW_NOTIFY_ID,
      "-t", tostring(SHOW_NOTIFY_TIMEOUT_MS), title, body },
    { "timeout", "3", "notify-send", "-a", SHOW_APP_NAME,
      "-t", tostring(SHOW_NOTIFY_TIMEOUT_MS), title, body },
  }
  for _, command in ipairs(commands) do
    local ok, success = pcall(wezterm.run_child_process, command)
    if ok and success then
      return true
    end
  end
  return false
end

--- The fallback: the session in a wezterm overlay (Escape closes it).
local function show_session_overlay(window, pane, title, workspace_data, file_path)
  local choices = {
    { label = wezterm.format({ { Foreground = { Color = SHOW_COLORS.dim } }, { Text = session_summary(workspace_data) } }) },
  }
  for _, row in ipairs(session_rows(workspace_data)) do
    local segments
    if row.kind == "tab" then
      segments = { { Foreground = { Color = SHOW_COLORS.tab } }, { Attribute = { Intensity = "Bold" } }, { Text = row.text } }
    else
      segments = { { Foreground = { Color = SHOW_COLORS.dim } }, { Text = row.branch }, "ResetAttributes", { Text = row.text } }
      if row.command then
        table.insert(segments, { Foreground = { Color = SHOW_COLORS.command } })
        table.insert(segments, { Text = " [" .. row.command .. "]" })
      end
    end
    if row.active then
      table.insert(segments, { Foreground = { Color = SHOW_COLORS.active } })
      table.insert(segments, { Text = " " .. ACTIVE_MARK })
    end
    table.insert(choices, { label = wezterm.format(segments) })
  end
  table.insert(choices, { label = wezterm.format({ { Foreground = { Color = SHOW_COLORS.dim } }, { Text = file_path } }) })

  window:perform_action(wezterm.action.InputSelector({
    title = title,
    choices = choices,
    -- Only a viewer: picking a row just closes it
    action = wezterm.action_callback(function() end),
  }), pane)
end

--- Shows the saved session (the file restore_state loads) as tabs with their
-- panes' cwds: a notification on Linux (dunst, else any notification daemon),
-- otherwise, and on Windows, a wezterm overlay.
function session_manager.show_state(window, pane)
  local file_path = state_file_path(SESSION_NAME)
  local workspace_data = load_from_json_file(file_path)
  if not workspace_data or type(workspace_data.tabs) ~= "table" then
    status.notify(window, NOTIFY_TITLE, 'No saved session: ' .. file_path, false)
    return
  end

  local title = "WezTerm session: " .. SESSION_NAME
  if not notify_session(title, session_markup(workspace_data, file_path)) then
    show_session_overlay(window, pane, title, workspace_data, file_path)
  end
end

return session_manager
