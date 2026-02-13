require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path
local ps_profile_path = myconfig.ps_profile_path

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
  -- bind c-w-h: move_or_split left (n)
  vim.keymap.set('n', '<C-w>h', function() move_or_split('h') end, { noremap = true, silent = true })
  -- bind c-w-j: move_or_split down (n)
  vim.keymap.set('n', '<C-w>j', function() move_or_split('j') end, { noremap = true, silent = true })
  -- bind c-w-k: move_or_split up (n)
  vim.keymap.set('n', '<C-w>k', function() move_or_split('k') end, { noremap = true, silent = true })
  -- bind c-w-l: move_or_split right (n)
  vim.keymap.set('n', '<C-w>l', function() move_or_split('l') end, { noremap = true, silent = true })
  -- bind m-c-u: increase window height (n)
  myconfig.map('n', '<M-c-u>', ':resize +2<CR>')
  -- bind m-c-i: decrease window height (n)
  myconfig.map('n', '<M-c-i>', ':resize -2<CR>')
  -- bind m-c-o: increase window width (n)
  myconfig.map('n', '<M-c-o>', ':vertical resize +2<CR>')
  -- bind m-c-y: decrease window width (n)
  myconfig.map('n', '<M-c-y>', ':vertical resize -2<CR>')
end

if term_program ~= "wezterm" then
  --myconfig.map('n', '<M-h>', '<Plug>WinMoveLeft')
  --myconfig.map('n', '<M-j>', '<Plug>WinMoveDown')
  --myconfig.map('n', '<M-k>', '<Plug>WinMoveUp')
  --myconfig.map('n', '<M-l>', '<Plug>WinMoveRight')
  -- bind m-h: move_or_split left (n)
  vim.keymap.set('n', '<M-h>', function() move_or_split('h') end, { noremap = true, silent = true })
  -- bind m-j: move_or_split down (n)
  vim.keymap.set('n', '<M-j>', function() move_or_split('j') end, { noremap = true, silent = true })
  -- bind m-k: move_or_split up (n)
  vim.keymap.set('n', '<M-k>', function() move_or_split('k') end, { noremap = true, silent = true })
  -- bind m-l: move_or_split right (n)
  vim.keymap.set('n', '<M-l>', function() move_or_split('l') end, { noremap = true, silent = true })
  -- bind m-u: increase window height (n)
  myconfig.map('n', '<M-u>', ':resize +2<CR>')
  -- bind m-i: decrease window height (n)
  myconfig.map('n', '<M-i>', ':resize -2<CR>')
  -- bind m-o: increase window width (n)
  myconfig.map('n', '<M-o>', ':vertical resize +2<CR>')
  -- bind m-y: decrease window width (n)
  myconfig.map('n', '<M-y>', ':vertical resize -2<CR>')
end

-- Navigate splits in terminal
-- bind m-h: navigate to left split (t)
myconfig.map('t', '<M-h>', [[<C-\><C-n><C-w>h]])
-- bind m-j: navigate to down split (t)
myconfig.map('t', '<M-j>', [[<C-\><C-n><C-w>j]])
-- bind m-k: navigate to up split (t)
myconfig.map('t', '<M-k>', [[<C-\><C-n><C-w>k]])
-- bind m-l: navigate to right split (t)
myconfig.map('t', '<M-l>', [[<C-\><C-n><C-w>l]])
-- bind m-q: quit terminal (t)
myconfig.map('t', '<M-q>', [[<C-\><C-n>:q<CR>]])
-- bind esc: exit terminal mode (t)
myconfig.map('t', '<Esc>', [[<C-\><C-n>]])

--map('n', '<leader>z', '<Plug>Zoom')
-- bind leader-z: toggle window zoom (n)
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

-- Tab keybinds

-- bind m-t: new tab (n)
myconfig.map('n', '<M-t>', ':tabe<CR>')
--myconfig.map('n', '<M-s>', ':split<CR>')
-- bind m-enter: vertical split with terminal (n)
myconfig.map('n', '<M-Enter>', ':vsp | terminal ' .. (vim.loop.os_uname().sysname == "Windows_NT" and "powershell" or "") .. '<CR>')
-- bind m-<: horizontal split with terminal (n)
myconfig.map('n', '<M-<>', ':split | terminal ' .. (vim.loop.os_uname().sysname == "Windows_NT" and "powershell" or "") .. '<CR>')
--if vim.fn.has('win32') == 1 and vim.fn.exists('g:GuiLoaded') == 1 then
--if vim.fn.has('win32') == 1 and vim.g.neovide then
--myconfig.map('n', '<M-Enter>', ':10 sp :let $VIM_DIR=expand("%:p:h")<CR>:terminal<CR>cd $VIM_DIR<CR>')
--end

-- Go to tab by number
-- bind m-0-9: go to tab x (n)
myconfig.map('n', '<M-1>', '1gt')
myconfig.map('n', '<M-2>', '2gt')
myconfig.map('n', '<M-3>', '3gt')
myconfig.map('n', '<M-4>', '4gt')
myconfig.map('n', '<M-5>', '5gt')
myconfig.map('n', '<M-6>', '6gt')
myconfig.map('n', '<M-7>', '7gt')
myconfig.map('n', '<M-8>', '8gt')
myconfig.map('n', '<M-9>', '9gt')
myconfig.map('n', '<M-0>', ':tablast<CR>')
myconfig.map('n', '<leader>o', '<C-^>')

