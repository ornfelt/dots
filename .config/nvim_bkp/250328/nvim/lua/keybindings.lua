local g   = vim.g

-- Map <leader> to space
g.mapleader = ' '
g.maplocalleader = ' '

local function map(m, k, v)
  vim.keymap.set(m, k, v, { silent = true })
end

local function normalize_path(path)
  if not path then return nil end
  -- Replace backslashes with forward slashes and remove duplicate forward slashes
  path = path:gsub("\\", "/"):gsub("//+", "/")
  return path
end

--local my_notes_path = vim.fn.getenv("my_notes_path")
--local my_notes_path = normalize_path(vim.env.my_notes_path or "")
local home_dir = normalize_path((os.getenv("HOME") or os.getenv("USERPROFILE")) .. "/")
local my_notes_path = normalize_path((os.getenv("my_notes_path") or home_dir) .. "/")
local code_root_dir = normalize_path((os.getenv("code_root_dir") or home_dir) .. "/")
local ps_profile_path = normalize_path((tostring(os.getenv("ps_profile_path")) or home_dir) .. "/")

local barhidden = false
--local function togglebar()
--    barhidden = not barhidden
--    require('lualine').hide({unhide = not barhidden})
--end
local function togglebar()
  barhidden = not barhidden
  if barhidden then
    vim.opt.laststatus = 0
  else
    vim.opt.laststatus = 2
  end
end

map('n', '<leader>b', togglebar) -- Toggle lualine

