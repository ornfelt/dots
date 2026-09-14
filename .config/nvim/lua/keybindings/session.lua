require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path
local user_domain = myconfig.user_domain

local function source_session_by_name(selected_name, sessions)
  for _, session in ipairs(sessions) do
    if session.name == selected_name then
      vim.cmd('silent source ' .. session.path)
      if myconfig.should_debug_print() then
        print('Session loaded from ' .. session.path)
      end
      return true
    end
  end
  print("Invalid selection.")
  return false
end

-- Session management
function load_session()
  local session_dir = vim.fn.expand('~/.vim/sessions/')
  local pattern = 's*.vim'
  local session_files = vim.fn.globpath(session_dir, pattern, 0, 1)

  if #session_files == 0 then
    print("No session files found in " .. session_dir)
    return
  end

  local prefix_with_index = true

  -- Extract session and indices
  local sessions = {}
  local index = 0
  for _, filepath in ipairs(session_files) do
    local filename = vim.fn.fnamemodify(filepath, ':t')
    -- Exclude files with "s_layout" (case-insensitive)
    if not string.match(string.lower(filename), 's_layout') then
      index = index + 1
      table.insert(sessions, { index = index, name = filename, path = filepath })
    end
  end

  -- Sort sessions by index
  table.sort(sessions, function(a, b) return a.index < b.index end)

  -- Build options for user selection
  local options = {}
  local label_to_session_name = {}
  for _, session in ipairs(sessions) do
    local label = prefix_with_index and string.format("%d: %s", session.index, session.name) or session.name
    table.insert(options, label)
    label_to_session_name[label] = session.name
  end

  local use_file_picker = myconfig.use_file_picker_for_commands()
  local selected_file_picker = myconfig.get_file_picker()
  local use_fzf = selected_file_picker == myconfig.FilePicker.FZF
  local use_fzf_lua = selected_file_picker == myconfig.FilePicker.FZF_LUA

  if use_file_picker then
    if use_fzf then
      -- fzf
      vim.fn["fzf#run"]({
        source = options,
        sink = function(selected)
          local session_name = label_to_session_name[selected]
          source_session_by_name(session_name, sessions)
        end,
        options = "--prompt 'Session> ' --reverse",
      })
    elseif use_fzf_lua then
      -- fzf-lua
      local fzf = require("fzf-lua")
      fzf.fzf_exec(options, {
        prompt = "Session> ",
        actions = {
          ["default"] = function(selected)
            local session_name = label_to_session_name[selected[1]]
            source_session_by_name(session_name, sessions)
          end,
        },
      })
    else
      -- Telescope
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      pickers.new({}, {
        prompt_title = "Select Session",
        finder = finders.new_table({
          results = options,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry,
              ordinal = entry,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          local function on_select()
            local selected = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not selected or not selected.value then
              vim.notify("No session selected", vim.log.levels.INFO)
              return
            end
            local session_name = label_to_session_name[selected.value]
            source_session_by_name(session_name, sessions)
          end

          map("i", "<CR>", on_select)
          map("n", "<CR>", on_select)
          return true
        end,
      }):find()
    end
  else
    -- Prompt user to select a session
    vim.ui.select(options, { prompt = 'Select a session to load:' }, function(choice)
      if choice then
        local session_name = label_to_session_name[choice]
        source_session_by_name(session_name, sessions)
      else
        print('No session selected.')
      end
    end)
  end
end

-- This also works for selecting a session (uses vim.fn.inputlist)
function load_session_alt()
  local session_dir = vim.fn.expand('~/.vim/sessions/')
  local pattern = 's*.vim'
  local session_files = vim.fn.globpath(session_dir, pattern, 0, 1)

  if #session_files == 0 then
    print("No session files found in " .. session_dir)
    return
  end

  local sessions = {}
  local index = 0
  local options = { 'Select a session to load:' }
  for idx, filepath in ipairs(session_files) do
    local filename = vim.fn.fnamemodify(filepath, ':t')
    -- Exclude files with "s_layout" (case-insensitive)
    if not string.match(string.lower(filename), 's_layout') then
      index = index + 1
      table.insert(sessions, { idx = index, name = filename, path = filepath })
      table.insert(options, index .. ': ' .. filename)
    end
  end

  -- Prompt user to select a session via inputlist
  local choice = vim.fn.inputlist(options)
  if choice > 0 and choice <= #sessions then
    local session = sessions[choice]
    vim.cmd('silent source ' .. session.path)
    if myconfig.should_debug_print() then
      print('Session loaded from ' .. session.path)
    end
  else
    print('No session selected.')
  end
end

function load_tabs_and_splits()
  local file = io.open(vim.fn.expand("~/.vim/sessions/s_layout.vim"), "r")

  if file == nil then
    print("No saved layout found!")
    return
  end

  local tab_count = tonumber(file:read("*line"))
  local saved_tab = 1

  for i = 1, tab_count do
    if i > 1 then
      vim.cmd("tabnew")
    end

    local win_count = tonumber(file:read("*line"))

    for j = 1, win_count do
      if j > 1 then
        -- vim.cmd("split")
        vim.cmd("vsplit")
      end

      local buf_name = file:read("*line")
      if buf_name and buf_name ~= "" and not buf_name:match("^term://") then
        vim.cmd("edit " .. buf_name)
      end
    end
  end

  local last_line = file:read("*line")
  if last_line and last_line:match("^TAB:") then
    saved_tab = tonumber(last_line:sub(5))
  end

  file:close()

  if tab_count > 1 then
    -- vim.cmd("2tabnext")
    vim.cmd(saved_tab .. "tabnext")
  end
end

--local hardcoded_patterns = {
--  "Code/ml/llama2.c",
--  "Code/ml/llama.cpp",
--}
local function read_patterns_from_file(filepath)
  local patterns = {}
  local file = io.open(filepath, "r")
  if file then
    for line in file:lines() do
      -- Trim trailing whitespace
      line = line:gsub("%s+$", "")
      -- Only store non-empty lines
      if #line > 0 then
        table.insert(patterns, line)
      end
    end
    file:close()
  else
    print("Could not open file: " .. filepath)
  end
  return patterns
end

-- Return last n slash-delimited components joined with underscores
-- e.g.: path="Code/ml/llama.cpp", n=3 => "Code_ml_llama.cpp"
local function last_n_dirs_underscored(path, n)
  local parts = {}
  for p in path:gmatch("[^/]+") do
    table.insert(parts, p)
  end

  local total = #parts
  if total < n then
    return table.concat(parts, "_")
  end

  local slice = {}
  for i = total - n + 1, total do
    table.insert(slice, parts[i])
  end
  return table.concat(slice, "_")
end

function save_tabs_and_splits()
  local tab_count = vim.fn.tabpagenr('$')

  local save_restriction = (#my_notes_path > 0 and tab_count > 2) or (tab_count > 1)
  if not save_restriction then
    print("Not saving: Less than required tabs are open.")
    return
  end

  local my_notes_tabs = {}
  local dir_counts = {}
  local current_tab = vim.fn.tabpagenr()
  local current_win = vim.fn.winnr()

  local hard_coded_paths_file = my_notes_path .. ".vim/hard_coded_paths.txt"
  local hardcoded_patterns = read_patterns_from_file(hard_coded_paths_file)

  -- Track how often each hardcoded pattern is seen
  local pattern_counts = {}
  for _, pattern in ipairs(hardcoded_patterns) do
    pattern_counts[pattern] = 0
  end

  -- Iterate over tabs to count tabs containing "my_notes_path" and to update pattern counts
  for i = 1, tab_count do
    vim.cmd(i .. "tabnext")

    local win_count = vim.fn.winnr('$')
    local found_my_notes = false

    for j = 1, win_count do
      vim.cmd(j .. "wincmd w")
      local buf_name = vim.fn.bufname('%')
      if buf_name ~= "" then
        -- .* matches any characters up to the last /.
        -- (.-) captures the smallest sequence of characters between the last two slashes, which is the parent directory name.
        -- [^/]+$ ensures we're matching a file name (or final path component) after this last directory.
        local full_path = myconfig.normalize_path(vim.fn.fnamemodify(buf_name, ':p'))
        -- local final_dir = full_path:match(".*/(.-)/[^/]+$") or ""
        -- ([^/]+/[^/]+) captures two directory levels at the end of the path.
        -- [^/]+$ matches the filename after the last directory.
        local final_dir = full_path:match(".*/([^/]+/[^/]+)/[^/]+$") or ""
        final_dir = final_dir:gsub("/", "_")
        -- Count occurrences of the final directory
        if final_dir ~= "" then
          dir_counts[final_dir] = (dir_counts[final_dir] or 0) + 1
        end

        if full_path:find(my_notes_path, 1, true) then
          found_my_notes = true
        end

        -- Also check which of our hardcoded patterns is matched
        for _, pattern in ipairs(hardcoded_patterns) do
          if full_path:find(pattern, 1, true) then
            pattern_counts[pattern] = pattern_counts[pattern] + 1
          end
        end

      end
    end

    if found_my_notes then
      table.insert(my_notes_tabs, i)
    end
  end

  -- Restore original tab and window
  vim.cmd(current_tab .. "tabnext")
  vim.cmd(current_win .. "wincmd w")

  -- Determine if any of our hardcoded patterns surpass the threshold (≥2 files)
  local forced_subpath = nil
  local max_pattern_count = 0
  for pattern, count in pairs(pattern_counts) do
    if count >= 2 and count > max_pattern_count then
      max_pattern_count = count
      forced_subpath   = pattern
    end
  end

  -- If no forced subpath, fall back to the 'most common directory' approach
  local most_common_dir = nil
  local max_count = 0
  if not forced_subpath then
    for dir, count in pairs(dir_counts) do
      if count > max_count then
        max_count = count
        most_common_dir = dir
      end
    end
  else
    -- forced_subpath is set, so we’ll convert that path to only its last 3 directories underscored
    most_common_dir = last_n_dirs_underscored(forced_subpath, 3)
  end

  -- Determine session filenames
  local session_dir = vim.fn.expand("~/.vim/sessions/")
  local layout_filename
  local session_filename

  if #my_notes_tabs >= 2 then
    -- Use default filenames if multiple my_notes_path tabs are found
    layout_filename = session_dir .. "s_layout.vim"
    session_filename = session_dir .. "s.vim"
  else
    -- Use most common directory or find next available filenames
    if most_common_dir then
      layout_filename = session_dir .. "s_layout_" .. most_common_dir .. ".vim"
      session_filename = session_dir .. "s_" .. most_common_dir .. ".vim"
    else
      local index = 2
      while true do
        layout_filename = session_dir .. "s_layout_" .. index .. ".vim"
        session_filename = session_dir .. "s" .. index .. ".vim"
        if vim.fn.filereadable(layout_filename) == 0 and vim.fn.filereadable(session_filename) == 0 then
          break
        end
        index = index + 1
      end
    end
  end

  -- Save tabs and splits layout
  local file = io.open(layout_filename, "w")
  file:write(tab_count .. "\n")

  for i = 1, tab_count do
    vim.cmd(i .. "tabnext")

    local win_count = vim.fn.winnr('$')
    file:write(win_count .. "\n")

    for j = 1, win_count do
      vim.cmd(j .. "wincmd w")
      local buf_name = vim.fn.bufname('%')
      if buf_name ~= "" then
        local full_path = myconfig.normalize_path(vim.fn.fnamemodify(buf_name, ':p'))
        file:write(full_path .. "\n")
      end
    end
  end

  file:write("TAB:" .. current_tab .. "\n")
  file:close()

  -- Restore original tab and window
  vim.cmd(current_tab .. "tabnext")
  vim.cmd(current_win .. "wincmd w")

  print("Session data saved to " .. layout_filename)

  -- Save the session
  vim.cmd("mks! " .. session_filename)
end

local function delete_session_by_name(selected_name, sessions, session_dir, backup_dir, user_domain, use_debug_print)
  -- Find selected session
  local target
  for _, s in ipairs(sessions) do
    if s.name == selected_name then
      target = s
      break
    end
  end

  if not target then
    print("Invalid selection.")
    return
  end

  if target.name == "s.vim" then
    print("Cannot delete the default session file (s.vim).")
    return
  end

  -- Build the layout + backup paths
  local layout_name       = "s_layout" .. target.name:sub(2)
  local layout_path       = session_dir .. layout_name
  local backup_sess_name  = user_domain .. "_" .. target.name
  local backup_layout     = user_domain .. "_" .. layout_name
  local backup_sess_path  = backup_dir .. backup_sess_name
  local backup_layout_path= backup_dir .. backup_layout

  if use_debug_print then
    print("Deleting:", target.path, layout_path, backup_sess_path, backup_layout_path)
  end

  local removed = {}
  local function try_remove(path)
    local ok, err = os.remove(path)
    if ok then
      table.insert(removed, myconfig.normalize_path(path))
    elseif err:match("No such file") == nil then
      print(("Error deleting %s: %s"):format(path, err))
    end
  end

  try_remove(target.path)
  try_remove(layout_path)
  try_remove(backup_sess_path)
  try_remove(backup_layout_path)

  if #removed > 0 then
    print("Deleted:\n" .. table.concat(removed, "\n"))
  else
    print("No files were deleted.")
  end
end

function remove_session()
  local session_dir     = vim.fn.expand('~/.vim/sessions/')
  local pattern         = 's*.vim'
  local session_files   = vim.fn.globpath(session_dir, pattern, 0, 1)
  local use_debug_print = myconfig.should_debug_print()
  local backup_dir      = my_notes_path .. ".vim/"

  if #session_files == 0 then
    print("No session files found in " .. session_dir)
    return
  end

  local sessions = {}
  for _, fp in ipairs(session_files) do
    local fn = vim.fn.fnamemodify(fp, ":t")
    if not fn:lower():match("s_layout") then
      table.insert(sessions, { name = fn, path = fp })
    end
  end
  table.sort(sessions, function(a,b) return a.name < b.name end)

  local options = vim.tbl_map(function(s) return s.name end, sessions)

  local use_file_picker = myconfig.use_file_picker_for_commands()
  local picker           = myconfig.get_file_picker()
  local use_fzf          = picker == myconfig.FilePicker.FZF
  local use_fzf_lua      = picker == myconfig.FilePicker.FZF_LUA

  if use_file_picker then
    if use_fzf then
      -- fzf
      vim.fn["fzf#run"]({
        source  = options,
        sink    = function(choice)
          delete_session_by_name(choice, sessions, session_dir, backup_dir, user_domain, use_debug_print)
        end,
        options = "--prompt 'Remove> ' --reverse",
      })

    elseif use_fzf_lua then
      -- fzf-lua
      local fzf = require("fzf-lua")
      fzf.fzf_exec(options, {
        prompt  = "Remove> ",
        actions = {
          ["default"] = function(selected)
            delete_session_by_name(selected[1], sessions, session_dir, backup_dir, user_domain, use_debug_print)
          end,
        },
      })

    else
      -- Telescope
      local pickers      = require("telescope.pickers")
      local finders      = require("telescope.finders")
      local conf         = require("telescope.config").values
      local actions      = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      pickers.new({}, {
        prompt_title = "Remove Session",
        finder       = finders.new_table { results = options },
        sorter       = conf.generic_sorter({}),
        attach_mappings = function(_, map)
          local function on_ok()
            local sel = action_state.get_selected_entry().value
            actions.close(_)
            delete_session_by_name(sel, sessions, session_dir, backup_dir, user_domain, use_debug_print)
          end
          map("i", "<CR>", on_ok)
          map("n", "<CR>", on_ok)
          return true
        end,
      }):find()
    end

  else
    -- vim.ui.select fallback
    vim.ui.select(options, { prompt = "Select a session to remove:" }, function(choice)
      if choice then
        delete_session_by_name(choice, sessions, session_dir, backup_dir, user_domain, use_debug_print)
      elseif use_debug_print then
        print("No session selected.")
      end
    end)
  end
end

-- cmd RemoveSession: remove_session
vim.api.nvim_create_user_command("RemoveSession", remove_session, {})

-- Simple keybinds for saving and loading single session via file
-- myconfig.map('n', '<leader>m', ':mks! ~/.vim/sessions/s.vim<CR>')
-- myconfig.map('n', '<leader>.', ':silent so ~/.vim/sessions/s.vim<CR>')

-- Customimzed keybinds
-- bind leader-.: load_session (n)
myconfig.map('n', '<leader>.', ':lua load_session()<CR>')
--myconfig.map('n', '<leader>.', ':lua load_session_alt()<CR>')
-- This works as well (will load via session layout file instead of the one created via mksession)
--vim.api.nvim_set_keymap('n', '<leader>.', ':lua load_tabs_and_splits()<CR>', { noremap = true, silent = true })

-- Save session keybind
-- bind leader-m: save_tabs_and_splits (n)
vim.api.nvim_set_keymap('n', '<leader>m', ':lua save_tabs_and_splits()<CR>', { noremap = true, silent = true })

