require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local USE_NVIM_ROOTER = false

local o   = vim.o
local opt = vim.opt
local g   = vim.g
--local A   = vim.api

-- cmd('syntax on')
-- vim.api.nvim_command('filetype plugin indent on')

o.termguicolors = true
o.background = 'dark'

local ok, colorizer = pcall(require, "colorizer")
if ok then
  colorizer.setup()
end

-- Do not save when switching buffers
-- o.hidden = true

-- Decrease update time
-- Time to wait for a mapped sequence to complete (lower value = faster fallback to normal input.)
--o.timeoutlen = 1000 -- Default
o.timeoutlen = 500

-- Time of inactivity before things like the CursorHold autocommand trigger and swap files are written.
-- Lower value = more responsive diagnostics, LSP, etc.
--o.updatetime = 4000 -- Default
o.updatetime = 500
--o.updatetime = 50

-- Number of screen lines to keep above and below the cursor
o.scrolloff = 8

-- Editing settings
o.number = true
--o.relativenumber = true
-- o.numberwidth = 2
-- o.signcolumn = 'yes'
o.cursorline = true

o.expandtab = true -- indent using spaces
o.smarttab = true
-- o.cindent = true
o.autoindent = true -- autoindents
o.smartindent = true -- autoindent with syntax support
o.wrap = true
-- o.textwidth = 300
o.tabstop = 4 -- width used to display tab char
o.shiftwidth = 4 -- width used for shifting commands (<< >> ==), 0 means replicate tabstop
-- o.softtabstop = 4 -- how wide an indentation is supposed to span. 0 means replicate tabstop
o.softtabstop = -1 -- If negative, shiftwidth value is used
o.list = false
-- o.listchars = 'trail:·,nbsp:◇,tab:→ ,extends:▸,precedes:◂'
-- o.listchars = 'eol:¬,space:·,lead: ,trail:·,nbsp:◇,tab:→-,extends:▸,precedes:◂,multispace:···⬝,leadmultispace:│   ,'
-- o.formatoptions = 'qrn1'

-- Makes neovim and host OS clipboard play nicely with each other
o.clipboard = 'unnamedplus'

-- Case insensitive searching UNLESS /C or capital in search
o.ignorecase = true
-- o.smartcase = true

-- Undo and backup options
o.backup = false
o.writebackup = false
-- o.backupdir = '/tmp/'
-- o.directory = '/tmp/'
o.swapfile = false
o.undofile = true
local undodir
if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
  undodir = vim.fn.expand('$USERPROFILE') .. '\\.vim\\undodir'
else
  undodir = vim.fn.expand('$HOME') .. '/.vim/undodir'
end
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, 'p')
end
vim.o.undodir = undodir

-- Remember 50 items in commandline history
o.history = 50

-- Better buffer splitting
o.splitbelow = true
o.splitright = true

-- Preserve view while jumping
-- o.jumpoptions = 'view'

-- When running macros and regexes on a large file, lazy redraw tells
-- neovim/vim not to draw the screen
-- You can enable this inside vim with :set lazyredraw
-- o.lazyredraw = true

