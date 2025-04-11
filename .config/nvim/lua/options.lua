local o   = vim.o
local opt = vim.opt
local g   = vim.g
--local A   = vim.api

-- cmd('syntax on')
-- vim.api.nvim_command('filetype plugin indent on')

o.termguicolors = true
o.background = 'dark'
require'colorizer'.setup()

-- Do not save when switching buffers
-- o.hidden = true

-- Decrease update time
o.timeoutlen = 500
--o.updatetime = 200
o.updatetime = 50

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

-- Command-line completion adjustments
opt.wildmenu = true

-- Editor behavior
--opt.nocompatible = true
vim.cmd('set nocompatible')
opt.shiftround = true
opt.hlsearch = true
opt.incsearch = true
opt.autochdir = true

-- Completion settings
opt.complete:append('kspell')
opt.shortmess:append('c')
opt.completeopt:append({'longest', 'menuone', 'preview'})

-- Enable filetype plugins and indentation
vim.cmd [[
  filetype plugin indent on
]]

-- Plugin settings
vim.g['jedi#popup_on_dot'] = 1

-- Syntastic Plugin Settings
-- vim.g['syntastic_always_populate_loc_list'] = 0
-- vim.g['syntastic_check_on_open'] = 1
-- vim.g['syntastic_check_on_wq'] = 0

-- Vimwiki Plugin Settings
vim.g['vimwiki_key_mappings'] = { table_mappings = 0 }

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

--vim.opt.showtabline = 1
--vim.opt.tabline = "%!v:lua.TabLine()"

-- Custom tabline
--_G.TabLine = function()
--  local s = ""
--  for i = 1, vim.fn.tabpagenr("$") do
--    -- Get tab label or buffer name
--    local tabname = vim.fn.gettabvar(i, "tablabel", vim.fn.bufname(vim.fn.tabpagebuflist(i)[1]))
--    if #tabname > 12 then
--      tabname = tabname:sub(-12) -- Negative index to get the last 12 characters
--    end
--
--    -- Highlight active tab
--    if i == vim.fn.tabpagenr() then
--      s = s .. "%#TabLineSel# " .. i .. " " .. tabname .. " "
--    else
--      s = s .. "%#TabLine# " .. i .. " " .. tabname .. " "
--    end
--  end
--  return s
--end

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

