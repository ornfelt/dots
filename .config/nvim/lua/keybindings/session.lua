local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path

-- Session management
function load_session()
  local session_dir = vim.fn.expand('~/.vim/sessions/')
  local pattern = 's*.vim'
  local session_files = vim.fn.globpath(session_dir, pattern, 0, 1)

  if #session_files == 0 then
    print("No session files found in " .. session_dir)
    return
  end

  -- Extract session and indices
  local sessions = {}
  local index = 0
  for _, filepath in ipairs(session_files) do
    local filename = vim.fn.fnamemodify(filepath, ':t')
    -- Exclude files with "layout" (case-insensitive)
    if not string.match(string.lower(filename), 'layout') then
      index = index + 1
      table.insert(sessions, { index = index, name = filename, path = filepath })
    end
  end

  -- Sort sessions by index
  table.sort(sessions, function(a, b) return a.index < b.index end)

  -- Build options for user selection
  local options = {}
  for _, session in ipairs(sessions) do
    local option_text = session.index .. ': ' .. session.name
    table.insert(options, option_text)
  end

  -- Prompt user to select a session
  vim.ui.select(options, { prompt = 'Select a session to load:' }, function(choice)
    if choice then
      local selected_index = choice:match('^(%d+):')
      selected_index = tonumber(selected_index)
      if selected_index then
        for _, session in ipairs(sessions) do
          if session.index == selected_index then
            vim.cmd('silent source ' .. session.path)
            -- print('Session loaded from ' .. session.path)
            return
          end
        end
      end
      print('Invalid selection.')
    else
      print('No session selected.')
    end
  end)
end

function load_session_also_works()
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
    -- Exclude files with "layout" (case-insensitive)
    if not string.match(string.lower(filename), 'layout') then
      index = index + 1
      table.insert(sessions, { idx = index, name = filename, path = filepath })
      table.insert(options, index .. ': ' .. filename)
    end
  end

  -- Prompt user to select a session
  local choice = vim.fn.inputlist(options)
  if choice > 0 and choice <= #sessions then
    local session = sessions[choice]
    vim.cmd('silent source ' .. session.path)
    --print('Session loaded from ' .. session.path)
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

-- Load session keybind
-- myconfig.map('n', '<leader>m', ':mks! ~/.vim/sessions/s.vim<CR>')
-- myconfig.map('n', '<leader>.', ':silent so ~/.vim/sessions/s.vim<CR>')
myconfig.map('n', '<leader>.', ':lua load_session()<CR>')
--myconfig.map('n', '<leader>.', ':lua load_session_also_works()<CR>')
--vim.api.nvim_set_keymap('n', '<leader>.', ':lua load_tabs_and_splits()<CR>', { noremap = true, silent = true })

-- Save session keybind
vim.api.nvim_set_keymap('n', '<leader>m', ':lua save_tabs_and_splits()<CR>', { noremap = true, silent = true })

