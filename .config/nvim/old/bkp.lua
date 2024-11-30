function save_buffers()
  local buf_list = vim.api.nvim_list_bufs()
  local file = io.open(vim.fn.expand("~/.vim/sessions/s_buffers.vim"), "w")

  for _, buf in ipairs(buf_list) do
    if vim.api.nvim_buf_get_option(buf, "buflisted") and vim.api.nvim_buf_get_option(buf, "modified") == false then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        file:write(buf_name .. "\n")
      end
    end
  end

  file:close()
  print("Buffers saved to ~/.vim/sessions/s_buffers.vim")
end

function save_active_buffers()
  local tab_count = vim.fn.tabpagenr('$')
  if tab_count > 2 then
    local file = io.open(vim.fn.expand("~/.vim/sessions/s_buffers.vim"), "w")
    local active_buffers = {}
    local current_tab = vim.fn.tabpagenr()

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      active_buffers[buf] = true
    end

    for buf, _ in pairs(active_buffers) do
      if vim.api.nvim_buf_get_option(buf, "buflisted") and vim.api.nvim_buf_get_option(buf, "modified") == false then
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name ~= "" then
          file:write(vim.fn.expand(buf_name, ':p') .. "\n")
        end
      end
    end

    file:write("TAB:" .. current_tab .. "\n")
    file:close()
    print("Active buffers and current tab saved to ~/.vim/sessions/s_buffers.vim")
    vim.cmd("mks! ~/.vim/sessions/s.vim")
  else
    print("Not saving: Less than 3 tabs are open.")
  end
end

-- Function to open each buffer in a separate tab
function load_buffers_old()
  local file = io.open(vim.fn.expand("~/.vim/sessions/s_buffers.vim"), "r")

  if file == nil then
    print("No saved buffers found!")
    return
  end

  local tab_count = 0

  for line in file:lines() do
    vim.cmd("tabnew " .. line)
    tab_count = tab_count + 1
  end

  file:close()

  if tab_count > 1 then
    vim.cmd("2tabnext")
  end
end

function load_buffers()
  local file = io.open(vim.fn.expand("~/.vim/sessions/s_buffers.vim"), "r")

  if file == nil then
    print("No saved buffers found!")
    return
  end

  local lines = {}
  local my_notes_path = vim.fn.getenv("my_notes_path")
  my_notes_path = my_notes_path:gsub("\\", "/") -- Normalize the path
  local saved_tab = 1 

  -- Read and filter lines
  for line in file:lines() do
    if line:match("^TAB:") then
      saved_tab = tonumber(line:sub(5))
    else
      -- Trim whitespace and normalize slashes
      line = line:gsub("\\", "/"):gsub("^%s*(.-)%s*$", "%1")

      if line ~= "" then
        table.insert(lines, line)
      end
    end
  end

  file:close()

  -- Custom sorting logic
  table.sort(lines, function(a, b)
    -- Prioritize lines starting with my_notes_path
    local a_starts_with_notes = a:find(my_notes_path, 1, true) == 1
    local b_starts_with_notes = b:find(my_notes_path, 1, true) == 1

    if a_starts_with_notes and not b_starts_with_notes then
      return true
    elseif not a_starts_with_notes and b_starts_with_notes then
      return false
    elseif a_starts_with_notes and b_starts_with_notes then
      -- Within my_notes_path, prioritize urls.txt, then wow.txt, then pf.txt
      if a:match("urls%.txt$") and not b:match("urls%.txt$") then
        return true
      elseif not a:match("urls%.txt$") and b:match("urls%.txt$") then
        return false
      elseif a:match("wow%.txt$") and not b:match("wow%.txt$") then
        return true
      elseif not a:match("wow%.txt$") and b:match("wow%.txt$") then
        return false
      elseif a:match("pf%.txt$") and not b:match("pf%.txt$") then
        return true
      elseif not a:match("pf%.txt$") and b:match("pf%.txt$") then
        return false
      end
    end

    -- Finally, order by extension (.cpp, .js, .sql)
    local a_ext = a:match("^.+(%..+)$")
    local b_ext = b:match("^.+(%..+)$")

    local ext_order = {[".cpp"] = 1, [".js"] = 2, [".sql"] = 3}
    local a_order = ext_order[a_ext] or 999
    local b_order = ext_order[b_ext] or 999

    if a_order ~= b_order then
      return a_order < b_order
    else
      -- If the extensions are the same or not recognized, sort alphabetically
      return a < b
    end
  end)

  -- Load buffers in the sorted order
  local tab_count = 0
  for _, line in ipairs(lines) do
    if tab_count == 0 then
      vim.cmd("edit " .. line)
    else
      vim.cmd("tabnew " .. line)
    end
    tab_count = tab_count + 1
  end

  if tab_count > 1 then
    --vim.cmd("2tabnext")
    vim.cmd(saved_tab .. "tabnext")
  end
end

-- vim.api.nvim_set_keymap('n', '<leader>m', ':lua save_buffers()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>m', ':lua save_active_buffers()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>.', ':lua load_buffers()<CR>', { noremap = true, silent = true })

-----------
function enter_vimgrep_command(pattern)
    local git_root = get_git_root()
    git_root = git_root:gsub('\\', '/')
    git_root = git_root:gsub('/+', '/')

    local cmd = string.format(':vimgrep //g "%s/%s"', git_root, pattern)
    local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)

    vim.api.nvim_feedkeys(keys, 'n', true)

    vim.schedule(function()
        local additional_keys = vim.api.nvim_replace_termcodes('<C-f><Esc>0f/li', true, false, true)
        vim.api.nvim_feedkeys(additional_keys, 'n', true)
    end)
end

vim.keymap.set( 'n', '<M-f>', function() enter_vimgrep_command('**/*.txt') end, { noremap = true, silent = true })
vim.keymap.set( 'n', '<M-g>', function() enter_vimgrep_command('**/*.*') end, { noremap = true, silent = true })
vim.keymap.set( 'n', '<M-G>', function() enter_vimgrep_command('**/.*') end, { noremap = true, silent = true })

-----------
local function get_current_buffer_extension()
    if vim.bo.filetype == '' and vim.fn.expand('%') == '' then
        -- vim.notify("Current buffer is not associated with a file.", vim.log.levels.WARN)
        return nil
    end

    local extension = vim.fn.fnamemodify(vim.fn.expand('%'), ':e')
    return extension
end

local function get_git_root()
    local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
    git_root = vim.trim(git_root)

    if vim.v.shell_error ~= 0 then
        -- vim.notify("Not inside a Git repository.", vim.log.levels.ERROR)
        -- return nil
        return vim.fn.getcwd()
    end

    return git_root
end


function VimGrepSearch(param)
    local git_root = get_git_root()
    git_root = git_root:gsub('\\', '/')
    git_root = git_root:gsub('/+', '/')

    local extension = get_current_buffer_extension()
    if not extension then
        extension = '.txt'
    end
    local pattern = '**/*.' .. extension

    local cmd = string.format(':vimgrep /%s/g %s/%s', param, git_root, pattern)
    -- print(cmd)
    vim.cmd(cmd)
end

function enter_vimgrep_command_feed()
    local cmd = string.format(':lua VimGrepSearch("")')
    local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
    vim.api.nvim_feedkeys(keys, 'n', true)

    vim.schedule(function()
        local additional_keys = vim.api.nvim_replace_termcodes('<Left><Left>', true, false, true)
        vim.api.nvim_feedkeys(additional_keys, 'n', true)
    end)
end

vim.keymap.set('n', '<M-f>', function()
    enter_vimgrep_command_feed()
end, { noremap = true, silent = true })