-- Fix * (Keep the cursor position, don't move to next match)
-- map('n', '*', '*N')
-- Fix n and N. Keeping cursor in center
-- map('n', 'n', 'nzz')
-- map('n', 'N', 'Nzz')

-- Mimic shell movements
map('i', '<C-E>', '<ESC>A')
map('i', '<C-A>', '<ESC>I')
map('i', '<C-v>', '<Esc>"+p')
-- map('i', '<C-a>', '<Esc>gg"yG') -- Copy everything from file into clipboard
-- map('i', '<C-BS>', '<C-W>a') -- Copy everything from file into clipboard
-- map('i', '<S-Tab>', '<BS>')
-- Undo break points
-- map('i', ',', ',<c-g>u')
-- map('i', '.', '.<c-g>u')
-- map('i', '!', '!<c-g>u')
-- map('i', '?', '?<c-g>u')

-- Make shift-insert work like in Xterm
map('i', '<S-Insert>', '<Esc><MiddleMouse>A')
map('n', '<S-Insert>', '<MiddleMouse>')

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
local function should_debug_print()
  local prioritize = read_config("DebugPrint", "false")
  return prioritize:lower() == "true"
end

--map('n', '<M-q>', ':q<CR>') -- Quit
-- Close and restore tab
local last_closed_tab = nil

local function save_and_close_tab()
  local tab_count = vim.fn.tabpagenr('$')
  if tab_count <= 1 then
    --print("Cannot save tab state: only one tab open.")
    vim.cmd("q")
    return
  end

  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  local buffers = {}

  if #windows > 1 then
    vim.cmd("q")
    return
  end

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    table.insert(buffers, {
      name = vim.api.nvim_buf_get_name(buf),
      position = vim.api.nvim_win_get_cursor(win),
    })
  end

  last_closed_tab = buffers
  vim.cmd("tabclose")
end

local function restore_tab()
  if not last_closed_tab or #last_closed_tab == 0 then
    print("No closed tab to restore.")
    return
  end

  vim.cmd("tabnew")

  local current_tab_index = vim.fn.tabpagenr()
  local total_tabs = vim.fn.tabpagenr("$")

  if current_tab_index < total_tabs then
    vim.cmd("tabmove -1")
  end

  for _, buf_data in ipairs(last_closed_tab) do
    if buf_data.name ~= "" then
      vim.cmd("edit " .. buf_data.name)
      vim.api.nvim_win_set_cursor(0, buf_data.position)
    end
  end

  last_closed_tab = nil
end

vim.keymap.set("n", "<M-q>", save_and_close_tab, { noremap = true, silent = true })
vim.keymap.set("n", "<M-S-T>", restore_tab, { noremap = true, silent = true })

map('n', '<M-z>', ':noh<CR>')
map('n', 'Y', 'y$') -- Yank till end of line

--map('x', '<leader>p', "\"_dP") -- Replace from void
map('n', '<leader>p', 'viw"_dP') -- Replace from void
map('v', '<leader>p', '"_dP') -- Replace from void
map('n', '<leader>d', '"_d') -- Delete to void
map('v', '<leader>d', '"_d') -- Delete to void

-- Paste from previous registers
map('n', '<leader>1', '"0p')
map('n', '<leader>2', '"1p')
map('n', '<leader>3', ':reg<CR>')
map('n', '<leader>4', ':put a<CR>')
map('n', '<leader>5', '"ay$')
map('v', '<leader>1', '"0p')
map('v', '<leader>2', '"1p')
map('v', '<leader>3', ':reg<CR>')
map('v', '<leader>4', ':put a<CR>')
map('v', '<leader>5', '"ay$')

local function is_plugin_installed(plugin_name)
  local status, _ = pcall(require, plugin_name)
  return status
end

local has_oil = is_plugin_installed('oil')
local has_mini_files = pcall(require, 'mini.files')

-- File tree
if has_oil then
  require('oil').setup({
    keymaps = {
      ["<C-s>"] = { "actions.select", opts = { vertical = true, close = true }, desc = "Open the entry in a vertical split" },
      ["<C-h>"] = { "actions.select", opts = { horizontal = true, close = true }, desc = "Open the entry in a horizontal split" },
      ["<C-t>"] = { "actions.select", opts = { tab = true, close = true }, desc = "Open the entry in new tab" },
    },
    view_options = {
      show_hidden = true,
    },
    -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
    skip_confirm_for_simple_edits = false,
    -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
    -- (:help prompt_save_on_select_new_entry)
    prompt_save_on_select_new_entry = true,
  })
  -- map('n', '<M-w>', ':leftabove vsplit | vertical resize 40 | Oil ~/ <CR>')
  -- map('n', '<M-w>', ':Oil ~/ <CR>')
  vim.keymap.set('n', '<M-w>', function()
    if vim.bo.filetype == 'oil' then
      -- vim.cmd('bd')
      vim.cmd('b#')
    else
      vim.cmd('Oil ~/')
    end
  end)
elseif has_mini_files then
  require('mini.files').setup()
  map('n', '<M-w>', ':lua MiniFiles.open("~/")<CR>')
end

-- vim.api.nvim_create_user_command('OilToggle', function()
-- vim.cmd((vim.bo.filetype == 'oil') and 'bd' or 'Oil')
-- end, { nargs = 0 })

function toggle_filetree()
  local filepath = vim.fn.expand('%:p') == '' and '~/' or vim.fn.expand('%:p:h')

  -- Silly fix for making oil work with domain-based user dirs
  --if filepath:find("%.homedir") then
  if filepath:find("%.corp") then
    filepath = filepath:gsub(".*se%-jonornf%-01\\", "H:/")
    filepath = filepath:gsub(" ", "\\ ")
  else
    if not filepath:lower():find("h:") then
      filepath = "./"
    end
  end

  if should_debug_print() then
    print(filepath)
  end

  if has_oil then
    -- vim.cmd('leftabove vsplit | vertical resize 40 | Oil ' .. filepath)
    -- vim.cmd('Oil ' .. filepath)
    vim.cmd((vim.bo.filetype == 'oil') and 'b#' or 'Oil ' .. filepath)
  elseif has_mini_files then
    require('mini.files').open(filepath)
  else
    print("No file tree plugin installed...")
  end
end
map('n', '<M-e>', ':lua toggle_filetree()<CR>')

---- fzf
local fzf_vim_installed = pcall(function() return vim.fn['fzf#run'] end)
--if fzf_vim_installed then
--    ----map('n', '<M-a>', ':FZF ./<CR>')
--    --map('n', '<M-W>', ':FZF ./<CR>')
--    --map('n', '<M-A>', ':FZF ~/<CR>')
--    map('n', '<M-S>', ':FZF ' .. (vim.fn.has('unix') == 1 and '/' or 'C:/') .. '<CR>')
--end
--
---- fzf-lua
local fzf_lua_installed = pcall(require, 'fzf-lua')
--if fzf_lua_installed then
--    --local opts = { noremap = true, silent = true }
--    --vim.api.nvim_set_keymap('n', '<M-a>', ":lua require('fzf-lua').git_files()<CR>", opts)
--    --vim.api.nvim_set_keymap('n', '<M-A>', ":lua require('fzf-lua').files()<CR>", opts)
--    ----vim.api.nvim_set_keymap('n', 'M-W', ":lua require('fzf-lua').files({ cwd = os.getenv('HOME') })<CR>", opts)
--    --map('n', '<M-W>', ":lua require('fzf-lua').files({ cwd = '~/' })<CR>")
--    local root_dir = vim.fn.has('unix') == 1 and '/' or 'C:/'
--    map('n', '<M-S>', ":lua require('fzf-lua').files({ cwd = '" .. root_dir .. "' })<CR>")
--end

local use_fzf = false
local use_fzf_lua = false

if use_fzf and fzf_vim_installed then
  map('n', '<M-S>', ':FZF ' .. (vim.fn.has('unix') == 1 and '/' or 'C:/') .. '<CR>')
end

-- fzf-lua
if (use_fzf_lua or not use_fzf) and fzf_lua_installed then
  local root_dir = vim.fn.has('unix') == 1 and '/' or 'C:/'
  map('n', '<M-S>', ":lua require('fzf-lua').files({ cwd = '" .. root_dir .. "' })<CR>")
end

-- Start fzf/telescope from a given environment variable
function StartFinder(env_var, additional_path)
  local path = os.getenv(env_var) or "~/"

  if additional_path then
    path = path .. "/" .. additional_path
  end
  path = normalize_path(path)

  if use_fzf then
    -- Search using fzf.vim
    path = path:gsub(" ", '\\ ')
    vim.cmd("FZF " .. path)
  elseif use_fzf_lua then
    -- Search using fzf-lua
    local fzf_lua = require('fzf-lua')
    fzf_lua.files({ cwd = path })
  else
    -- Search using telescope
    local telescope_builtin = require('telescope.builtin')
    telescope_builtin.find_files({
      cwd = path,
      hidden = env_var == "my_notes_path",
      prompt_title = "Search in " .. path,
      previewer = true,
    })
  end
end

-- vim.api.nvim_create_user_command('RunFZFCodeRootDirWithCode', function() StartFinder("code_root_dir", "Code") end, {})
-- vim.api.nvim_set_keymap('n', '<leader>a', '<cmd>RunFZFCodeRootDirWithCode<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>a', ':lua StartFinder("code_root_dir", "Code")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>s', ':lua StartFinder("code_root_dir", "Code2")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>A', ':lua StartFinder("code_root_dir")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':lua StartFinder("my_notes_path")<CR>', { noremap = true, silent = true })

local function replace_placeholders(line)
  --  line = line:gsub("{code_root_dir}", vim.fn.getenv("code_root_dir") or "")
  -- Use gsub to find and replace all occurrences of {ENV_VAR_NAME}
  -- with corresponding environment variable value
  line = line:gsub("{(.-)}", function(env_var)
    return vim.fn.getenv(env_var) or ""
  end)
  return line
end

local function read_lines_from_file(file)
  local lines = {}
  for line in io.lines(file) do
    line = replace_placeholders(line)
    line = normalize_path(line)
    line = line:gsub("\r", "") -- Remove carriage return (^M)
    table.insert(lines, line)
  end
  return lines
end

function open_files_from_list()
  local file_path = my_notes_path .. "/files.txt"
  local files = read_lines_from_file(file_path)

  if use_fzf then
    -- Use fzf file picker to display file paths (edit/tabedit)
    vim.fn['fzf#run']({
      source = files,
      -- sink = function(selected)
      -- vim.cmd('edit ' .. selected)
      -- end,
      options = '--multi --prompt "Select a file to open> " --expect=ctrl-t',
      window = {
        width = 0.6,
        height = 0.6,
        border = 'rounded'
      },
      sinklist = function(selected)
        local key = selected[1]
        local file = selected[2]
        if key == "ctrl-t" then
          vim.cmd('tabedit ' .. file)
        else
          vim.cmd('edit ' .. file)
        end
      end
    })
  elseif use_fzf_lua then
    -- Use fzf-lua file picker to display file paths
    require('fzf-lua').fzf_exec(files, {
      prompt = 'Select a file: ',
      actions = {
        ['default'] = function(selected)
          vim.cmd('edit ' .. selected[1])
        end,
        ['ctrl-t'] = function(selected)
          vim.cmd('tabedit ' .. selected[1])
        end,
      }
    })
  else
    -- Use Telescope file picker to display file paths
    require('telescope.pickers').new({}, {
      prompt_title = "Select a file to open",
      finder = require('telescope.finders').new_table({
        results = files,
      }),
      sorter = require('telescope.config').values.generic_sorter({}),
      attach_mappings = function(_, map)
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        map('i', '<CR>', function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd('edit ' .. selection.value)
        end)

        map('i', '<C-t>', function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd('tabedit ' .. selection.value)
        end)

        map('n', '<CR>', function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd('edit ' .. selection.value)
        end)

        map('n', '<C-t>', function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd('tabedit ' .. selection.value)
        end)

        return true
      end,
    }):find()
  end
end

vim.api.nvim_set_keymap('n', '<leader>w', ':lua open_files_from_list()<CR>', { noremap = true, silent = true })

-- Vimgrep and QuickFix Lists
-- map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>0f/li')
-- map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>0f/li') -- Search all
-- map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>0f/li') -- Search dotfiles

local function get_git_root()
  local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
  git_root = vim.trim(git_root)

  if vim.v.shell_error ~= 0 then
    -- vim.notify("Not inside a Git repository.", vim.log.levels.ERROR)
    -- return nil
    return vim.fn.getcwd(), false
  end

  return git_root, true
end

function enter_vimgrep_command(pattern, use_current_word)
  --local current_word = use_current_word and vim.fn.expand("<cword>") or ""

  -- Support visual selection
  local current_word = ""
  if use_current_word then
    if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
      --current_word = vim.fn.getreg('"') -- Last yanked text
      local start_pos = vim.fn.getpos("v")
      local end_pos = vim.fn.getpos(".")
      if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
        start_pos, end_pos = end_pos, start_pos
      end

      local lines = vim.fn.getline(start_pos[2], end_pos[2])

      if #lines == 1 then
        -- Single line selection
        current_word = lines[1]:sub(start_pos[3], end_pos[3])
      else
        -- Multi-line selection, use only the last line
        --current_word = lines[#lines]:sub(1, end_pos[3])
        -- Just take current word to simplify this
        current_word = vim.fn.expand("<cword>")
      end
    else
      current_word = vim.fn.expand("<cword>")
    end
  end

  --vim.ui.input({ prompt = 'vimgrep ' .. pattern .. ': ' }, function(input)
  vim.ui.input({ prompt = 'vimgrep ' .. pattern .. ': ', default = current_word }, function(input)
    if not input or input == '' then
      --vim.notify('No search keyword provided.', vim.log.levels.WARN)
      return
    end

    local directory, is_git_repo = get_git_root()
    directory = directory:gsub('\\', '/')
    directory = directory:gsub('/+', '/')

    local cmd
    if is_git_repo then
      vim.cmd("lcd " .. directory)
      cmd = string.format(':vimgrep /%s/g `git ls-files`', input)
      -- This won't jump to first match due to 'j'
      --cmd = string.format(':vimgrep /%s/gj `git ls-files`', input)
    else
      cmd = string.format(':vimgrep /%s/g %s/%s', input, directory, pattern)
    end

    if should_debug_print() then
      print(cmd)
    end

    vim.cmd(cmd)
    --vim.cmd('copen') -- Open quickfix window
    --vim.notify(string.format('vimgrep search executed for keyword: "%s"', input), vim.log.levels.INFO)
  end)
end

local function get_current_buffer_extension()
  if vim.bo.filetype == '' and vim.fn.expand('%') == '' then
    --vim.notify("Current buffer is not associated with a file.", vim.log.levels.WARN)
    return nil
  end

  local extension = vim.fn.fnamemodify(vim.fn.expand('%'), ':e')
  return extension
end

-- vim.keymap.set( 'n', '<M-f>', function() enter_vimgrep_command('**/*.txt') end, { noremap = true, silent = true })
--vim.keymap.set('n', '<M-f>', function()
--    local extension = get_current_buffer_extension()
--    if not extension then
--        extension = '.txt'
--    end
--    local pattern = '**/*.' .. extension
--    enter_vimgrep_command(pattern)
--end, { noremap = true, silent = true })

-- Helper function to set up vimgrep command
local function setup_vimgrep_command(use_current_word)
  local extension = get_current_buffer_extension() or 'txt'
  local pattern = '**/*.' .. extension
  enter_vimgrep_command(pattern, use_current_word)
end

-- Key mappings
vim.keymap.set({ 'n', 'v' }, '<M-f>', function()
  setup_vimgrep_command(true) -- Use word under cursor or selection
end, { noremap = true, silent = true })

vim.keymap.set('n', '<M-C-f>', function()
  setup_vimgrep_command(false) -- Do not use word under cursor or selection
end, { noremap = true, silent = true })

vim.keymap.set( 'n', '<M-g>', function() enter_vimgrep_command('**/*.*', true) end, { noremap = true, silent = true })
vim.keymap.set( 'n', '<M-G>', function() enter_vimgrep_command('**/.*', true) end, { noremap = true, silent = true })

-- :vimgrep /mypattern/j *.xml *.js
-- :vimgrep /mypattern/g **/*.{c,cpp,cs}
-- The 'g' option specifies that all matches for a search will be returned instead of just one per
-- line, and the 'j' option specifies that Vim will not jump to the first match automatically.
local function construct_glob_pattern(extensions)
  return '**/*.{' .. table.concat(extensions, ',') .. '}'
end

vim.keymap.set('n', '<M-F>', function()
  local extensions = { 'c', 'cpp', 'cs', 'css', 'go', 'h', 'hpp', 'html', 'java', 'js', 'jsx', 'json', 'lua', 'php', 'py', 'rs', 'sql', 'ts', 'tsx', 'xml', 'zig' }
  local pattern = construct_glob_pattern(extensions)
  enter_vimgrep_command(pattern, true)
end, { noremap = true, silent = true })

map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>0f/li')
-- map('n', '<M-v>', ':cfdo s//x/gc<left><left><left><left><left><C-f>i')
map('n', '<M-n>', ':cnext<CR>')
map('n', '<M-p>', ':cprev<CR>')
map('n', '<M-P>', ':clast<CR>')
map('n', '<M-b>', ':copen<CR>')
map('n', '<M-B>', ':cclose<CR>')

function ToggleQuickfix()
  local is_open = false

  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      is_open = true
      break
    end
  end

  if is_open then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end
-- vim.api.nvim_set_keymap('n', '<M-b>', ':lua ToggleQuickfix()<CR>', { noremap = true, silent = true })

local function move_or_split(direction)
  if vim.fn.getcmdwintype() ~= "" then return nil end

  local current_window = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. direction) -- Try moving to given direction

  if vim.api.nvim_get_current_win() == current_window then
    -- If the window didn't change, create a new split
    if direction == "h" then
      vim.cmd("leftabove vsplit")
    elseif direction == "l" then
      vim.cmd("rightbelow vsplit")
    elseif direction == "j" then
      vim.cmd("belowright split")
    elseif direction == "k" then
      vim.cmd("aboveleft split")
    end
  end
end

-- Window management and movement
--- lua print(vim.fn.getenv("TERM_PROGRAM"))
local term_program_raw = vim.fn.getenv("TERM_PROGRAM") or ""
local term_program = tostring(term_program_raw):lower()
if term_program == "wezterm" or term_program == "tmux" then
  --vim.api.nvim_set_keymap('n', '<C-w>h', '<Plug>WinMoveLeft', { noremap = false, silent = true })
  --vim.api.nvim_set_keymap('n', '<C-w>j', '<Plug>WinMoveDown', { noremap = false, silent = true })
  --vim.api.nvim_set_keymap('n', '<C-w>k', '<Plug>WinMoveUp', { noremap = false, silent = true })
  --vim.api.nvim_set_keymap('n', '<C-w>l', '<Plug>WinMoveRight', { noremap = false, silent = true })
  vim.keymap.set('n', '<C-w>h', function() move_or_split('h') end, { noremap = true, silent = true })
  vim.keymap.set('n', '<C-w>j', function() move_or_split('j') end, { noremap = true, silent = true })
  vim.keymap.set('n', '<C-w>k', function() move_or_split('k') end, { noremap = true, silent = true })
  vim.keymap.set('n', '<C-w>l', function() move_or_split('l') end, { noremap = true, silent = true })
  map('n', '<M-c-u>', ':resize +2<CR>')
  map('n', '<M-c-i>', ':resize -2<CR>')
  map('n', '<M-c-o>', ':vertical resize +2<CR>')
  map('n', '<M-c-y>', ':vertical resize -2<CR>')
end

if term_program ~= "wezterm" then
  --map('n', '<M-h>', '<Plug>WinMoveLeft')
  --map('n', '<M-j>', '<Plug>WinMoveDown')
  --map('n', '<M-k>', '<Plug>WinMoveUp')
  --map('n', '<M-l>', '<Plug>WinMoveRight')
  vim.keymap.set('n', '<M-h>', function() move_or_split('h') end, { noremap = true, silent = true })
  vim.keymap.set('n', '<M-j>', function() move_or_split('j') end, { noremap = true, silent = true })
  vim.keymap.set('n', '<M-k>', function() move_or_split('k') end, { noremap = true, silent = true })
  vim.keymap.set('n', '<M-l>', function() move_or_split('l') end, { noremap = true, silent = true })
  map('n', '<M-u>', ':resize +2<CR>')
  map('n', '<M-i>', ':resize -2<CR>')
  map('n', '<M-o>', ':vertical resize +2<CR>')
  map('n', '<M-y>', ':vertical resize -2<CR>')
end

-- Navigate splits in terminal
map('t', '<M-h>', [[<C-\><C-n><C-w>h]])
map('t', '<M-j>', [[<C-\><C-n><C-w>j]])
map('t', '<M-k>', [[<C-\><C-n><C-w>k]])
map('t', '<M-l>', [[<C-\><C-n><C-w>l]])
map('t', '<M-q>', [[<C-\><C-n>:q<CR>]])
map('t', '<Esc>', [[<C-\><C-n>]])

map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', '<leader>l', ':Tabmerge right<CR>')

vim.api.nvim_set_keymap('n', '<C-Tab>', '', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Tab>', '', { noremap = true, silent = true })

-- Moving text
map('x', 'J', ":move '>+1<CR>gv=gv")
map('x', 'K', ":move '<-2<CR>gv=gv")
map('n', '<leader>j', ':join<CR>')
map('n', '<leader>J', ':join!<CR>')

--map('n', '<leader>z', '<Plug>Zoom')
vim.keymap.set('n', '<leader>z', function()
    local zoomed = vim.w.zoomed

    if zoomed then
        vim.cmd("wincmd =")
        vim.w.zoomed = nil
    else
        vim.cmd("wincmd _")
        vim.cmd("wincmd |")
        vim.w.zoomed = true
    end
end, { desc = "Toggle Zoom for Current Split" })

-- Indentation
map('v', '<leader><', ':le<CR>')
map('n', '<leader><', ':le<CR>')
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Tab keybinds
map('n', '<M-t>', ':tabe<CR>')
--map('n', '<M-s>', ':split<CR>')
map('n', '<M-Enter>', ':vsp | terminal ' .. (vim.loop.os_uname().sysname == "Windows_NT" and "powershell" or "") .. '<CR>')
map('n', '<M-<>', ':split | terminal ' .. (vim.loop.os_uname().sysname == "Windows_NT" and "powershell" or "") .. '<CR>')
--if vim.fn.has('win32') == 1 and vim.fn.exists('g:GuiLoaded') == 1 then
--if vim.fn.has('win32') == 1 and vim.g.neovide then
--map('n', '<M-Enter>', ':10 sp :let $VIM_DIR=expand("%:p:h")<CR>:terminal<CR>cd $VIM_DIR<CR>')
--end

-- Go to tab by number
map('n', '<M-1>', '1gt')
map('n', '<M-2>', '2gt')
map('n', '<M-3>', '3gt')
map('n', '<M-4>', '4gt')
map('n', '<M-5>', '5gt')
map('n', '<M-6>', '6gt')
map('n', '<M-7>', '7gt')
map('n', '<M-8>', '8gt')
map('n', '<M-9>', '9gt')
map('n', '<M-0>', ':tablast<CR>')
map('n', '<leader>o', '<C-^>')

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

  -- Iterate over tabs to count tabs containing "my_notes_path"
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
        local full_path = normalize_path(vim.fn.fnamemodify(buf_name, ':p'))
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
      end
    end

    if found_my_notes then
      table.insert(my_notes_tabs, i)
    end
  end

  -- Restore original tab and window
  vim.cmd(current_tab .. "tabnext")
  vim.cmd(current_win .. "wincmd w")

  -- Determine the most common final directory
  local most_common_dir = nil
  local max_count = 0
  for dir, count in pairs(dir_counts) do
    if count > max_count then
      max_count = count
      most_common_dir = dir
    end
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
        local full_path = normalize_path(vim.fn.fnamemodify(buf_name, ':p'))
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
-- map('n', '<leader>m', ':mks! ~/.vim/sessions/s.vim<CR>')
-- map('n', '<leader>.', ':silent so ~/.vim/sessions/s.vim<CR>')
map('n', '<leader>.', ':lua load_session()<CR>')
--map('n', '<leader>.', ':lua load_session_also_works()<CR>')
--vim.api.nvim_set_keymap('n', '<leader>.', ':lua load_tabs_and_splits()<CR>', { noremap = true, silent = true })

-- Save session keybind
vim.api.nvim_set_keymap('n', '<leader>m', ':lua save_tabs_and_splits()<CR>', { noremap = true, silent = true })

-- Open new tabs
map('n', '<M-m>', ':tabe ~/.config/nvim/init.lua<CR>')
map('n', '<M-,>', ':tabe ~/.zshrc<CR>')
map('n', '<M-.>', '<cmd>tabe ' .. my_notes_path .. '/vimtutor.txt<CR>')

local function get_file_prefix()
  if term_program == "wezterm" or term_program:match("xterm") or term_program == "tmux" then
    return "wez"
  elseif term_program == "alacritty" then
    return "alac"
  elseif term_program:match("^st") then
    return "st"
  else
    return "wez"
  end
end

vim.keymap.set("n", "<M-;>", function()
  local file_prefix = get_file_prefix()
  local file_path = home_dir .. file_prefix .. "_text.txt"
  vim.cmd("tabe " .. file_path)
end, { noremap = true, silent = true })

-- Windows
if vim.fn.has('win32') == 1 then
  vim.api.nvim_set_keymap('n', '<M-m>', '<cmd>tabe ' .. vim.fn.expand('$LOCALAPPDATA') .. '/nvim/init.lua<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', '<M-,>', '<cmd>tabe ' .. ps_profile_path .. '/Microsoft.PowerShell_profile.ps1<CR>', { noremap = true, silent = true })
end

-- map('n', '<C-c>', 'y')
map('v', '<C-c>', 'y')

map('n', '<leader>ws', "/\\s\\+$/<CR>") -- Show extra whitespace
map('n', '<leader>wr', ':%s/\\s\\+$<CR>') -- Remove all extra whitespace
map('n', '<leader>wu', ':%s/\\%u200b//g<CR>') -- Remove all extra unicode chars
map('n', '<leader>wb', ':%s/[[:cntrl:]]//g<CR>') -- Remove all hidden characters
--map('n', '<leader>wf', 'gqG<C-o>zz') -- Format rest of the text with vim formatting, go back and center screen
-- map('n', '<leader>wp', ':s,\\\\,/,g<CR>') -- Normalize path
function NormalizePath()
  vim.cmd('normal! 0')
  vim.cmd('silent! s,\\\\,/,g')
  vim.cmd('silent! s,/\\+,/,g')
  vim.cmd('silent! noh')
end
vim.api.nvim_set_keymap('n', '<leader>wp', ':lua NormalizePath()<CR>', { noremap = true, silent = true })

function ReplacePathBasedOnContext()
  if not my_notes_path or not code_root_dir then
    print("Environment variables 'my_notes_path' or 'code_root_dir' are not set.")
    return
  end

  local line = vim.fn.getline(".")

  -- vim.pesc will escape the string for use in Vim regular expressions
  -- It adds necessary backslashes to special chars etc.
  if line:find("{my_notes_path}/", 1, true) or line:find("{code_root_dir}/", 1, true) then
    line = line:gsub("{my_notes_path}", vim.pesc(my_notes_path))
    line = line:gsub("{code_root_dir}", vim.pesc(code_root_dir))
  else
    line = line:gsub(vim.pesc(my_notes_path), "{my_notes_path}/")
    --line = line:gsub(vim.pesc(code_root_dir), "{code_root_dir}/")
    line = line:gsub(vim.pesc(code_root_dir) .. "(/?Code)", "{code_root_dir}/%1")
  end

  if ps_profile_path then
    if line:find("{ps_profile_path}/", 1, true) then
      line = line:gsub("{ps_profile_path}", vim.pesc(ps_profile_path))
    else
      line = line:gsub(vim.pesc(ps_profile_path), "{ps_profile_path}/")
    end
  end

  line = normalize_path(line) -- Just to replace any consecutive slashes again...
  -- Update line in buffer
  vim.fn.setline(".", line)
end

vim.api.nvim_set_keymap('n', '<leader>wo', ':lua ReplacePathBasedOnContext()<CR>', { noremap = true, silent = true })

map('v', '<leader>gu', ':s/\\<./\\u&/g<CR>:noh<CR>:noh<CR>') -- Capitalize first letter of each word on visually selected line
map('n', '<leader>*', [[:/^\*\*\*$<CR>]]) -- Search for my bookmark
map('v', '<leader>%', '/\\%V') -- Search in highlighted text
-- map('v', '<leader>/', '"3y/<C-R>3<CR>') -- Search for highlighted text
map('n', '<leader>/', function()
  local clipboard_text = vim.fn.getreg('+')
  if clipboard_text ~= "" then
    vim.cmd('/' .. vim.fn.escape(clipboard_text, '\\/'))
  else
    vim.notify("Clipboard is empty!", vim.log.levels.WARN)
  end
end)
map("n", "Q", "<nop>") -- Remove Ex Mode
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Replace word under cursor
vim.keymap.set("n", "<leader>ts", "<cmd>silent !tmux neww tmux-sessionizer<CR>") -- Start tmux-sessionizer
vim.keymap.set('n', '<leader>df', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>db', '<cmd>lua vim.diagnostic.setqflist()<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>db', function()
  local current_line = vim.fn.line('.')
  vim.diagnostic.setqflist()

  --vim.defer_fn(function()
  local qf_items = vim.fn.getqflist()
  for i, item in ipairs(qf_items) do
    if item.lnum == current_line then
      vim.cmd(tostring(i) .. 'cc')
      vim.cmd('copen')
      return
    end
  end

  vim.cmd('copen')
  --end, 100)

end, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>dc', function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
  if #diagnostics > 0 then
    --local message = diagnostics[1].message
    local messages = {}
    for _, diagnostic in ipairs(diagnostics) do
      table.insert(messages, diagnostic.message)
    end

    local message = table.concat(messages, '\n')
    vim.fn.setreg('+', message)

    if should_debug_print() then
      print('Copied to clipboard:\n' .. message)
    end
  else
    print('No diagnostics on this line.')
  end
end, { noremap = true, silent = true })

-- au TabLeave * let g:lasttab = tabpagenr()
vim.api.nvim_create_autocmd("TabLeave", {
  pattern = "*",
  callback = function()
    vim.g.lasttab = vim.fn.tabpagenr()
  end,
})

function goto_last_tab()
  if vim.g.lasttab then
    vim.cmd("tabn " .. vim.g.lasttab)
  end
end

vim.api.nvim_set_keymap('n', '<leader>tl', '<cmd>lua goto_last_tab()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>tl', '<cmd>lua goto_last_tab()<CR>', { noremap = true, silent = true })

-- List tabs with telescope
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

function list_tabs()
  local tabs = {}
  for i = 1, vim.fn.tabpagenr("$") do
    --local tabname = vim.fn.gettabvar(i, "tabname", "[No Name]")
    local bufname = vim.fn.bufname(vim.fn.tabpagebuflist(i)[1]) or "[No Buffer]"
    table.insert(tabs, string.format("%d: (%s)", i, normalize_path(bufname)))
  end

  if use_fzf then
    -- fzf
    vim.fn["fzf#run"]({
      source = tabs,
      sink = function(selected)
        local index = tonumber(selected:match("^(%d+):"))
        if index then
          vim.cmd("tabnext " .. index)
        end
      end,
      options = "--prompt 'Tabs> ' --reverse",
    })
  elseif use_fzf_lua then
    -- fzf-lua
    local fzf = require("fzf-lua")
    fzf.fzf_exec(tabs, {
      prompt = "Tabs> ",
      actions = {
        ["default"] = function(selected)
          local index = tonumber(selected[1]:match("^(%d+):"))
          if index then
            vim.cmd("tabnext " .. index)
          end
        end,
      },
    })
  else
    -- Telescope
    pickers.new({}, {
      prompt_title = "Tabs",
      finder = finders.new_table({
        results = tabs,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
            index = tonumber(entry:match("Tab (%d+):")),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function on_select()
          local selected = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selected then
            vim.cmd("tabnext " .. selected.index)
          end
        end

        map("i", "<CR>", on_select)
        map("n", "<CR>", on_select)

        return true
      end,
    }):find()
  end
end

vim.api.nvim_set_keymap("n", "<M-s>", ":lua list_tabs()<CR>", { noremap = true, silent = true })

function ReplaceQuotes()
  vim.cmd([[
    silent! %s/[’‘’]/'/g
    silent! %s/[“”]/"/g
    ]])
end

vim.api.nvim_set_keymap('n', '<leader>wq', ':lua ReplaceQuotes()<CR>', { noremap = true, silent = true })

local function PythonCommand()
  vim.cmd('w') -- Save the file first
  code_root_dir = code_root_dir:gsub(" ", '" "')

  local command = "!python " .. code_root_dir .. "Code2/Python/my_py/scripts/"
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '^V' then
    --vim.cmd('normal gv')
    vim.fn.feedkeys(":" .. command)
    -- local pos = #command
    -- vim.fn.setcmdpos(pos)
  else
    local current_file = vim.fn.expand("%:p")
    local current_line = vim.fn.line(".")

    -- local send_file_end = true
    local send_file_end = false
    local last_line = send_file_end and vim.fn.line("$") or ""

    local args = ' "' .. current_file .. '" ' .. current_line
    if send_file_end then
      args = args .. " " .. last_line
    end

    local full_command = command .. args
    vim.fn.feedkeys(":" .. full_command)

    -- vim.schedule(function()
    -- -- local pos = #command + 1
    -- vim.fn.setcmdpos(pos)
    -- end)
    vim.schedule(function()
      local move_left_count = #args
      local move_left_keys = vim.api.nvim_replace_termcodes(string.rep("<Left>", move_left_count), true, false, true)
      vim.api.nvim_feedkeys(move_left_keys, "n", false)
    end)
  end
end

vim.api.nvim_create_user_command('RunPythonCommand', PythonCommand, {})
vim.api.nvim_set_keymap('v', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })

-- GPT binds
if is_plugin_installed('chatgpt') then
  local chatgpt_config = {
    openai_api_key = os.getenv("OPENAI_API_KEY"),
  }

  -- Model can be changed in actions for this plugin
  require("chatgpt").setup(chatgpt_config)

  map('n', '<leader>e', ':ChatGPTEditWithInstructions<CR>')
  map('v', '<leader>e', ':ChatGPTEditWithInstructions<CR>')
  map('n', '<leader>x', ':ChatGPTRun explain_code<CR>')
  map('v', '<leader>x', ':ChatGPTRun explain_code<CR>')
  map('n', '<leader>c', ':ChatGPTRun complete_code<CR>')
  map('v', '<leader>c', ':ChatGPTRun complete_code<CR>')
  map('n', '<leader>v', ':ChatGPTRun summarize<CR>')
  map('v', '<leader>v', ':ChatGPTRun summarize<CR>')
  map('n', '<leader>g', ':ChatGPTRun grammar_correction<CR>')
  map('v', '<leader>g', ':ChatGPTRun grammar_correction<CR>')
  map('n', '<leader>6', ':ChatGPTRun docstring<CR>')
  map('v', '<leader>6', ':ChatGPTRun docstring<CR>')
  map('n', '<leader>7', ':ChatGPTRun add_tests<CR>')
  map('v', '<leader>7', ':ChatGPTRun add_tests<CR>')
  map('n', '<leader>8', ':ChatGPTRun optimize_code<CR>')
  map('v', '<leader>8', ':ChatGPTRun optimize_code<CR>')
  map('n', '<leader>9', ':ChatGPTRun code_readability_analysis<CR>')
  map('v', '<leader>9', ':ChatGPTRun code_readability_analysis<CR>')
  map('n', '<leader>0', ':ChatGPT<CR>')
  map('v', '<leader>0', ':ChatGPT<CR>')
  map('n', '<M-c>', ':ChatGPTRun send_request<CR>')
  map('v', '<M-c>', ':ChatGPTRun send_request<CR>')
  map('i', '<M-c>', ':ChatGPTRun send_request<CR>')
end

if is_plugin_installed('gp') then
  local gp_config = {
    openai_api_key = os.getenv("OPENAI_API_KEY"),
    providers = {
      ollama = {
        disable = false,
        endpoint = "http://localhost:11434/v1/chat/completions",
        -- secret = "dummy_secret",
      },
    }
  }

  --require("gp").setup({openai_api_key: os.getenv("OPENAI_API_KEY")})
  require("gp").setup(gp_config)

  map('n', '<leader>e', ':GpAppend<CR>')
  map('v', '<leader>e', ':GpAppend<CR>')
  map('n', '<leader>x', ':GpTabnew<CR>')
  map('v', '<leader>x', ':GpTabnew<CR>')
  map('n', '<leader>c', ':GpNew<CR>')
  map('v', '<leader>c', ':GpNew<CR>')
  map('n', '<leader>v', ':GpVnew<CR>')
  map('v', '<leader>v', ':GpVnew<CR>')
  map('n', '<leader>g', ':GpRewrite<CR>')
  map('v', '<leader>g', ':GpRewrite<CR>')
  map('n', '<leader>6', ':GpImplement<CR>')
  map('v', '<leader>6', ':GpImplement<CR>')
  map('n', '<leader>7', ':GpChatRespond<CR>')
  map('v', '<leader>7', ':GpChatRespond<CR>')
  -- map('n', '<leader>8', ':GpChatFinder<CR>')
  -- map('v', '<leader>8', ':GpChatFinder<CR>')
  -- map('n', '<leader>8', ':GpContext<CR>')
  -- map('v', '<leader>8', ':GpContext<CR>')
  map('n', '<leader>8', ':GpNextAgent<CR>')
  map('v', '<leader>8', ':GpNextAgent<CR>')
  map('n', '<leader>9', ':GpChatNew<CR>')
  map('v', '<leader>9', ':GpChatNew<CR>')
  map('n', '<leader>0', ':GpChatToggle<CR>')
  map('v', '<leader>0', ':GpChatToggle<CR>')
  -- There's also:
  -- :GpAgent (for info)
  -- :GpWhisper
  -- :GpImage
  -- :GpStop
  -- etc.
end

-- Basic llama.cpp example request (no streaming)
local function llm()
  local url = "http://127.0.0.1:8080/completion"
  local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

  local json_payload = {
    temp = 0.72,
    top_k = 100,
    top_p = 0.73,
    repeat_penalty = 1.100000023841858,
    n_predict = 256,
    stop = {"\n\n\n"},
    stream = false,
    prompt = buffer_content
  }

  local curl_command = 'curl -k -s -X POST -H "Content-Type: application/json" -d @- ' .. url
  local response = vim.fn.system(curl_command, vim.fn.json_encode(json_payload))
  --local content = vim.fn.json_decode(response).content
  --local decoded_response = vim.fn.json_decode(response)
  local success, decoded_response = pcall(vim.fn.json_decode, response)
  if not success then
    decoded_response = nil
  end

  local default_msg = "llama is sleeping"
  local content = (decoded_response and decoded_response.content) or default_msg

  local split_newlines = vim.split(content, '\n', true)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
  lines[1] = lines[1] .. split_newlines[1]
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, lines)
  vim.api.nvim_buf_set_lines(0, line_num, line_num, false, vim.list_slice(split_newlines, 2))
end

vim.api.nvim_create_user_command('Llm', llm, {})

if is_plugin_installed('model') then
  local llamacpp = require('model.providers.llamacpp')

  require('model').setup({
    prompts = {
      zephyr = {
        provider = llamacpp,
        builder = function(input, context)
          return {
            prompt =
              '<|system|>'
              .. (context.args or 'You are a helpful assistant')
              .. '\n</s>\n<|user|>\n'
              .. input
              .. '</s>\n<|assistant|>',
            stop = { '</s>' }
          }
        end
      }
    }
  })

  vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
else
  vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
  vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
end

-- Helper function for setting key mappings for filetypes
local function create_hellow_mapping(ft, fe)
  code_root_dir = code_root_dir:gsub(" ", '" "')
  local template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. ft
  if fe then
    template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. fe
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local map_opts = { noremap = true, silent = true }
      vim.api.nvim_buf_set_keymap(0, 'i', 'hellow<Tab>', '<Esc>:r ' .. template_file .. '<Enter>', map_opts)
    end
  })
end

vim.keymap.set("i", "<m-+>", function()
  vim.ui.input({ prompt = "Calc: " }, function(input)
    local calc = load("return " .. (input or ""))()
    if (calc) then
      vim.api.nvim_feedkeys(tostring(calc), "i", true)
    end
  end)
end)

vim.keymap.set("v", "<m-+>", function()
  -- local start_pos = vim.fn.getpos("'<")
  -- local end_pos = vim.fn.getpos("'>")
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  local selected_text = table.concat(lines, "\n")
  local calc = load("return " .. selected_text)()
  if calc then
    vim.fn.cursor(end_pos[2], end_pos[3])
    vim.api.nvim_put({tostring(calc)}, 'l', true, true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>k', true, false, true), 'n', true)
  end
end)

vim.keymap.set("n", "<m-+>", function()
  local current_line = vim.fn.getline('.')
  local calc = load("return " .. current_line)()
  if calc then
    local line_num = vim.fn.line('.')
    vim.fn.append(line_num, tostring(calc))
    -- All of these work
    -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('j', true, false, true), 'n', true)
    -- vim.fn.cursor(line_num + 1, 0)
    vim.cmd('normal! j')
    -- vim.api.nvim_exec('normal! j', false)
    -- vim.api.nvim_command('normal! j')
  end
end)

-- Set mappings for various filetypes
create_hellow_mapping("asm")
create_hellow_mapping("c")
create_hellow_mapping("clojure", "clj")
create_hellow_mapping("cobol", "cob")
create_hellow_mapping("cpp")
create_hellow_mapping("cs")
create_hellow_mapping("dart")
create_hellow_mapping("erlang", "erl")
create_hellow_mapping("elixir", "ex")
create_hellow_mapping("fortran", "f90")
create_hellow_mapping("fsharp", "fs")
create_hellow_mapping("go")
create_hellow_mapping("groovy")
create_hellow_mapping("haskell", "hs")
create_hellow_mapping("java")
create_hellow_mapping("julia", "jl")
create_hellow_mapping("javascript", "js")
create_hellow_mapping("kotlin", "kt")
create_hellow_mapping("lua")
create_hellow_mapping("ocaml", "ml")
create_hellow_mapping("nim")
create_hellow_mapping("pascal", "pas")
create_hellow_mapping("perl", "pl")
create_hellow_mapping("php")
create_hellow_mapping("py,python", "py")
create_hellow_mapping("r")
create_hellow_mapping("ruby", "rb")
create_hellow_mapping("rust", "rs")
create_hellow_mapping("scala")
create_hellow_mapping("scheme", "scm")
create_hellow_mapping("st")
create_hellow_mapping("swift")
create_hellow_mapping("typescript", "ts")
create_hellow_mapping("vb")
create_hellow_mapping("zig")

-- Function keys mappings
map('n', '<F4>', '<Esc>:set cursorline!<CR>')
map('n', '<F5>', '<Esc>:setlocal spell! spelllang=en_us<CR>')
map('n', '<F6>', '<Esc>:setlocal spell! spelllang=sv<CR>')

local function SqlExecCommand()
  code_root_dir = code_root_dir:gsub(" ", '" "') -- Handle spaces in the path

  -- Add '/' at the end if it doesn't exist
  --if not code_root_dir:match("/$") then
  --    code_root_dir = code_root_dir .. "/"
  --end

  -- Remove '/' at the end if it exists (not necessary really)
  code_root_dir = code_root_dir:gsub("/$", "")

  local executable_net8 = code_root_dir .. '/Code2/SQL/my_sql/SqlExec/SqlExec/bin/Debug/net8.0/SqlExec.exe'
  local executable_net7 = code_root_dir .. '/Code2/SQL/my_sql/SqlExec/SqlExec/bin/Debug/net7.0/SqlExec.exe'

  if vim.fn.has('win32') == 0 then
    executable_net8 = executable_net8:gsub("%.exe$", "")
    executable_net7 = executable_net7:gsub("%.exe$", "")
  end

  local function file_exists(path)
    local stat = vim.loop.fs_stat(path)
    return stat ~= nil
  end
  local executable = file_exists(executable_net8) and executable_net8 or executable_net7

  local current_file = vim.fn.expand('%:p') -- Full path of current file
  local mode = vim.fn.mode()
  local args = { '"' .. current_file .. '"' }

  if mode == 'v' or mode == 'V' then
    -- vim.cmd('normal! gv') -- Re-select last visual selection to ensure it's active
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    if start_pos[2] >= 1 and end_pos[2] >= 1 then
      if start_pos[2] > end_pos[2] then
        -- Visual select starts from bottom
        table.insert(args, end_pos[2]) -- Start line number
        table.insert(args, start_pos[2]) -- End line number
      else
        table.insert(args, start_pos[2]) -- Start line number
        table.insert(args, end_pos[2]) -- End line number
      end
    else
      print("Invalid visual selection range.")
      return
    end
  else
    local current_line = vim.fn.line(".")
    table.insert(args, current_line)
  end

  local formatted_args = table.concat(args, " ")
  local output = vim.fn.system(executable .. " " .. formatted_args)

  vim.cmd('belowright 15new')
  local new_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(output, "\n"))
  --vim.api.nvim_buf_set_option(new_buf, "bufhidden", "wipe") -- Automatically wipe the buffer when closed
end

-- Check if prioritizing build scripts is enabled
local function should_prioritize_build_script()
  local prioritize = read_config("PrioritizeBuildScript", "false")
  return prioritize:lower() == "true"
end

local function is_prioritized_filetype(filetype)
  local prioritized_filetypes = {
    'c', 'cpp', 'cs', 'css', 'go', 'h', 'hpp', 'html',
    'java', 'js', 'jsx', 'lua', 'php', 'py', 'python',
    'rs', 'ts', 'tsx', 'zig'
  }

  for _, ft in ipairs(prioritized_filetypes) do
    if ft == filetype then
      return true
    end
  end
  return false
end

function compile_run()
  vim.cmd('w') -- Save the file first

  local filetype = vim.bo.filetype
  local is_windows = vim.fn.has('win32') == 1 -- or vim.fn.has('win16') == 1 or vim.fn.has('win64') == 1
  local build_script = is_windows and './build.ps1' or './build.sh'

  if should_prioritize_build_script() and is_prioritized_filetype(filetype) then
    local build_script_exists = vim.fn.filereadable(build_script) == 1
    if build_script_exists then
      if is_windows then
        vim.cmd('!powershell -ExecutionPolicy ByPass -File build.ps1')
      else
        vim.cmd('!bash ./build.sh')
      end
      return
    end
  end

  if filetype == 'c' then
    if is_windows then
      vim.cmd('!gcc -Wall % -o %<')
      vim.cmd('!%:r.exe')
    else
      vim.cmd('!gcc -Wall -lm -lcurl % -o %<')
      vim.cmd('!time ./%:r')
    end
  elseif filetype == 'cpp' then
    if is_windows then
      vim.cmd('!g++ -O2 -Wall % -o %< -std=c++17 -pthread')
      vim.cmd('!%:r.exe')
    else
      vim.cmd('!g++ -O2 -Wall % -o %< -std=c++17 -lcurl -lcpprest -lcrypto -lssl -lpthread')
      vim.cmd('!time ./%:r')
    end
  elseif filetype == 'java' then
    --local build_script = is_windows and './build.ps1' or './build.sh'
    --local build_script_exists = vim.fn.filereadable(build_script) == 1
    --if build_script_exists then
    --    if is_windows then
    --        vim.cmd('!powershell -ExecutionPolicy ByPass -File build.ps1')
    --    else
    --        vim.cmd('!bash ./build.sh')
    --    end
    --    return
    --end
    if is_windows then
      vim.cmd('!javac %')
      vim.cmd('!java -cp %:p:h %:t:r')
    else
      vim.cmd('!time java %')
    end
  elseif filetype == 'sh' then
    vim.cmd('!time bash %')
  elseif filetype == 'python' then
    vim.cmd(is_windows and '!python %' or '!time python %')
    -- local main_py_exists = vim.fn.filereadable('./main.py') == 1
    -- local has_main = vim.fn.search('__main__', 'nw') > 0
    -- if main_py_exists and not has_main then
    -- vim.cmd(is_windows and '!python ./main.py > test.txt' or '!time python3 ./main.py > test.txt')
    -- else
    -- vim.cmd(is_windows and '!python % > test.txt' or '!time python3 % > test.txt')
    -- end
  elseif filetype == 'html' then
    vim.cmd('!firefox % &')
  elseif filetype == 'php' then
    vim.cmd(is_windows and '!php %' or '!time php %')
  elseif filetype == 'javascript' or filetype == 'jsx' then
    vim.cmd(is_windows and '!node %' or '!time node %')
  elseif filetype == 'typescript' or filetype == 'tsx' then
    local ts_file = vim.fn.expand('%:p')
    local js_file = ts_file:gsub('%.ts$', '.js')

    --vim.cmd(is_windows and '!tsc %; node ' .. js_file or '!tsc % && time node ' .. js_file)
    --vim.cmd(is_windows and '!tsc; node ' .. js_file or '!tsc && time node ' .. js_file)

    local package_json_exists = vim.fn.filereadable('./package.json') == 1

    if package_json_exists then
      vim.cmd(is_windows and '!npm start' or '!time npm start')
    else
      --local js_file = "dist/" .. vim.fn.fnamemodify(js_file, ":t")

      if is_windows then
        vim.cmd('!tsc ' .. ts_file)
        vim.cmd('!node ' .. js_file)
      else
        vim.cmd('!tsc ' .. ts_file .. ' && time node ' .. js_file)
      end
    end

  elseif filetype == 'go' then
    vim.cmd('!go build %<')
    vim.cmd(is_windows and '!go run %' or '!time go run %')
  elseif filetype == 'rust' then
    vim.cmd('!cargo build && cargo run')
  elseif filetype == 'lua' then
    vim.cmd(is_windows and '!lua %' or '!time lua %')
  elseif filetype == 'mkd' or filetype == 'mk' then
    vim.cmd('!grip')
  elseif filetype == 'cs' or filetype == 'fs' or filetype == 'fsx' or filetype == 'fsharp' or filetype == 'vb' then
    vim.cmd('!dotnet build && dotnet run')
  elseif filetype == 'tex' or filetype == 'plaintex' then
    --vim.cmd('!pdflatex % && zathura ' .. vim.fn.expand('%:p:r') .. '.pdf &')
    vim.cmd('!pdflatex %')
    if not is_windows then
      local pdf_path = vim.fn.expand('%:p:r') .. '.pdf'
      local command = 'ps aux | grep "zathura .*' .. pdf_path .. '" | grep -v grep'
      --print("command: ", command)
      local handle = io.popen(command)
      local result = handle:read("*a")
      handle:close()
      --print("ps aux output: ", result)
      if result == "" then
        vim.cmd('!zathura ' .. pdf_path .. ' &')
      end
    end
  elseif filetype == 'sql' then
    SqlExecCommand()
  else
    print("Compilation of " .. filetype .. " extensions not configured..")
  end
end

vim.api.nvim_set_keymap('n', '<M-x>', '<Cmd>lua compile_run()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<M-x>', '<Cmd>lua compile_run()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-S-X>', '<Cmd>!chmod +x %<CR>', { noremap = true, silent = true })

-- " Execute line under the cursor
-- nnoremap <leader>, yy:@"<CR>
--vim.api.nvim_set_keymap('n', '<leader>,', 'yy:@"<CR>', { noremap = true, silent = true })
--
-- Function to execute command under cursor or highlighted text
function execute_command()
  local mode = vim.fn.mode()
  local command

  if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is for visual block mode
    -- Yank selection to "v" register
    vim.cmd('normal! "vy')
    command = vim.fn.getreg("v")
  else
    command = vim.fn.getline('.')
  end

  if should_debug_print() then
    -- Copy to clipboard
    vim.fn.setreg('+', command)
    print("Copied to clipboard: " .. command)
  else
    -- Execute it
    vim.cmd(command)
  end
end

-- Try with these:
-- lua print(vim.fn.getenv("my_notes_path"))
-- lua print(vim.fn.getenv("code_root_dir"))
-- lua print(vim.fn.getenv("ps_profile_path"))
vim.api.nvim_set_keymap('n', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })

--local actions_preview = require("actions-preview")
-- pcall for checking requirement safely
local actions_preview = pcall(require, "actions-preview") and require("actions-preview")
if actions_preview then
  vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
end

local function get_current_file_path()
  local file_path = vim.api.nvim_buf_get_name(0) -- Name of current buffer
  if file_path == "" then
    return ""
  else
    return vim.fn.fnamemodify(file_path, ":p") -- Convert to full path
  end
  --return vim.fn.expand("%:p")
end

function copy_current_file_path()
  local path = get_current_file_path()
  if path == "" then
    print("No file in current buffer")
  else
    vim.fn.setreg('+', path)
    print("Copied to clipboard: " .. path)
  end
end

local function remove_file_name(path)
  -- Use a pattern to find the last `/`, including everything up to it but not beyond
  local directory_path = path:match("(.*/)")
  if directory_path then
    return directory_path
  else
    return path -- In case there's no slash found
  end
end

function copy_current_file_path_old(replace_env)
  local path = get_current_file_path()
  if path == "" then
    print("No file in current buffer")
    return
  end

  path = normalize_path(path)
  path = path:gsub("oil:", "")

  if replace_env then
    -- Replace "my_notes_path"
    if my_notes_path then
      if my_notes_path:sub(-1) == "/" then
        my_notes_path = my_notes_path:sub(1, -2)
      end

      local pattern = "^" .. vim.pesc(my_notes_path)
      path = path:gsub(pattern, "{my_notes_path}")
    end

    -- Replace "ps_profile_path"
    if ps_profile_path then
      if ps_profile_path:sub(-1) == "/" then
        ps_profile_path = ps_profile_path:sub(1, -2)
      end

      local pattern = "^" .. vim.pesc(ps_profile_path)
      path = path:gsub(pattern, "{ps_profile_path}")
    end

    -- Replace "code_root_dir"
    if code_root_dir then
      if code_root_dir:sub(-1) == "/" then
        code_root_dir = code_root_dir:sub(1, -2)
      end

      --local pattern = "^" .. vim.pesc(code_root_dir)
      --path = path:gsub(pattern, "{code_root_dir}")
      local pattern = "^" .. vim.pesc(code_root_dir .. "/Code")
      path = path:gsub(pattern, "{code_root_dir}/Code")
    end
  else
    path = remove_file_name(path)
  end

  vim.fn.setreg('+', path)
  print("Copied to clipboard: " .. path)