-- Better folds (don't fold by default)
-- o.foldmethod = 'indent'
-- o.foldlevelstart = 99
-- o.foldnestmax = 3
-- o.foldminlines = 1
--
-- opt.mouse = "a"

-- General settings
opt.wrap = false -- No Wrap lines
opt.backspace = { 'start', 'eol', 'indent' }
opt.path:append { '**' } -- Finding files - search down into subfolders
opt.wildignore:append { '*/node_modules/*' }
vim.scriptencoding = 'utf-8'
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'
-- vim.cmd("autocmd!")
-- opt.cmdheight = 1

-- Setting runtimepath
opt.runtimepath:append('~/.vim')
opt.runtimepath:append('~/.fzf')

-- UI tweaks
opt.errorbells = false
opt.visualbell = false
--opt.t_vb = ''
vim.cmd('set t_vb=')

-- File handling
opt.autoread = true
opt.autowrite = true

-- Sessions (:mksession -- <leader>m in keybindings/session.lua writes one).
-- Only what is on screen when the session is saved: the tab pages, the windows
-- in each and their sizes, the file each window shows and the cursor in it
-- (that last one is always saved). Left out of the default
-- "blank,buffers,curdir,folds,help,tabpages,winsize,terminal":
--   buffers  - a 'badd' for every hidden buffer ever opened. Loading the session
--              listed them all again, so the next save wrote them back and the
--              file only ever grew.
--   folds    - manual folds and the fold settings of every window
--   curdir   - a :cd to the directory nvim was in. 'autochdir' moves it to the
--              file anyway, and without it the paths are written in full.
--   blank, help, terminal - empty windows, help windows, terminals
-- (Two things :mksession writes whatever this says -- each window's alternate
--  file and the argument list -- save_tabs_and_splits() takes back out.)
opt.sessionoptions = { 'tabpages', 'winsize' }

-- Command-line completion adjustments
opt.wildmenu = true

-- Editor behavior
--opt.nocompatible = true
vim.cmd('set nocompatible')
opt.shiftround = true
opt.hlsearch = true
opt.incsearch = true

opt.autochdir = not USE_NVIM_ROOTER

-- Completion settings
opt.complete:append('kspell')
opt.shortmess:append('c')
opt.completeopt:append({'longest', 'menuone', 'preview'})

-- Enable filetype plugins and indentation
vim.cmd [[
  filetype plugin indent on
]]

-- Plugin settings
--vim.g['jedi#popup_on_dot'] = 1

-- Syntastic Plugin Settings
-- vim.g['syntastic_always_populate_loc_list'] = 0
-- vim.g['syntastic_check_on_open'] = 1
-- vim.g['syntastic_check_on_wq'] = 0

-- Vimwiki Plugin Settings
--vim.g['vimwiki_key_mappings'] = { table_mappings = 0 }

-- local ok, _ = pcall(vim.cmd, 'colorscheme base16-gruvbox-dark-medium')
-- vim.g.gruvbox_contrast_dark = 'hard'
vim.cmd("colorscheme gruvbox")

-- Python path
-- vim.g['python3_host_prog'] = '/path/to/python3'
--vim.g.python3_host_prog = 'C:/Windows/python.exe'
vim.g.python3_host_prog = os.getenv("PYTHON_PATH")

-- Disable netrw (file explorer that comes with vim)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.env.LANG = "en_US.UTF-8"

-- Custom tabline: "1:name" per tab, the way tmux names its windows, and the
-- same tabline nvcs draws (its UI/Renderer.cs DrawTabLine).
--   * name: the file name of the tab's current window, not its path -- the
--     directory's name for an oil buffer ("oil:///home/me/src/" -> "src")
--   * cut to 12 characters, keeping the end behind a "…" ("…ng_file.txt")
--   * " [+]" behind it when that buffer is modified
--   * the "1:" only with vim.g.tabline_show_index (myconfig's show_tab_index)
-- Names keep all of their 12 characters however many tabs there are (nvim's own
-- tabline squeezes them into equal shares, down to a character or two). When
-- the tabs do not fit, the row starts late enough to keep the current tab on
-- screen, where nvim's would stop at the edge.
local MAX_TAB_TITLE = 12

local function cells(s) return vim.fn.strdisplaywidth(s) end

-- The end of name that fits in room cells, a "…" standing in for the rest.
local function keep_end(name, room)
  if cells(name) <= room then return name end
  if room <= 1 then return room == 1 and "…" or "" end
  local start = vim.fn.strchars(name)
  local used = 1 -- the "…"
  while start > 0 do
    local w = cells(vim.fn.strcharpart(name, start - 1, 1))
    if used + w > room then break end
    used = used + w
    start = start - 1
  end
  return "…" .. vim.fn.strcharpart(name, start)
end

local function tab_title(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return vim.bo[buf].buftype == "quickfix" and "[Quickfix List]" or "[No Name]"
  end
  local trimmed = (name:gsub("[/\\]+$", ""))
  local last = trimmed:match("[^/\\]+$") or name
  return keep_end(last, MAX_TAB_TITLE)
end

_G.TabLine = function()
  local show_index = vim.g.tabline_show_index == true or vim.g.tabline_show_index == 1
  local n = vim.fn.tabpagenr("$")
  local cur = vim.fn.tabpagenr()
  local width = vim.o.columns

  local labels, span = {}, 0
  for i = 1, n do
    local buf = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    labels[i] = (show_index and (" " .. i .. ":") or " ") .. tab_title(buf)
      .. (vim.bo[buf].modified and " [+]" or "") .. " "
    if i <= cur then span = span + cells(labels[i]) end
  end
  local first = 1
  while first < cur and span > width do
    span = span - cells(labels[first])
    first = first + 1
  end

  -- Only what fits is handed over, the last label cut at the edge, so nvim
  -- never truncates the line itself (it would cut from the start).
  local s, col = "", 0
  for i = first, n do
    if col >= width then break end
    local label = labels[i]
    if col + cells(label) > width then
      label = vim.fn.strcharpart(label, 0, width - col)
    end
    col = col + cells(label)
    s = s .. "%" .. i .. "T" .. (i == cur and "%#TabLineSel#" or "%#TabLine#")
      .. label:gsub("%%", "%%%%")
  end
  return s .. "%#TabLineFill#%T"
end

vim.opt.tabline = "%!v:lua.TabLine()"

-- https://gpanders.com/blog/whats-new-in-neovim-0-11/#diagnostics
vim.diagnostic.config({ virtual_text = true })

--vim.diagnostic.config({
--  virtual_text = { current_line = true },
--  virtual_lines = false,
--})

--opt.messagesopt = 'wait:1000,history:500'

-- Map <leader> to space
g.mapleader = ' '
g.maplocalleader = ' '

-- nvim-rooter equivalent:
-- note: disable autochdir first!
if USE_NVIM_ROOTER then
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      local directory = vim.fs.root(0, '.git') or '.'
      vim.cmd.cd(vim.fn.fnameescape(directory))
    end,
  })
end

