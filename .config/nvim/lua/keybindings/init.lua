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
-- bind c-e: move to end of line (i)
myconfig.map('i', '<C-E>', '<ESC>A')
-- bind c-a: move to beginning of line (i)
myconfig.map('i', '<C-A>', '<ESC>I')
-- Note: This conflicts with the literal/quoted insert mode but 
-- it's accessible via ctrl-q so it shouldn't matter!
-- bind c-v: paste from system clipboard (i)
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
-- bind s-insert: paste from middle mouse (i)
myconfig.map('i', '<S-Insert>', '<Esc><MiddleMouse>A')
-- bind s-insert: paste from middle mouse (n)
myconfig.map('n', '<S-Insert>', '<MiddleMouse>')

-- bind m-z: clear search highlight (n)
myconfig.map('n', '<M-z>', ':noh<CR>')
-- bind Y: yank till end of line (n)
myconfig.map('n', 'Y', 'y$') -- Yank till end of line

-- Pasting
-- bind leader-s-p: replace word with clipboard from void register (n)
myconfig.map('n', '<leader>P', 'viw"_dP') -- Replace from void
-- bind leader-s-p: replace selection with clipboard from void register (v)
myconfig.map('v', '<leader>P', '"_dP') -- Replace from void

-- Same void/black-hole replacement as above BUT if the 
-- word/selection ends exactly at the last character on 
-- its line -> use p (append).
local function smart_replace_word_under_cursor()
  local line = vim.fn.getline('.')
  local col  = vim.fn.col('.') -- 1-based
  local L    = #line
  if L == 0 then return end
  if col > L then col = L end

  -- Treat [A-Za-z0-9_] as word chars (respects underscore)
  local function isw(i)
    if i < 1 or i > L then return false end
    return line:sub(i, i):match("[%w_]") ~= nil
  end

  -- If not on a word char, bail
  if not isw(col) then return end

  -- Find word start/end around the cursor
  local s = col
  while s > 1 and isw(s - 1) do s = s - 1 end
  local e = col
  while e < L and isw(e + 1) do e = e + 1 end

  -- "Last word" means the word ends at the very end of the line
  local is_last_word = (e == L)

  local command = is_last_word and 'viw"_dp' or 'viw"_dP'

  -- Debug
  if myconfig.should_debug_print() then
    local word = line:sub(s, e)
    print("Cursor column (1-based): ", vim.fn.col('.'))
    print("Current line: ", line)
    print("Word under cursor: ", word)
    print("Word start col: ", s)
    print("Word end col: ", e)
    print("Line length: ", L)
    print("Text after word: ", line:sub(e + 1), "<")
    print("Is last word (no chars after)?: ", is_last_word and "yes" or "no")
    print("Using command: ", command)
  end

  vim.api.nvim_feedkeys(command, 'n', false)
end

-- bind leader-p: smart_replace_word_under_cursor (n)
vim.keymap.set('n', '<leader>p', smart_replace_word_under_cursor, { noremap = true, silent = true })

-- Smart visual replace: choose p/P depending on whether the selection ends at EOL
local function smart_replace_visual_selection()
  -- start/end marks of the visual selection
  --local s = vim.fn.getpos("'<") -- {buf, lnum, col, off}
  --local e = vim.fn.getpos("'>")
  local s = vim.fn.getpos("v")
  local e = vim.fn.getpos(".")

  local srow, scol = s[2], s[3]
  local erow, ecol = e[2], e[3]

  -- normalize order (ensure s <= e)
  if erow < srow or (erow == srow and ecol < scol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  -- If multi-line (or not charwise), fallback
  local mode = vim.fn.mode()
  if mode ~= 'v' or srow ~= erow then
    return '"_dP'
  end

  local line = vim.fn.getline(srow)
  local L = #line

  -- Visual can report col beyond line end; clamp
  if ecol > L then ecol = L end

  -- "last word/selection" == ends exactly at end-of-line (no trailing chars)
  local is_last = (ecol == L)
  local cmd = is_last and '"_dp' or '"_dP'

  -- Debug
  if myconfig.should_debug_print() then
    print("VIS sel line: ", line)
    print("VIS start col, end col: ", scol, ecol)
    print("VIS line length: ", L)
    print("VIS ends at EOL? ", is_last and "yes" or "no")
    print("VIS using: ", cmd)
  end

  return cmd
end

-- bind leader-p: smart_replace_visual_selection (v)
vim.keymap.set('v', '<leader>p', smart_replace_visual_selection, { expr = true, noremap = true, silent = true })

-- bind leader-d: delete to void register (n, v)
myconfig.map('n', '<leader>d', '"_d') -- Delete to void
myconfig.map('v', '<leader>d', '"_d') -- Delete to void

-- Paste from previous registers
-- bind leader-1: paste from register 0 (n)
myconfig.map('n', '<leader>1', '"0p')
-- bind leader-2: paste from register 1 (n)
myconfig.map('n', '<leader>2', '"1p')
-- bind leader-3: show registers (n)
myconfig.map('n', '<leader>3', ':reg<CR>')
-- bind leader-4: put from register a (n)
myconfig.map('n', '<leader>4', ':put a<CR>')
-- bind leader-5: yank to register a till end of line (n)
myconfig.map('n', '<leader>5', '"ay$')
-- bind leader-1: paste from register 0 (v)
myconfig.map('v', '<leader>1', '"0p')
-- bind leader-2: paste from register 1 (v)
myconfig.map('v', '<leader>2', '"1p')
-- bind leader-3: show registers (v)
myconfig.map('v', '<leader>3', ':reg<CR>')
-- bind leader-4: put from register a (v)
myconfig.map('v', '<leader>4', ':put a<CR>')
-- bind leader-5: yank to register a till end of line (v)
myconfig.map('v', '<leader>5', '"ay$')

-- Movement
-- bind c-d: scroll down and center (n)
myconfig.map('n', '<C-d>', '<C-d>zz')
-- bind c-u: scroll up and center (n)
myconfig.map('n', '<C-u>', '<C-u>zz')

-- Moving text
-- bind s-j: move line down (x)
myconfig.map('x', 'J', ":move '>+1<CR>gv=gv")
-- bind s-k: move line up (x)
myconfig.map('x', 'K', ":move '<-2<CR>gv=gv")
-- bind leader-j: join lines (n)
myconfig.map('n', '<leader>j', ':join<CR>')
-- bind leader-s-j: join lines without space (n)
myconfig.map('n', '<leader>J', ':join!<CR>')

-- bind leader-c-j: trim, add comma, and join with next line (n)
vim.keymap.set('n', '<leader><C-j>', function()
  local line = vim.api.nvim_get_current_line()

  -- Trim trailing whitespace
  local trimmed = line:gsub("%s+$", "")

  if trimmed == "" then
    vim.notify("Current line is empty", vim.log.levels.ERROR)
    return
  end

  -- Add comma if it doesn't already end with one
  if not trimmed:match(",$") then
    trimmed = trimmed .. ","
  end

  -- Replace line with trimmed + comma
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { trimmed })

  -- join with next line
  vim.cmd("join")
end, { desc = "Trim + add comma + join", noremap = true, silent = true })