end

local function replace_env(path, env, placeholder)
  if env then
    -- Remove trailing slash, if any.
    if env:sub(-1) == "/" then
      env = env:sub(1, -2)
    end

    -- Convert both strings to lowercase for a case-insensitive comparison.
    local lower_path = path:lower()
    local lower_env = env:lower()

    -- Create the pattern for matching from the start.
    local env_pattern = "^" .. vim.pesc(lower_env)

    -- If a match is found, replace the matched portion with the placeholder.
    if lower_path:find(env_pattern) then
      local env_len = #env  -- length remains the same since case doesn't affect length.
      return placeholder .. path:sub(env_len + 1)
    end
  end
  return path
end

function copy_current_file_path(replace_env_vars)
  local path = get_current_file_path()
  if path == "" then
    print("No file in current buffer")
    return
  end

  path = normalize_path(path)
  path = path:gsub("oil:", "")

  if replace_env_vars then
    path = replace_env(path, my_notes_path, "{my_notes_path}")
    path = replace_env(path, ps_profile_path, "{ps_profile_path}")

    if code_root_dir then
      local code_env = code_root_dir
      if code_env:sub(-1) == "/" then
        code_env = code_env:sub(1, -2)
      end
      local code_prefix = code_env .. "/Code"
      path = replace_env(path, code_prefix, "{code_root_dir}/Code")
    end
  else
    path = remove_file_name(path)
  end

  vim.fn.setreg('+', path)
  print("Copied to clipboard: " .. path)
