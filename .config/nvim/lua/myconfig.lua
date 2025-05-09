local M = {} -- Module table

-- Utility function to normalize paths
function M.normalize_path(path)
  if not path then return nil end
  -- Replace backslashes with forward slashes and remove duplicate forward slashes
  path = path:gsub("\\", "/"):gsub("//+", "/"):gsub("/#", "\\#")
  return path
end

-- Utility function that tries to get the git root
function M.get_git_root()
  local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
  git_root = vim.trim(git_root)

  if vim.v.shell_error ~= 0 then
    -- vim.notify("Not inside a Git repository.", vim.log.levels.ERROR)
    -- return nil
    return vim.fn.getcwd(), false
  end

  return git_root, true
end

-- Utility function to replace placeholders with env var value
local function replace_placeholders(line)
  --  line = line:gsub("{code_root_dir}", vim.fn.getenv("code_root_dir") or "")
  -- Use gsub to find and replace all occurrences of {ENV_VAR_NAME}
  -- with corresponding environment variable value
  line = line:gsub("{(.-)}", function(env_var)
    return vim.fn.getenv(env_var) or ""
  end)
  return line
end

function M.read_lines_from_file(file, applyTransformations)
  applyTransformations = applyTransformations or false
  local lines = {}
  for line in io.lines(file) do
    if applyTransformations then
      line = replace_placeholders(line)
      line = M.normalize_path(line)
      line = line:gsub("\r", "") -- Remove carriage return (^M)
    end
    table.insert(lines, line)
  end
  return lines
end

-- Utility function for checking if a plugin is installed
function M.is_plugin_installed(plugin_name)
  local status, _ = pcall(require, plugin_name)
  return status
end

-- Utility function for checking if a command is callable
function M.is_callable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Utility function for creating a keymap
function M.map(m, k, v)
  vim.keymap.set(m, k, v, { silent = true })
end

-- Environment vars
local home_dir = M.normalize_path((os.getenv("HOME") or os.getenv("USERPROFILE")) .. "/")
local my_notes_path = M.normalize_path((os.getenv("my_notes_path") or home_dir) .. "/")
local code_root_dir = M.normalize_path((os.getenv("code_root_dir") or home_dir) .. "/")
local ps_profile_path = M.normalize_path((tostring(os.getenv("ps_profile_path")) or home_dir) .. "/")
local user_domain = os.getenv("UserDomain") or home_dir

M.home_dir = home_dir
M.my_notes_path = my_notes_path
M.code_root_dir = code_root_dir
M.ps_profile_path = ps_profile_path
M.user_domain = user_domain

-- Get nvim config dir
function M.get_conf_dir()
  local os_name = vim.loop.os_uname().sysname
  if os_name == "Windows_NT" then
    return M.normalize_path(home_dir .. "/AppData/Local")
  else
    return M.normalize_path(home_dir .. "/.config")
  end
end

-- Customized config (for fun)
local config_file_path = my_notes_path .. "scripts/files/nvim_config.txt"

local function print_config_contents()
    local file = io.open(config_file_path, "r")
    if not file then
        vim.notify("Config file not found: " .. config_file_path, vim.log.levels.ERROR)
        return
    end

    vim.notify("Contents of " .. config_file_path, vim.log.levels.INFO)
    for line in file:lines() do
        print(line)
    end

    file:close()
end

vim.api.nvim_create_user_command("PrintConfig", print_config_contents, {})

local function read_config(key, default_value)
  local value = default_value
  local key_lower = key:lower()

  for line in io.lines(config_file_path) do
    local line_lower = line:lower()
    if line_lower:match("^" .. key_lower .. ":") then
      value = line:match(key .. ": (%S+)")
      if value then
        value = value:match("^%s*(.-)%s*$") -- Trim leading and trailing whitespace
      end
      if not value or value == "" then
        value = default_value
      end
      break
    end
  end

  return value
end

-- Check if DebugPrint is enabled
function M.should_debug_print()
  local debug_print = read_config("DebugPrint", "false")
  return debug_print:lower() == "true"
end

-- Check if prioritizing build scripts is enabled
function M.should_prioritize_build_script()
  local prioritize = read_config("PrioritizeBuildScript", "false")
  return prioritize:lower() == "true"
end

function M.use_file_picker_for_commands()
  local use_file_picker = read_config("UseFilePickerForCommands", "false")
  return use_file_picker:lower() == "true"