-- Indentation
-- bind leader-<: left align (v)
myconfig.map('v', '<leader><', ':le<CR>')
-- bind leader-<: left align (n)
myconfig.map('n', '<leader><', ':le<CR>')
-- bind <: dedent and reselect (v)
myconfig.map('v', '<', '<gv')
-- bind >: indent and reselect (v)
myconfig.map('v', '>', '>gv')

-- Copy
-- myconfig.map('n', '<C-c>', 'y')
-- bind c-c: copy to clipboard (v)
myconfig.map('v', '<C-c>', 'y')

-- Searching
-- bind leader-*: search for bookmark marker (n)
myconfig.map('n', '<leader>*', [[:/^\*\*\*$<CR>]]) -- Search for my bookmark
-- bind leader-%: search in highlighted text (v)
myconfig.map('v', '<leader>%', '/\\%V') -- Search in highlighted text

-- myconfig.map('v', '<leader>/', '"3y/<C-R>3<CR>') -- Search for highlighted text
-- Search for copied text
-- bind leader-/: search for clipboard text (n)
myconfig.map('n', '<leader>/', function()
  local clipboard_text = vim.fn.getreg('+')
  if clipboard_text ~= "" then
    vim.cmd('/' .. vim.fn.escape(clipboard_text, '\\/'))
  else
    vim.notify("Clipboard is empty!", vim.log.levels.WARN)
  end
end)

-- Search for 2 consecutive empty lines
--myconfig.map('n', '<leader>(', [[:/^\n^$<CR>]])
-- Search for 2 consecutive empty lines, but not at EOF
--myconfig.map('n', '<leader>(', [[:/\v(^\s*$\n){2,}\ze\_.<CR>]])
-- This should be enough?
-- bind leader-(: search for 2+ consecutive empty lines (n)
myconfig.map('n', '<leader>(', [[:/\v(^\s*$\n){2,}<CR>]])

-- diff search
--myconfig.map('n', '<leader>)', [[:/diff --<CR>]])
-- markdown code section search
-- bind leader-): search for markdown code block (n)
myconfig.map('n', '<leader>)', [[:/\`\`\`<CR>]])

-- bind s-q: disable Ex mode (n)
myconfig.map("n", "Q", "<nop>") -- Remove Ex Mode

-- Function keys
-- bind f4: toggle cursorline (n)
myconfig.map('n', '<F4>', '<Esc>:set cursorline!<CR>')
-- bind f5: toggle spell check (english) (n)
myconfig.map('n', '<F5>', '<Esc>:setlocal spell! spelllang=en_us<CR>')
-- bind f6: toggle spell check (swedish) (n)
myconfig.map('n', '<F6>', '<Esc>:setlocal spell! spelllang=sv<CR>')

--local actions_preview = require("actions-preview")
-- pcall for checking requirement safely
local actions_preview = pcall(require, "actions-preview") and require("actions-preview")
if actions_preview then
  -- bind leader-ca: code actions preview (v,n)
  vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
end

local gitgraph = pcall(require, "gitgraph") and require("gitgraph")

-- bind leader-gl: open GitGraph in new tab (n)
vim.keymap.set('n', '<leader>gl', function()
  if gitgraph then
    vim.cmd('tabnew')
    gitgraph.draw({}, { all = true, max_count = 5000 })
  else
    print("GitGraph plugin is not installed")
  end
end, { desc = "GitGraph - Draw" })