end

vim.api.nvim_set_keymap('n', '<leader>-', ':lua copy_current_file_path(true)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>-', ':lua copy_current_file_path(false)<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>gl', function()
  vim.cmd('tabnew')
  require('gitgraph').draw({}, { all = true, max_count = 5000 })
end, { desc = "GitGraph - Draw" })

function PythonExecCommand()
  vim.cmd('w') -- Save the file first
  code_root_dir = code_root_dir:gsub(" ", '" "')

  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/read_file.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/gpt.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/claude/claude.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/gemini/gemini.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/mistral/mistral.py"
  local command = read_config("PythonExecCommand", "gpt")
  local script_path = code_root_dir .. "/Code2/Python/my_py/scripts/" .. command .. ".py"

  local use_debug_print = should_debug_print()

  if use_debug_print then
    print(script_path)
  end

  local print_to_current_buffer = false
  local current_file = vim.fn.expand('%:p')
  local mode = vim.fn.mode()
  local args = { '"' .. current_file .. '"' }

  if mode == 'v' or mode == 'V' then
    -- vim.cmd('normal! gv')
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    if start_pos[2] >= 1 and end_pos[2] >= 1 then
      if start_pos[2] > end_pos[2] then
        -- Visual select starts from bottom
        table.insert(args, end_pos[2]) -- Start line number
        table.insert(args, start_pos[2]) -- End line number
      else
        table.insert(args, start_pos[2]) -- Start line number
        table.insert(args, end_pos[2]) -- End line number
      end
    else
      print("Invalid visual selection range.")
      return
    end
  elseif mode == 'i' then
    local current_line = vim.fn.line(".")
    table.insert(args, current_line)
  else
    local current_line = vim.fn.line(".")
    table.insert(args, current_line)
  end

  local formatted_args = table.concat(args, " ")
  local cmd = "python " .. script_path .. " " .. formatted_args
  local output = vim.fn.system(cmd)

  if use_debug_print then
    print("args: " .. formatted_args)
  end

  if print_to_current_buffer then
    local current_buf = vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(current_buf)
    vim.api.nvim_buf_set_lines(current_buf, line_count, line_count, false, vim.split(output, "\n"))
  else
    vim.cmd('belowright 20new')
    local new_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(output, "\n"))
    -- Testing args
    -- vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(formatted_args, "\n"))
  end
end

vim.api.nvim_set_keymap('n', '<M-c>', '<cmd>lua PythonExecCommand()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<M-c>', '<cmd>lua PythonExecCommand()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<M-c>', '<cmd>lua PythonExecCommand()<CR>', { noremap = true, silent = true })

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

vim.api.nvim_create_user_command('TogglePrioritizeBuildScript', TogglePrioritizeBuildScript, {})
vim.api.nvim_create_user_command('ToggleDebugPrint', ToggleDebugPrint, {})

-- lua print(vim.fn.expand("<cWORD>"))
function open_file_with_env()
  -- local cword = vim.fn.expand("<cfile>")
  local cword = vim.fn.expand("<cWORD>")
  -- Removes everything before drive letter (may appear in diff files)
  local trimmed_cword = cword:match("([a-zA-Z]:.*)")
  if trimmed_cword ~= nil then
    cword = trimmed_cword
  end

  local use_debug_print = should_debug_print()

  -- hmmm
  cword = cword:gsub("#", "\\#")
  if use_debug_print then
    print("cword: " .. cword)
  end

  -- Remove some characters: ', ", parenthesis and brackets
  cword = cword:gsub("[\'\"(),%[%] ]", "")

  if cword:match("^a/") or cword:match("^b/") then
    --local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
    local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
    if git_root == "" then
      print("Current file is not in a Git repository.")
      return
    end

    -- Replace 'a/' or 'b/' with git root dir
    cword = cword:gsub("^[ab]/", git_root .. "/")
  end

  if cword:find("{") then
    local new_cword = cword:gsub("{(.-)}", function(var)
      local value = os.getenv(var)
      if value then
        return value
      else
        print("Environment variable " .. var .. " not found.")
        return nil
      end
    end)

    if new_cword == cword then
      return
    end

    if use_debug_print then
      print("new_cword: " .. new_cword)
    end

    -- vim.cmd("edit " .. new_cword)
    vim.cmd("tabe " .. new_cword)

  elseif cword:match(":[^/]+/") then
    -- Strip everything before colon
    local colon_index = cword:find(":[^/]+/")
    if not colon_index then
      print("Could not find env-style path after colon.")
      return
    end

    -- Trim everything before colon
    local trimmed = cword:sub(colon_index)

    -- Extract env var and path tail
    local varname, path_after = trimmed:match(":([^/]+)/(.*)")
    if not varname or not path_after then
      print("Invalid env-style path format.")
      return
    end

    local env_value = os.getenv(varname)
    if not env_value then
      print("Environment variable " .. varname .. " not found.")
      return
    end

    local new_cword = env_value .. "/" .. path_after
    new_cword = normalize_path(new_cword)

    if use_debug_print then
      print("new_cword (from :var): " .. new_cword)
    end

    vim.cmd("tabe " .. new_cword)

  else
    -- vim.cmd("edit " .. cword)
    vim.cmd("tabe " .. cword)
  end
end

vim.api.nvim_set_keymap('n', 'gf', ':lua open_file_with_env()<CR>', { noremap = true, silent = true })

function open_in_firefox()
  local cword = vim.fn.expand("<cWORD>")
  if cword:find("http") or cword:find(":") then
    vim.fn.system("firefox " .. vim.fn.shellescape(cword) .. " &")
  else
    -- cword = cword:gsub('"', ''):gsub(',', ''):gsub("'", '')
    cword = cword:match([["(.-)"]]) or cword:match([['(.-)']]) or cword
    local url = "https://github.com/" .. cword
    vim.fn.system("firefox " .. vim.fn.shellescape(url) .. " &")
  end