end

function M.get_py_command()
  return read_config("PythonExecCommand", "gpt")
end

function CyclePythonExecCommand()
  local possible_commands = { "read_file", "gpt", "claude/claude", "gemini/gemini", "mistral/mistral" }
  local current_command = read_config("PythonExecCommand", "gpt")

  -- Identify current index, then rotate to the next
  local current_index = nil
  for i, cmd in ipairs(possible_commands) do
    if cmd == current_command then
      current_index = i
      break
    end
  end

  local next_index = current_index % #possible_commands + 1
  local new_command = possible_commands[next_index]

  -- Rewrite config file with the new command
  local lines = {}
  local command_updated = false

  for line in io.lines(config_file_path) do
    if line:match("^PythonExecCommand:") then
      table.insert(lines, "PythonExecCommand: " .. new_command)
      command_updated = true
    else
      table.insert(lines, line)
    end
  end

  -- If there's no existing command, append it
  if not command_updated then
    table.insert(lines, "PythonExecCommand: " .. new_command)
  end

  -- Write changes back to the file
  local file = io.open(config_file_path, "w")
  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()

  print("New PythonExecCommand: " .. new_command)
end

vim.api.nvim_create_user_command('CyclePythonExecCommand', CyclePythonExecCommand, {})

function ToggleBooleanSetting(settingKey)
  local lines = {}
  local current_value = "false"
  local updated = false

  for line in io.lines(config_file_path) do
    if line:match("^" .. settingKey .. ":") then
      current_value = line:match(settingKey .. ": (%S+)")
      local new_value = current_value:lower() == "true" and "false" or "true"
      table.insert(lines, settingKey .. ": " .. new_value)
      updated = true
    else
      table.insert(lines, line)
    end
  end

  -- If the key wasn't found, append it with a true value
  if not updated then
    table.insert(lines, settingKey .. ": true")
  end

  -- Write changes back to file
  local file = io.open(config_file_path, "w")
  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()

  local new_value = current_value:lower() == "true" and "false" or "true"
  print(settingKey .. " toggled to: " .. new_value)
end

function TogglePrioritizeBuildScript()
  ToggleBooleanSetting("PrioritizeBuildScript")
end

function ToggleDebugPrint()
  ToggleBooleanSetting("DebugPrint")
end

function ToggleUseFilePickerForCommands()
  ToggleBooleanSetting("UseFilePickerForCommands")
end

vim.api.nvim_create_user_command('TogglePrioritizeBuildScript', TogglePrioritizeBuildScript, {})
vim.api.nvim_create_user_command('ToggleDebugPrint', ToggleDebugPrint, {})
vim.api.nvim_create_user_command('ToggleUseFilePickerForCommands', ToggleUseFilePickerForCommands, {})

-- Dynamic filepicker selection
local FilePicker = {
  FZF = "fzf",
  FZF_LUA = "fzf_lua",
  TELESCOPE = "telescope"
}

M.FilePicker = FilePicker

function M.get_file_picker()
  return read_config("SelectedFilePicker", FilePicker.TELESCOPE):lower()
end

local function CycleFilePicker()
  local possible_file_pickers = {
    FilePicker.FZF,
    FilePicker.FZF_LUA,
    FilePicker.TELESCOPE
  }

  local current_picker = read_config("SelectedFilePicker", FilePicker.TELESCOPE)

  local current_index = nil
  for i, picker in ipairs(possible_file_pickers) do
    if picker == current_picker then
      current_index = i
      break
    end
  end

  if not current_index then
    current_index = 1
  end

  -- Cycle to the next index (wrap-around using modulo arithmetic)
  local next_index = current_index % #possible_file_pickers + 1
  local new_picker = possible_file_pickers[next_index]

  local lines = {}
  local picker_updated = false

  for line in io.lines(config_file_path) do
    if line:match("^SelectedFilePicker:") then
      table.insert(lines, "SelectedFilePicker: " .. new_picker)
      picker_updated = true
    else
      table.insert(lines, line)
    end
  end

  if not picker_updated then
    table.insert(lines, "SelectedFilePicker: " .. new_picker)
  end

  -- Write the updated lines back to the config file
  local file = io.open(config_file_path, "w")
  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()

  print("New file picker selected: " .. new_picker)
end

vim.api.nvim_create_user_command('CycleFilePicker', CycleFilePicker, {})

return M -- Return the module table

