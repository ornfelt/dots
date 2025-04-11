local myconfig = require("myconfig")

require("keybindings.ai")
require("keybindings.commandpicker")
require("keybindings.compile")
require("keybindings.diff")
require("keybindings.filetree")
require("keybindings.formatting")
require("keybindings.fuzzy")
require("keybindings.nav")
require("keybindings.path_operations")
require("keybindings.py_exec")
require("keybindings.qf")
require("keybindings.replace")
require("keybindings.restore_tab")
require("keybindings.session")
require("keybindings.showbinds")
require("keybindings.utility")
require("keybindings.vimgrep")

-- Close tab
--myconfig.map('n', '<M-q>', ':q<CR>') -- Quit
-- See restore_tab instead (customized bind for M-q)...

-- Fix * (Keep the cursor position, don't move to next match)
-- myconfig.map('n', '*', '*N')
-- Fix n and N. Keeping cursor in center
-- myconfig.map('n', 'n', 'nzz')
-- myconfig.map('n', 'N', 'Nzz')

-- Mimic shell movements
myconfig.map('i', '<C-E>', '<ESC>A')
myconfig.map('i', '<C-A>', '<ESC>I')
myconfig.map('i', '<C-v>', '<Esc>"+p')
-- myconfig.map('i', '<C-a>', '<Esc>gg"yG') -- Copy everything from file into clipboard
-- myconfig.map('i', '<C-BS>', '<C-W>a') -- Copy everything from file into clipboard
-- myconfig.map('i', '<S-Tab>', '<BS>')
-- Undo break points
-- myconfig.map('i', ',', ',<c-g>u')
-- myconfig.map('i', '.', '.<c-g>u')
-- myconfig.map('i', '!', '!<c-g>u')
-- myconfig.map('i', '?', '?<c-g>u')

-- Make shift-insert work like in Xterm
myconfig.map('i', '<S-Insert>', '<Esc><MiddleMouse>A')
myconfig.map('n', '<S-Insert>', '<MiddleMouse>')

myconfig.map('n', '<M-z>', ':noh<CR>')
myconfig.map('n', 'Y', 'y$') -- Yank till end of line

-- Pasting
--myconfig.map('x', '<leader>p', "\"_dP") -- Replace from void
myconfig.map('n', '<leader>p', 'viw"_dP') -- Replace from void
myconfig.map('v', '<leader>p', '"_dP') -- Replace from void
myconfig.map('n', '<leader>d', '"_d') -- Delete to void
myconfig.map('v', '<leader>d', '"_d') -- Delete to void

-- Paste from previous registers
myconfig.map('n', '<leader>1', '"0p')
myconfig.map('n', '<leader>2', '"1p')
myconfig.map('n', '<leader>3', ':reg<CR>')
myconfig.map('n', '<leader>4', ':put a<CR>')
myconfig.map('n', '<leader>5', '"ay$')
myconfig.map('v', '<leader>1', '"0p')
myconfig.map('v', '<leader>2', '"1p')
myconfig.map('v', '<leader>3', ':reg<CR>')
myconfig.map('v', '<leader>4', ':put a<CR>')
myconfig.map('v', '<leader>5', '"ay$')

-- Movement
myconfig.map('n', '<C-d>', '<C-d>zz')
myconfig.map('n', '<C-u>', '<C-u>zz')

-- Moving text
myconfig.map('x', 'J', ":move '>+1<CR>gv=gv")
myconfig.map('x', 'K', ":move '<-2<CR>gv=gv")
myconfig.map('n', '<leader>j', ':join<CR>')
myconfig.map('n', '<leader>J', ':join!<CR>')

-- Indentation
myconfig.map('v', '<leader><', ':le<CR>')
myconfig.map('n', '<leader><', ':le<CR>')
myconfig.map('v', '<', '<gv')
myconfig.map('v', '>', '>gv')

-- Copy
-- myconfig.map('n', '<C-c>', 'y')
myconfig.map('v', '<C-c>', 'y')

-- Searching
myconfig.map('n', '<leader>*', [[:/^\*\*\*$<CR>]]) -- Search for my bookmark
myconfig.map('v', '<leader>%', '/\\%V') -- Search in highlighted text

-- myconfig.map('v', '<leader>/', '"3y/<C-R>3<CR>') -- Search for highlighted text
-- Search for copied text
myconfig.map('n', '<leader>/', function()
  local clipboard_text = vim.fn.getreg('+')
  if clipboard_text ~= "" then
    vim.cmd('/' .. vim.fn.escape(clipboard_text, '\\/'))
  else
    vim.notify("Clipboard is empty!", vim.log.levels.WARN)
  end
end)

myconfig.map("n", "Q", "<nop>") -- Remove Ex Mode

-- Function keys
myconfig.map('n', '<F4>', '<Esc>:set cursorline!<CR>')
myconfig.map('n', '<F5>', '<Esc>:setlocal spell! spelllang=en_us<CR>')
myconfig.map('n', '<F6>', '<Esc>:setlocal spell! spelllang=sv<CR>')

--local actions_preview = require("actions-preview")
-- pcall for checking requirement safely
local actions_preview = pcall(require, "actions-preview") and require("actions-preview")
if actions_preview then
  vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
end

local gitgraph = pcall(require, "gitgraph") and require("gitgraph")

vim.keymap.set('n', '<leader>gl', function()
  if gitgraph then
    vim.cmd('tabnew')
    gitgraph.draw({}, { all = true, max_count = 5000 })
  else
    print("GitGraph plugin is not installed")
  end
end, { desc = "GitGraph - Draw" })