end

-- vim.api.nvim_set_keymap('n', 'gx', ':!open <cWORD><CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'gx', ':!nohup firefox <cWORD> &<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'gx', ':!firefox <cWORD> &<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gx', ':lua open_in_firefox()<CR>', { noremap = true, silent = true })

local function diff_copy()
  local current_buf = vim.api.nvim_get_current_buf()
  local windows = vim.api.nvim_list_wins()

  local other_buf
  for _, win in ipairs(windows) do
    if vim.api.nvim_win_get_buf(win) ~= current_buf then
      other_buf = vim.api.nvim_win_get_buf(win)
      break
    end
  end

  local file_paths = {}
  if current_buf and vim.api.nvim_buf_is_loaded(current_buf) then
    local path = vim.api.nvim_buf_get_name(current_buf)
    if path ~= "" then
      table.insert(file_paths, path)
    end
  end

  if other_buf and vim.api.nvim_buf_is_loaded(other_buf) then
    local path = vim.api.nvim_buf_get_name(other_buf)
    if path ~= "" then
      table.insert(file_paths, path)
    end
  end

  if #file_paths < 2 then
    print("Not enough files to copy.")
    return
  end

  local target_dir
  if vim.loop.os_uname().sysname == "Windows_NT" then
    target_dir = "C:/local/testing_files"
  else
    target_dir = os.getenv("HOME") .. "/Documents/local/testing_files"
  end

  vim.fn.mkdir(target_dir, "p")

  local target1 = target_dir .. "/test1.txt"
  local target2 = target_dir .. "/test2.txt"

  vim.cmd(string.format("silent !cp %s %s", vim.fn.shellescape(file_paths[1]), vim.fn.shellescape(target1)))
  vim.cmd(string.format("silent !cp %s %s", vim.fn.shellescape(file_paths[2]), vim.fn.shellescape(target2)))

  print("Files copied to " .. target_dir)
end

vim.api.nvim_create_user_command('DiffCp', diff_copy, {})

local function diff_current_lines()
  local line_number = vim.fn.line('.')
  local current_line = vim.fn.getline(line_number)
  local next_line = vim.fn.getline(line_number + 1)
  local third_line = vim.fn.getline(line_number + 2)
  local combined_lines = current_line .. "\n" .. next_line .. "\n" .. third_line

  local file_paths = {}
  local unique_paths = {}

  for prefix, path in combined_lines:gmatch('([ab])/([^\n%s]+)') do
    local full_path = path
    if vim.loop.os_uname().sysname == "Windows_NT" then
      full_path = full_path:gsub("/", "\\")
    else
      if not full_path:match("^/") then
        full_path = "/" .. full_path -- Add '/' prefix for Linux paths
      end
    end

    if not unique_paths[full_path] then
      table.insert(file_paths, full_path)
      unique_paths[full_path] = true
    end

    if #file_paths >= 2 then
      break
    end
  end

  if should_debug_print() then
    print("File paths read:")
    for i, file_path in ipairs(file_paths) do
      print(string.format("File %d: %s", i, file_path))
    end
  end

  if #file_paths < 2 then
    print("Not enough file paths found for diff.")
    return
  end

  for i, file_path in ipairs(file_paths) do
    local trimmed_fp = file_path:match("([a-zA-Z]:.*)")
    if trimmed_fp ~= nil then
      trimmed_fp = trimmed_fp:gsub("#", "\\#")
      file_paths[i] = trimmed_fp
    end
  end

  vim.cmd(string.format("edit %s", file_paths[1]))
  vim.cmd("diffthis")
  vim.cmd(string.format("vert diffsplit %s", file_paths[2]))
end

vim.api.nvim_create_user_command('Diffi', diff_current_lines, {})