-- Open new tabs
-- bind m-m: open nvim init.lua (n)
myconfig.map('n', '<M-m>', ':tabe ~/.config/nvim/init.lua<CR>')
-- bind m-,: open zshrc (n)
myconfig.map('n', '<M-,>', ':tabe ~/.zshrc<CR>')
-- bind m-.: open vimtutor notes (n)
myconfig.map('n', '<M-.>', '<cmd>tabe ' .. my_notes_path .. '/vimtutor.txt<CR>')

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

-- bind m-;: open terminal-specific text file (n)
vim.keymap.set("n", "<M-;>", function()
  local file_prefix = get_file_prefix()
  local file_path = myconfig.home_dir .. file_prefix .. "_text.txt"
  vim.cmd("tabe " .. file_path)
end, { noremap = true, silent = true })

-- Windows
if vim.fn.has('win32') == 1 then
  -- bind m-m: open nvim init.lua (n)
  vim.api.nvim_set_keymap('n', '<M-m>', '<cmd>tabe ' .. vim.fn.expand('$LOCALAPPDATA') .. '/nvim/init.lua<CR>', { noremap = true, silent = true })
  -- bind m-,: open PowerShell profile (n)
  vim.api.nvim_set_keymap('n', '<M-,>', '<cmd>tabe ' .. ps_profile_path .. '/Microsoft.PowerShell_profile.ps1<CR>', { noremap = true, silent = true })
end

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

-- bind leader-tl: goto_last_tab (n)
vim.api.nvim_set_keymap('n', '<leader>tl', '<cmd>lua goto_last_tab()<CR>', { noremap = true, silent = true })
-- bind leader-tl: goto_last_tab (v)
vim.api.nvim_set_keymap('v', '<leader>tl', '<cmd>lua goto_last_tab()<CR>', { noremap = true, silent = true })

-- Merge with right tab
--myconfig.map('n', '<leader>tm', ':Tabmerge right<CR>')
-- lua tabmerge
local function tab_merge()
  local current = vim.fn.tabpagenr()
  local total = vim.fn.tabpagenr('$')

  if current == total then
    print("No next tab to merge.")
    return
  end

  vim.cmd("tabnext " .. (current + 1))
  local buffer_to_merge = vim.fn.bufnr('%')

  vim.cmd("tabnext " .. current)
  vim.cmd("vsplit")
  vim.cmd("buffer " .. buffer_to_merge)
  vim.cmd("tabclose " .. (current + 1))
end

-- bind leader-tm: tab_merge (n)
vim.keymap.set('n', '<leader>tm', tab_merge, { noremap = true, silent = true })

-- Unbind ctrl-tab (used for wezterm and tmux)
-- bind c-tab: unbind (used for wezterm/tmux) (n)
vim.api.nvim_set_keymap('n', '<C-Tab>', '', { noremap = true, silent = true })
-- bind c-s-tab: unbind (used for wezterm/tmux) (n)
vim.api.nvim_set_keymap('n', '<C-S-Tab>', '', { noremap = true, silent = true })

-- bind leader-ts: start tmux-sessionizer (n)
vim.keymap.set("n", "<leader>ts", "<cmd>silent !tmux neww tmux-sessionizer<CR>") -- Start tmux-sessionizer

-- Wezterm split
local function replace_env_vars(path)
  return path:gsub("{(.-)}", function(var)
    return os.getenv(var) or ""
  end)
end

-- See: https://wezfurlong.org/wezterm/cli/cli/split-pane.html#synopsis
function split_pane_in_wezterm()
  local cword = vim.fn.expand("<cWORD>")
  local trimmed_cword = cword:match("([a-zA-Z]:.*)") or cword

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
    if myconfig.should_debug_print() then
      print("wezterm_command: " .. wezterm_command)
    end
    os.execute(wezterm_command)
  else
    print("Error: Invalid directory path: " .. resolved_path)
  end
end

function save_resolved_path_to_file()
  local cword = vim.fn.expand("<cWORD>")
  local trimmed_cword = cword:match("([a-zA-Z]:.*)") or cword

  local resolved_path = replace_env_vars(trimmed_cword)
  resolved_path = vim.fn.fnamemodify(resolved_path, ":p:h")
  resolved_path = resolved_path:gsub("\\", "/")

  local file_path = myconfig.home_dir .. "/new_wez_dir.txt"

  local file = io.open(file_path, "w")
  if file then
    file:write(resolved_path .. "\n")
    file:close()
    print("Resolved path saved to: " .. file_path)
  else
    print("Error: Could not open file for writing: " .. file_path)
  end
end

-- bind leader-dw: split_pane_in_wezterm (n)
vim.api.nvim_set_keymap('n', '<leader>dw', ':lua split_pane_in_wezterm()<CR>', { noremap = true, silent = true })
-- bind c-w-d: save_resolved_path_to_file (n)
vim.api.nvim_set_keymap('n', '<C-w>d', ':lua save_resolved_path_to_file()<CR>', { noremap = true, silent = true })

