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
  for _, tab in ipairs(tabs) do
    local tab_data = {
      tab_id = tostring(tab:tab_id()),
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

  -- Recreate tabs and panes from the saved state
  local first_tab = nil
  for _, tab_data in ipairs(workspace_data.tabs) do
    local cwd_uri = tab_data.panes[1].cwd
    local cwd_path = extract_path_from_dir(cwd_uri)

    local new_tab = window:mux_window():spawn_tab({ cwd = cwd_path })
    if not new_tab then
      wezterm.log_info("Failed to create a new tab.")
      break
    end

    if not first_tab then
      first_tab = new_tab
    end

    -- Activate the new tab before creating panes
    new_tab:activate()

    -- Recreate panes within this tab
    local active_pane = nil
    for j, pane_data in ipairs(tab_data.panes) do
      local new_pane
      if j == 1 then
        new_pane = new_tab:active_pane()
      else
        -- The size is the new pane's: its width for a split to the right,
        -- its height for one below
        local direction = 'Right'
        local size = pane_data.width
        if pane_data.left == tab_data.panes[j - 1].left then
          direction = 'Bottom'
          size = pane_data.height
        end

        new_pane = new_tab:active_pane():split({
          direction = direction,
          size = size,
          cwd = extract_path_from_dir(pane_data.cwd)
        })
      end

      if not new_pane then
        wezterm.log_info("Failed to create a new pane.")
        break
      end

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

    if active_pane then
      active_pane:activate()
    end
  end

  if first_tab then
    first_tab:activate()
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

return session_manager