local function get_default_branch()
  if vim.loop.os_uname().sysname == "Windows_NT" then
    local cmd = [[powershell -Command "(git remote show upstream | Select-String -Pattern 'HEAD branch' | ForEach-Object { $_.Line }) -replace '^.*HEAD branch: ', ''''"]]
    local output = vim.fn.system(cmd):gsub("\n", "")

    if vim.v.shell_error ~= 0 or output == "" then
      return ""
    end

    -- Extract last word (branch name)
    local branch_name = output:match("%S+$") or ""
    -- Remove any quotes or single quotes (')
    branch_name = branch_name:gsub("[\"']", "")
    return "upstream/" .. branch_name
  else
    local cmd = "git remote show upstream | grep 'HEAD branch' | awk '{print $NF}'"
    local output = vim.fn.system(cmd):gsub("\n", "")
    if vim.v.shell_error ~= 0 or output == "" or output:find("does not appear to be a git repo") then
      return ""
    end
    return "upstream/" .. output
  end
end

local function diffg_command()
  local current_file = vim.fn.expand('%:p')
  if current_file == "" then
    print("No file is currently open.")
    return
  end

  --local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
  if git_root == "" then
    print("Current file is not in a Git repository.")
    return
  end

  local use_debug_print = should_debug_print()
  if use_debug_print then
    print("git_root: " .. git_root)
  end

  -- Remove git_root and the trailing '/'
  -- (this worked with commented git_root code above on linux)
  --local relative_path = current_file:sub(#git_root + 2)

  local relative_path = current_file:sub(#git_root)
  relative_path = relative_path:gsub("^[/\\]+", "") -- Remove leading slashes
  if use_debug_print then
    print("relative_path: " .. relative_path)
  end

  --local default_branch = "upstream/npcbots_3.3.5"
  local default_branch = get_default_branch()
  local branch_name = vim.fn.input("Enter the Git branch name: ", default_branch)
  if branch_name == "" then
    print("Branch name cannot be empty.")
    return
  end

  -- Comment for now since I sometimes want to diff upstream branch
  --local _ = vim.fn.system("git show-ref --verify --quiet refs/heads/" .. branch_name)
  --if vim.v.shell_error ~= 0 then
  --  print("Branch does not exist: " .. branch_name)
  --  return
  --end

  local target_dir = vim.loop.os_uname().sysname == "Windows_NT"
      and "C:/local/testing_files"
      or os.getenv("HOME") .. "/Documents/local/testing_files"
  vim.fn.mkdir(target_dir, "p")

  local target_file1 = target_dir .. "/test1.txt"
  local target_file2 = target_dir .. "/test2.txt"

  local copy_command = string.format("cp %s %s", vim.fn.shellescape(current_file), vim.fn.shellescape(target_file1))
  vim.fn.system(copy_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to copy the current file to: " .. target_file1)
    return
  end

  local checkout_command = string.format("git show %s:%s > %s", branch_name, relative_path, target_file2)
  checkout_command = checkout_command:gsub("\\", "/"):gsub("//+", "/")

  if use_debug_print then
    print("checkout_command: " .. checkout_command)
  end

  vim.fn.system(checkout_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to checkout file from branch: " .. branch_name)
    return
  end

  if use_debug_print then
    print("File checked out to: " .. target_file2)
  end

  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(target_file2))
end

vim.api.nvim_create_user_command('Diffg', diffg_command, {})

local function is_callable(cmd)
  return vim.fn.executable(cmd) == 1
end

function format_file()
  local filetype = vim.bo.filetype

  if filetype == "json" then
    if is_callable("jq") then
      vim.cmd([[%!jq .]])
    elseif is_callable("python") then
      vim.cmd([[%!python -m json.tool]])
    else
      vim.cmd('echo "No JSON formatter available!"')
    end

  elseif filetype == "xml" then
    if is_callable("xmllint") then
      vim.cmd([[%!xmllint --format -]])
    elseif is_callable("python") then
      vim.cmd([[%!python -c "import sys, xml.dom.minidom as m; print(m.parse(sys.stdin).toprettyxml())"]])
    else
      vim.cmd('echo "No XML formatter available!"')
    end

  else
    vim.cmd('echo "Unsupported file type!"')
  end
end

vim.api.nvim_set_keymap('n', '<leader>=', ':lua format_file()<CR>', { noremap = true, silent = true })

function VisualSubstituteCommand()
  -- local mode = vim.fn.mode() -- Check mode if needed?
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  -- Ensure start_line <= end_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Leave visual mode first
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', false)
  local cmd_string = ":" .. start_line .. "," .. end_line .. "s,"
  local keys = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
  -- vim.fn.feedkeys(":" .. start_line .. "," .. end_line .. "s,")
  --local left_key = vim.api.nvim_replace_termcodes("<Left>", true, false, true)
  --vim.api.nvim_feedkeys(left_key, 'n', false)
end

vim.api.nvim_set_keymap('v', '<leader>R', '<cmd>lua VisualSubstituteCommand()<CR>', { noremap = true, silent = true })

local function VisualReplaceCommand()
  local mode = vim.fn.mode()
  if not (mode == 'v' or mode == 'V' or mode == '\22') then -- '\22' represents <C-V> (visual block)
    print("VisualReplaceCommand can only be used in visual mode.")
    return
  end

  -- Yank visually selected text into register z
  vim.cmd('noau normal! "zy')
  local selected_text = vim.fn.getreg('z')

  -- Trim any leading/trailing whitespace
  selected_text = selected_text:gsub("^%s*(.-)%s*$", "%1")

  -- Replace line breaks with spaces to handle multi-line selections
  selected_text = selected_text:gsub("\n", "\\n")

  -- Escape special characters for use in the substitution command
  -- selected_text = selected_text:gsub("([%%%^%$%(%)%%%.%[%]%*%+%-%?%|])", "\\%1")

  local cmd_string = ":%s," .. selected_text .. ","
  -- Replace termcodes to ensure special keys are interpreted correctly
  local keys = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  -- Exit visual mode by sending <Esc>
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, 'n', false)
  vim.api.nvim_feedkeys(keys, 'n', false)
end

vim.keymap.set('v', '<leader>r', function()
  VisualReplaceCommand()
end, { noremap = true, silent = true })

-- Pick a comand to run via telescope
vim.keymap.set('n', '<leader><leader>', function()
  local commands = {
    -- Packer
    { label = "PackerUpdate", cmd = "PackerUpdate" },
    { label = "PackerLoad", cmd = "PackerLoad" },
    { label = "PackerSync", cmd = "PackerSync" },
    -- Lazy
    { label = "Lazy", cmd = "Lazy" },
    -- Markview
    { label = "Markview", cmd = "Markview" },
    -- Custom
    { label = "Diffi", cmd = "Diffi" },
    { label = "Diffg", cmd = "Diffg" },
    { label = "DiffCp", cmd = "DiffCp" },
    { label = "MakefileTargets", cmd = "MakefileTargets" },
    { label = "GoLangTestFiles", cmd = "GoLangTestFiles" },
    { label = "Config - CyclePythonExecCommand", cmd = "CyclePythonExecCommand" },
    { label = "Config - TogglePrioritizeBuildScript", cmd = "TogglePrioritizeBuildScript" },
    { label = "Config - ToggleDebugPrint", cmd = "ToggleDebugPrint" },
    { label = "Config - PrintConfig", cmd = "PrintConfig" },
    { label = "Llama", cmd = "Llm" },
    -- SQL
    { label = "SqlsExecuteQuery", cmd = "SqlsExecuteQuery" },
    { label = "SqlsShowDatabases", cmd = "SqlsShowDatabases" },
    { label = "SqlsShowSchemas", cmd = "SqlsShowSchemas" },
    { label = "SqlsShowConnections", cmd = "SqlsShowConnections" },
    { label = "SqlsSwitchDatabase", cmd = "SqlsSwitchDatabase" },
    { label = "SqlsSwitchConnection", cmd = "SqlsSwitchConnection" },
    -- GP
    { label = "GpChatNew - New chat", cmd = "GpChatNew" },
    { label = "GpChatPaste - Visual chat paste", cmd = "GpChatPaste" },
    { label = "GpChatToggle - Toggle chat", cmd = "GpChatToggle" },
    { label = "GpChatFinder - Find chat history", cmd = "GpChatFinder" },
    { label = "GpChatRespond - Request a GPT response for current chat", cmd = "GpChatRespond" },
    { label = "GpChatDelete - Delete the current chat", cmd = "GpChatDelete" },
    { label = "GpRewrite - Rewrite using a prompt", cmd = "GpRewrite" },
    { label = "GpAppend - Add GPT response after current content", cmd = "GpAppend" },
    { label = "GpPrepend - Add GPT response before current content", cmd = "GpPrepend" },
    { label = "GpEnew - Add GPT response into a new buffer", cmd = "GpEnew" },
    { label = "GpNew - Add GPT response into a new horizontal split", cmd = "GpNew" },
    { label = "GpVnew - Add GPT response into a new vertical split", cmd = "GpVnew" },
    { label = "GpTabnew - Add GPT response into a new tab", cmd = "GpTabnew" },
    { label = "GpPopup - Add GPT response into a pop-up window", cmd = "GpPopup" },
    { label = "GpImplement - Use comments to develop code", cmd = "GpImplement" },
    { label = "GpContext - Provide custom context per repository", cmd = "GpContext" },
    { label = "GpWhisper - Transcribe and replace content", cmd = "GpWhisper" },
    { label = "GpWhisperRewrite - Transcribe and rewrite content", cmd = "GpWhisperRewrite" },
    { label = "GpWhisperAppend - Transcribe and append content", cmd = "GpWhisperAppend" },
    { label = "GpWhisperPrepend - Transcribe and prepend content", cmd = "GpWhisperPrepend" },
    { label = "GpWhisperEnew - Transcribe into a new buffer", cmd = "GpWhisperEnew" },
    { label = "GpWhisperPopup - Transcribe into a pop-up window", cmd = "GpWhisperPopup" },
    { label = "GpNextAgent - Switch to the next agent", cmd = "GpNextAgent" },
    { label = "GpStop - Stop all ongoing responses", cmd = "GpStop" },
    { label = "GpInspectPlugin - Inspect the GPT plugin object", cmd = "GpInspectPlugin" },
    { label = "GpChatNew - Visual new chat for selected content", cmd = "GpChatNew" },
    { label = "GpChatPaste - Visual chat paste for selection", cmd = "GpChatPaste" },
    { label = "GpChatToggle - Visual toggle chat for selection", cmd = "GpChatToggle" },
    { label = "GpRewrite - Rewrite content inline", cmd = "GpRewrite" },
    { label = "GpAppend - Append content inline", cmd = "GpAppend" },
    { label = "GpPrepend - Prepend content inline", cmd = "GpPrepend" },
    { label = "GpRewrite - Rewrite selected content", cmd = "GpRewrite" },
    { label = "GpAppend - Append after selected content", cmd = "GpAppend" },
    { label = "GpPrepend - Prepend before selected content", cmd = "GpPrepend" },
    { label = "GpPopup - Add GPT response to a visual pop-up window", cmd = "GpPopup" },
    { label = "GpEnew - Add GPT response to a visual new buffer", cmd = "GpEnew" },
    { label = "GpNew - Add GPT response to a visual horizontal split", cmd = "GpNew" },
    { label = "GpVnew - Add GPT response to a visual vertical split", cmd = "GpVnew" },
    { label = "GpTabnew - Add GPT response to a visual new tab", cmd = "GpTabnew" },
    -- ChatGPT
    { label = "ChatGPTRun Translate - Translate content", cmd = "ChatGPTRun translate" },
    { label = "ChatGPTRun Keywords - Generate keywords", cmd = "ChatGPTRun keywords" },
    { label = "ChatGPTRun Fix Bugs - Fix bugs in code", cmd = "ChatGPTRun fix_bugs" },
    { label = "ChatGPTRun Roxygen Edit - Edit Roxygen comments", cmd = "ChatGPTRun roxygen_edit" },
    { label = "ChatGPTEditWithInstructions - Edit with instructions", cmd = "ChatGPTEditWithInstructions" },
    { label = "ChatGPTRun Explain Code - Explain the code", cmd = "ChatGPTRun explain_code" },
    { label = "ChatGPTRun Complete Code - Complete selected code", cmd = "ChatGPTRun complete_code" },
    { label = "ChatGPTRun Summarize - Summarize selected content", cmd = "ChatGPTRun summarize" },
    { label = "ChatGPTRun Grammar Correction - Correct grammar", cmd = "ChatGPTRun grammar_correction" },
    { label = "ChatGPTRun Docstring - Generate docstring", cmd = "ChatGPTRun docstring" },
    { label = "ChatGPTRun Add Tests - Add tests for code", cmd = "ChatGPTRun add_tests" },
    { label = "ChatGPTRun Optimize Code - Optimize the code", cmd = "ChatGPTRun optimize_code" },
    { label = "ChatGPTRun Code Readability Analysis - Analyze code readability", cmd = "ChatGPTRun code_readability_analysis" },
    { label = "ChatGPT - Run ChatGPT for selection", cmd = "ChatGPT" },
    -- LSP
    { label = "LSP Info", cmd = "LspInfo" },
    { label = "LSP Log", cmd = "LspLog" },
    { label = "LSP Document Symbols", cmd = "lua vim.lsp.buf.document_symbol()" },
    { label = "LSP Client Attached", cmd = "lua print(vim.lsp.buf.server_ready())" },
    { label = "LSP Client Capabilities", cmd = "lua print(vim.inspect(vim.lsp.get_active_clients()[1].server_capabilities))" },
    { label = "LSP Client Name", cmd = "lua print(vim.lsp.get_active_clients()[1].name)" },
    { label = "LSP Active Clients", cmd = "lua print(vim.inspect(vim.lsp.get_active_clients()))" },
    { label = "LSP Start Client", cmd = "lua vim.lsp.start_client({ name = 'example', cmd = {'path/to/server'} })" },
    { label = "LSP Stop Client", cmd = "lua vim.lsp.stop_client(vim.lsp.get_active_clients())" },
    -- Telescope file pickers
    { label = "Telescope Find files", cmd = "lua require('telescope.builtin').find_files()" },
    { label = "Telescope Git files", cmd = "lua require('telescope.builtin').git_files()" },
    { label = "Telescope Grep string", cmd = "lua require('telescope.builtin').grep_string()" },
    { label = "Telescope Live grep", cmd = "lua require('telescope.builtin').live_grep()" },
    -- Telescope vim pickers
    { label = "Telescope Buffers", cmd = "lua require('telescope.builtin').buffers()" },
    { label = "Telescope Old files", cmd = "lua require('telescope.builtin').oldfiles()" },
    { label = "Telescope Commands", cmd = "lua require('telescope.builtin').commands()" },
    { label = "Telescope Tags", cmd = "lua require('telescope.builtin').tags()" },
    { label = "Telescope Command history", cmd = "lua require('telescope.builtin').command_history()" },
    { label = "Telescope Search history", cmd = "lua require('telescope.builtin').search_history()" },
    { label = "Telescope Help tags", cmd = "lua require('telescope.builtin').help_tags()" },
    { label = "Telescope Man pages", cmd = "lua require('telescope.builtin').man_pages()" },
    { label = "Telescope Marks", cmd = "lua require('telescope.builtin').marks()" },
    { label = "Telescope Colorscheme", cmd = "lua require('telescope.builtin').colorscheme()" },
    { label = "Telescope Quickfix", cmd = "lua require('telescope.builtin').quickfix()" },
    { label = "Telescope Loclist", cmd = "lua require('telescope.builtin').loclist()" },
    { label = "Telescope Jumplist", cmd = "lua require('telescope.builtin').jumplist()" },
    { label = "Telescope Vim options", cmd = "lua require('telescope.builtin').vim_options()" },
    { label = "Telescope Registers", cmd = "lua require('telescope.builtin').registers()" },
    { label = "Telescope Keymaps", cmd = "lua require('telescope.builtin').keymaps()" },
    { label = "Telescope Filetypes", cmd = "lua require('telescope.builtin').filetypes()" },
    { label = "Telescope Highlights", cmd = "lua require('telescope.builtin').highlights()" },
    { label = "Telescope Resume last picker", cmd = "lua require('telescope.builtin').resume()" }, -- Inception?
    { label = "Telescope Pickers", cmd = "lua require('telescope.builtin').pickers()" },
    -- Telescope LSP pickers
    { label = "Telescope LSP references", cmd = "lua require('telescope.builtin').lsp_references()" },
    { label = "Telescope LSP incoming calls", cmd = "lua require('telescope.builtin').lsp_incoming_calls()" },
    { label = "Telescope LSP outgoing calls", cmd = "lua require('telescope.builtin').lsp_outgoing_calls()" },
    { label = "Telescope LSP document symbols", cmd = "lua require('telescope.builtin').lsp_document_symbols()" },
    { label = "Telescope LSP workspace symbols", cmd = "lua require('telescope.builtin').lsp_workspace_symbols()" },
    { label = "Telescope LSP dynamic workspace symbols", cmd = "lua require('telescope.builtin').lsp_dynamic_workspace_symbols()" },
    { label = "Telescope Diagnostics", cmd = "lua require('telescope.builtin').diagnostics()" },
    { label = "Telescope LSP implementations", cmd = "lua require('telescope.builtin').lsp_implementations()" },
    { label = "Telescope LSP definitions", cmd = "lua require('telescope.builtin').lsp_definitions()" },
    { label = "Telescope LSP type definitions", cmd = "lua require('telescope.builtin').lsp_type_definitions()" },
    -- Telescope git pickers
    { label = "Telescope Git commits", cmd = "lua require('telescope.builtin').git_commits()" },
    { label = "Telescope Git branches", cmd = "lua require('telescope.builtin').git_branches()" },
    { label = "Telescope Git status", cmd = "lua require('telescope.builtin').git_status()" },
    { label = "Telescope Git stash", cmd = "lua require('telescope.builtin').git_stash()" },
    -- Telescope Treesitter pickers
    { label = "Telescope Treesitter", cmd = "lua require('telescope.builtin').treesitter()" },
    -- Telescope list pickers
    { label = "Telescope Planets", cmd = "lua require('telescope.builtin').planets()" },
    { label = "Telescope Built-in pickers", cmd = "lua require('telescope.builtin').builtin()" },
    { label = "Telescope Lua reloader", cmd = "lua require('telescope.builtin').reloader()" },
    { label = "Telescope Symbols", cmd = "lua require('telescope.builtin').symbols()" },
    -- Treesitter
    { label = "Treesitter Toggle Highlighting", cmd = "lua vim.cmd('TSBufToggle highlight')" },
    { label = "Treesitter Inspect Tree", cmd = "InspectTree" },
    { label = "Treesitter Install info", cmd = "TSInstallInfo" },
    { label = "Treesitter check health", cmd = "checkhealth nvim-treesitter" },
    -- Diagnostics
    { label = "Diagnostics Buffer ", cmd = "lua print(vim.inspect(vim.diagnostic.get(0)))" },
    { label = "Diagnostics Workspace ", cmd = "lua print(vim.inspect(vim.diagnostic.get()))" },
    { label = "Diagnostics Cursor ", cmd = "lua print(vim.inspect(vim.diagnostic.get_cursor()))" },
    -- Trouble
    { label = "Trouble diagnostics", cmd = "Trouble diagnostics" },
    { label = "Trouble fzf", cmd = "Trouble fzf" },
    { label = "Trouble fzf_files", cmd = "Trouble fzf" },
    { label = "Trouble loclist", cmd = "Trouble loclist" },
    { label = "Trouble lsp", cmd = "Trouble lsp" },
    { label = "Trouble lsp_command", cmd = "Trouble lsp_command" },
    { label = "Trouble lsp_declarations", cmd = "Trouble lsp_declarations" },
    { label = "Trouble lsp_definitions", cmd = "Trouble lsp_definitions" },
    { label = "Trouble lsp_document_symbols", cmd = "Trouble lsp_document_symbols" },
    { label = "Trouble lsp_implementations", cmd = "Trouble lsp_implementations" },
    { label = "Trouble lsp_incoming_calls", cmd = "Trouble lsp_incoming_calls" },
    { label = "Trouble lsp_outgoing_calls", cmd = "Trouble lsp_outgoing_calls" },
    { label = "Trouble lsp_references", cmd = "Trouble lsp_references" },
    { label = "Trouble lsp_type_definitions", cmd = "Trouble lsp_type_definitions" },
    { label = "Trouble qflist", cmd = "Trouble qflist" },
    { label = "Trouble quickfix", cmd = "Trouble quickfix" },
    { label = "Trouble symbols", cmd = "Trouble symbols" },
    { label = "Trouble telescope", cmd = "Trouble telescope" },
    { label = "Trouble telescope_files", cmd = "Trouble telescope_files" },
    -- General
    { label = "messages", cmd = "messages" },
    { label = "Reload Configuration", cmd = "lua vim.cmd('source ' .. vim.env.MYVIMRC)" },
    { label = "List Buffers", cmd = "lua print(vim.inspect(vim.api.nvim_list_bufs()))" },
    { label = "Buffers", cmd = "buffers" },
    { label = "undolist", cmd = "undolist" },
    { label = "Toggle Relative Numbers", cmd = "lua vim.o.relativenumber = not vim.o.relativenumber" },
    { label = "Neovim Log", cmd = "lua vim.cmd('tabedit ' .. vim.fn.stdpath('state') .. '/log')" },
    { label = "Check Health", cmd = "lua vim.cmd('checkhealth')" },
    { label = "diffthis", cmd = "windo diffthis" },
    { label = "diffoff", cmd = "windo diffoff" },
    { label = "diffget", cmd = "windo diffget" },
    { label = "diffput", cmd = "windo diffput" },
    { label = "diffpatch", cmd = "windo diffpatch" },
    { label = "diffsplit", cmd = "windo diffsplit" },
    { label = "diffdiffupdate", cmd = "windo diffdiffupdate" },
  }

  local selections_to_print = {
    ["messages"] = true,
    ["CyclePythonExecCommand"] = true,
    ["TogglePrioritizeBuildScript"] = true,
    ["ToggleDebugPrint"] = true,
    ["PrintConfig"] = true,
  }

  pickers.new({}, {
    prompt_title = "Choose Command",
    finder = finders.new_table({
      results = commands,
      entry_maker = function(entry)
        return {
          value = entry.cmd,
          display = entry.label,
          ordinal = entry.label,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),

    -- Just run the command
    --attach_mappings = function(prompt_bufnr, _)
    --  actions.select_default:replace(function()
    --    local selection = action_state.get_selected_entry()
    --    actions.close(prompt_bufnr)
    --    vim.cmd(selection.value)
    --  end)
    --  return true
    --end,

    -- Display in telescope if command starts with "lua print"
    --attach_mappings = function(prompt_bufnr, _)
    --  actions.select_default:replace(function()
    --    local selection = action_state.get_selected_entry()
    --    actions.close(prompt_bufnr)
    --    if selections_to_print[selection.value] or selection.value:match("^lua print") then
    --      local cmd_output = vim.fn.execute(selection.value)
    --
    --      require("telescope.pickers").new({}, {
    --        prompt_title = "Command Output",
    --        finder = require("telescope.finders").new_table({
    --          results = vim.split(cmd_output, "\n"),
    --        }),
    --        sorter = require("telescope.config").values.generic_sorter({}),
    --      }):find()
    --    else
    --      vim.cmd(selection.value)
    --    end
    --  end)
    --  return true
    --end

    -- Display in buffer below
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selections_to_print[selection.value] or selection.value:match("^lua print") then
          local cmd_output = vim.fn.execute(selection.value)

          vim.cmd("belowright 10split")
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_win_set_buf(0, buf)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(cmd_output, "\n"))
          -- vim.api.nvim_buf_set_option(buf, "modifiable", false)
          -- vim.api.nvim_buf_set_option(buf, "filetype", "output") -- For syntax highlighting
          vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe") -- Automatically wipe the buffer when closed
          -- vim.api.nvim_win_set_option(0, "number", false) -- Disable line numbers in the split
        else
          vim.cmd(selection.value)
        end
      end)
      return true
    end

  }):find()
end, { noremap = true, silent = true })

-- Pick a comand to run via ui.select
--vim.keymap.set('n', '<leader><leader>', function()
--  local commands = {
--    { label = "PackerUpdate", cmd = "PackerUpdate" },
--    { label = "PackerLoad", cmd = "PackerLoad" },
--    { label = "PackerSync", cmd = "PackerSync" },
--  }
--
--  local choices = {}
--  for _, item in ipairs(commands) do
--    table.insert(choices, item.label)
--  end
--
--  vim.ui.select(choices, { prompt = "Choose Command:" }, function(choice)
--    if choice then
--      for _, item in ipairs(commands) do
--        if item.label == choice then
--          vim.cmd(item.cmd)
--          return
--        end
--      end
--    end
--  end)
--end, { noremap = true, silent = true })

-- Pick a comand to run via vim command menu
--vim.keymap.set('n', '<leader><leader>', function()
--  local choice = vim.fn.inputlist({
--    "Choose Command:",
--    "1. PackerUpdate",
--    "2. PackerLoad",
--    "3. PackerSync",
--  })
--
--  if choice == 1 then
--    vim.cmd("PackerUpdate")
--  elseif choice == 2 then
--    vim.cmd("PackerLoad")
--  elseif choice == 3 then
--    vim.cmd("PackerSync")
--  end
--end, { noremap = true, silent = true })

-- Read and display keybinds from a file
local function read_lines_from_file(file_path)
  local lines = {}
  for line in io.lines(file_path) do
    table.insert(lines, line)
  end
  return lines
end

vim.keymap.set('n', '<leader>?', function()
  local file_path = my_notes_path .. "/scripts/files/nvim_keys.txt"
  local lines = read_lines_from_file(file_path)

  -- Use Telescope picker to display lines
  require('telescope.pickers').new({}, {
    prompt_title = "Choose Line",
    finder = require('telescope.finders').new_table({
      results = lines,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),

    attach_mappings = function(prompt_bufnr, _)
      require('telescope.actions').select_default:replace(function()
        local selection = require('telescope.actions.state').get_selected_entry()
        require('telescope.actions').close(prompt_bufnr)
        print(selection.value)
      end)
      return true
    end

  }):find()
end, { noremap = true, silent = true })

function count_characters()
  local mode = vim.api.nvim_get_mode().mode
  local text = ""

  if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is for visual block mode
    -- Yank selection to "v" register
    vim.cmd('normal! "vy')
    text = vim.fn.getreg("v")
  else
    -- Word under cursor
    text = vim.fn.expand("<cword>")
  end

  local char_count = #text
  print("Character count: " .. char_count)
end

-- Keybindings for counting characters
vim.api.nvim_set_keymap("n", "<leader>cc", ":lua count_characters()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<leader>cc", "<cmd>lua count_characters()<CR>", { noremap = true, silent = true })

-- See: https://wezfurlong.org/wezterm/cli/cli/split-pane.html#synopsis
function split_pane_in_wezterm()
  local cword = vim.fn.expand("<cWORD>")
  local trimmed_cword = cword:match("([a-zA-Z]:.*)") or cword

  local function replace_env_vars(path)
    return path:gsub("{(.-)}", function(var)
      return os.getenv(var) or ""
    end)
  end

  local resolved_path = replace_env_vars(trimmed_cword)
  resolved_path = vim.fn.fnamemodify(resolved_path, ":p:h")
  -- :p (full path) converts given path to an absolute (full) path
  -- :h (head) returns the dir portion of the path (removes the file name)
  -- resolved_path will default to current dir if invalid dir...
  resolved_path = resolved_path:gsub("\\", "/")

  -- Hmm... redundant, but whatever
  -- if vim.fn.isdirectory(resolved_path) == 1 then
  if resolved_path:find("/") then
    local wezterm_command = "wezterm cli split-pane --right --percent 50 --cwd " .. vim.fn.shellescape(resolved_path)
    if should_debug_print() then
      print("wezterm_command: " .. wezterm_command)
    end
    os.execute(wezterm_command)
  else
    print("Error: Invalid directory path: " .. resolved_path)
  end
end

vim.api.nvim_set_keymap('n', '<leader>dw', ':lua split_pane_in_wezterm()<CR>', { noremap = true, silent = true })

function save_resolved_path_to_file()
  local cword = vim.fn.expand("<cWORD>")
  local trimmed_cword = cword:match("([a-zA-Z]:.*)") or cword

  local function replace_env_vars(path)
    return path:gsub("{(.-)}", function(var)
      return os.getenv(var) or ""
    end)
  end

  local resolved_path = replace_env_vars(trimmed_cword)
  resolved_path = vim.fn.fnamemodify(resolved_path, ":p:h")
  resolved_path = resolved_path:gsub("\\", "/")

  local file_path = home_dir .. "/new_wez_dir.txt"

  local file = io.open(file_path, "w")
  if file then
    file:write(resolved_path .. "\n")
    file:close()
    print("Resolved path saved to: " .. file_path)
  else
    print("Error: Could not open file for writing: " .. file_path)
  end
end

vim.api.nvim_set_keymap('n', '<C-w>d', ':lua save_resolved_path_to_file()<CR>', { noremap = true, silent = true })

local treesitter_utils = require("treesitter_utils")

-- Add async to function if using await inside function
local function add_async()
  -- Feed the "t" key back as part of the operation
  vim.api.nvim_feedkeys("t", "n", true)

  -- Get the current buffer and text before the cursor
  local buffer = vim.fn.bufnr()
  local text_before_cursor = vim.fn.getline("."):sub(vim.fn.col(".") - 4, vim.fn.col(".") - 1)

  -- Only proceed if the text before the cursor matches "awai"
  if text_before_cursor ~= "awai" then
    return
  end

  -- Get current Tree-sitter node, ignoring injections for embedded JS
  local current_node = vim.treesitter.get_node { ignore_injections = false }
  local function_node = treesitter_utils.find_node_ancestor(
    { "arrow_function", "function_declaration", "function" },
    current_node
  )
  if not function_node then
    return
  end

  -- Check if function is already "async"
  local function_text = vim.treesitter.get_node_text(function_node, 0)
  if vim.startswith(function_text, "async") then
    return
  end

  -- Add async at the start of the function
  local start_row, start_col = function_node:start()
  vim.api.nvim_buf_set_text(buffer, start_row, start_col, start_row, start_col, { "async " })
end

-- Set keybinding for JavaScript and TypeScript
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript" },
  callback = function()
    vim.keymap.set("i", "t", add_async, { buffer = true })
  end,
})

local function replace_env_paths(file_path)
  if file_path:find("{my_notes_path}/", 1, true) or file_path:find("{code_root_dir}/", 1, true) or file_path:find("{ps_profile_path}/", 1, true) then
    file_path = file_path:gsub("{my_notes_path}/", vim.pesc(my_notes_path))
    file_path = file_path:gsub("{code_root_dir}/", vim.pesc(code_root_dir))
    file_path = file_path:gsub("{ps_profile_path}/", vim.pesc(ps_profile_path))
    file_path = normalize_path(file_path)
  end
  return file_path
end

local function clean_selected_path(cwd, selected_path)
  selected_path = selected_path:match("[A-Za-z].*$") or selected_path
  if not selected_path:match("^/") and not selected_path:match("^%a:") then
    selected_path = vim.fn.fnamemodify(cwd .. "/" .. selected_path, ":p")
  end

  return normalize_path(selected_path)
end

function diff_buffers_or_file()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  local use_fzf_for_diff = false
  local use_fzf_lua_for_diff = false

  if #windows == 2 then
    vim.cmd("windo diffthis")
    print("Diff mode enabled for the two open splits.")
  else
    local file_to_diff = vim.fn.input("Enter file path or directory to diff with current buffer: ")
    if file_to_diff ~= "" then
      file_to_diff = replace_env_paths(file_to_diff)

      if vim.fn.isdirectory(file_to_diff) == 1 then
        if use_fzf_lua_for_diff then
          require('fzf-lua').files({
            cwd = file_to_diff,
            prompt = "Select a file to diff",
            actions = {
              ["default"] = function(selected_paths)
                local cwd = file_to_diff
                local selected_path = selected_paths[1]

                if selected_path then
                  print("path: " .. selected_path)
                  selected_path = clean_selected_path(cwd, selected_path)
                  print("Cleaned path: " .. selected_path)

                  vim.cmd("vsplit " .. vim.fn.fnameescape(selected_path))
                  vim.cmd("diffthis")
                  vim.cmd("windo diffthis")
                  print("Diff mode enabled for current buffer and " .. selected_path)
                else
                  print("No file selected. Diff mode aborted.")
                end
              end,
            },
          })
        elseif use_fzf_for_diff then
          vim.fn['fzf#run']({
            dir = file_to_diff,
            options = '--prompt="Select file to diff> " --reverse',
            sink = function(selected)
              local file = clean_selected_path(file_to_diff, selected)
              vim.cmd("vsplit " .. vim.fn.fnameescape(file))
              vim.cmd("diffthis | windo diffthis")
              print("Diff mode enabled for current buffer and " .. file)
            end,
            window = {
              width = 0.6,
              height = 0.6,
              border = 'rounded',
            },
          })
        else
          require('telescope.builtin').find_files({
            cwd = file_to_diff,
            prompt_title = "Select a file to diff",
            attach_mappings = function(_, map)
              map("i", "<CR>", function(prompt_bufnr)
                local selected = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)
                if selected and selected.path then
                  vim.cmd("vsplit " .. vim.fn.fnameescape(selected.path))
                  vim.cmd("diffthis")
                  vim.cmd("windo diffthis")
                  print("Diff mode enabled for current buffer and " .. selected.path)
                end
              end)
              return true
            end,
          })
        end
      elseif vim.fn.filereadable(file_to_diff) == 1 then
        vim.cmd("vsplit " .. vim.fn.fnameescape(file_to_diff))
        vim.cmd("diffthis")
        vim.cmd("windo diffthis")
        print("Diff mode enabled for current buffer and " .. file_to_diff)
      else
        print("Invalid file or directory path. Please try again.")
      end
    else
      print("No file path provided. Diff mode aborted.")
    end
  end
end

vim.api.nvim_set_keymap("n", "<leader>di", ":lua diff_buffers_or_file()<CR>", { noremap = true, silent = true })

