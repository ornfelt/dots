lspconfig = require'lspconfig'
if vim.fn.has('unix') == 1 then
    -- require'lspconfig'.sumneko_lua.setup{}
    require'lspconfig'.pyright.setup{}
    require'lspconfig'.clangd.setup{}
    require'lspconfig'.jdtls.setup{}
end

local g   = vim.g
local o   = vim.o
local opt = vim.opt
local A   = vim.api

-- cmd('syntax on')
-- vim.api.nvim_command('filetype plugin indent on')

o.termguicolors = true
-- o.background = 'dark'
require'colorizer'.setup()

-- Do not save when switching buffers
-- o.hidden = true

-- Decrease update time
o.timeoutlen = 500
o.updatetime = 200

-- Number of screen lines to keep above and below the cursor
o.scrolloff = 8

-- Editing settings
o.number = true
o.relativenumber = true
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
o.undofile = false
o.swapfile = false
-- o.backupdir = '/tmp/'
-- o.directory = '/tmp/'
-- o.undodir = '/tmp/'

-- Remember 50 items in commandline history
o.history = 50

-- Better buffer splitting
o.splitbelow = true
o.splitright = true

-- Preserve view while jumping
-- o.jumpoptions = 'view'

-- When running macros and regexes on a large file, lazy redraw tells neovim/vim not to draw the screen
-- You can enable this inside vim with :set lazyredraw
-- o.lazyredraw = true

-- Better folds (don't fold by default)
-- o.foldmethod = 'indent'
-- o.foldlevelstart = 99
-- o.foldnestmax = 3
-- o.foldminlines = 1
--
-- opt.mouse = "a"

-- Map <leader> to space
g.mapleader = ' '
g.maplocalleader = ' '

-- General settings
vim.opt.wrap = false -- No Wrap lines
vim.opt.backspace = { 'start', 'eol', 'indent' }
vim.opt.path:append { '**' } -- Finding files - Search down into subfolders
vim.opt.wildignore:append { '*/node_modules/*' }
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
-- vim.cmd("autocmd!")
-- vim.opt.cmdheight = 1
--
vim.cmd([[
set runtimepath+=~/.vim
set rtp+=~/.fzf
set noerrorbells
set noeb vb t_vb=
set autoread
set autowrite
set wildmenu
set nocompatible
set shiftround
set hls
set autochdir
set complete+=kspell
set shortmess+=c
set completeopt+=longest,menuone
set completeopt+=preview
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
filetype plugin indent on

let g:jedi#popup_on_dot = 1
" Syntastic
let g:syntastic_always_populate_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:NERDTreeQuitOnOpen=1
let NERDTreeShowHidden=1

" Disable tab key for vimwiki (enables autocomplete via tabbing)
let g:vimwiki_key_mappings = { 'table_mappings': 0 }
"let g:python3_host_prog = $PYTHON_PATH
]])

local function getWords()
  if vim.bo.filetype == "md" or vim.bo.filetype == "text" or vim.bo.filetype == "txt" or vim.bo.filetype == "vtxt" or vim.bo.filetype == "markdown" then
    return tostring(vim.fn.wordcount().words)
  else
    return ""
  end
end

local options = {
    icons_enabled = true,
    theme = 'gruvbox',
    -- globalstatus = true,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
}

if vim.fn.has('win32') == 1 then
    options.component_separators = { left = '', right = '|' }
end

require('lualine').setup {
  options = options,
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {getWords, 'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}

local barhidden = false

local function togglebar()
    if barhidden then
        require('lualine').hide({unhide = true})
        barhidden = false
    else
        require('lualine').hide()
        barhidden = true;
    end
end

-- local ok, _ = pcall(vim.cmd, 'colorscheme base16-gruvbox-dark-medium')
-- vim.g.gruvbox_contrast_dark = 'hard'
vim.cmd("colorscheme gruvbox")
-- vim.cmd("colorscheme catppuccin")

-- Keybinds
local function map(m, k, v)
    vim.keymap.set(m, k, v, { silent = true })
end

-- Fix * (Keep the cursor position, don't move to next match)
-- map('n', '*', '*N')
-- Fix n and N. Keeping cursor in center
-- map('n', 'n', 'nzz')
-- map('n', 'N', 'Nzz')

-- Mimic shell movements
map('i', '<C-E>', '<ESC>A')
map('i', '<C-A>', '<ESC>I')
map('i', '<C-v>', '<Esc>"+p')
map('i', '<C-a>', '<Esc>gg"yG') -- Copy everything from file into clipboard
map('i', '<C-BS>', '<C-W>a') -- Copy everything from file into clipboard
map('i', '<S-Tab>', '<BS>')
-- Undo break points
-- map('i', ',', ',<c-g>u')
-- map('i', '.', '.<c-g>u')
-- map('i', '!', '!<c-g>u')
-- map('i', '?', '?<c-g>u')

-- Make shift-insert work like in Xterm
map('i', '<S-Insert>', '<Esc><MiddleMouse>A')
map('n', '<S-Insert>', '<MiddleMouse>')

map('n', '<leader>b', togglebar) -- Toggle lualine
map('n', '<M-q>', ':q<CR>') -- Quit neovim
map('n', '<M-z>', ':noh<CR>')
-- map('n', '<M-x>', ':call CompileRun()<CR>')
map('n', 'Y', 'y$') -- Yank till end of line
-- map('n', 'F4', ':set cursorline!<CR>')
-- map('n', 'F5', ':setlocal spell! spelllang=en_us<CR>')
-- map('n', 'F6', ':setlocal spell! spelllang=sv<CR>')

map('n', '<leader>p', 'viw"_dP') -- Replace from void
map('n', '<leader>d', '"_d') -- Delete to void
map('v', '<leader>d', '"_d') -- Delete to void

-- Paste from previous registers
map('n', '<leader>1', '"1p')
map('n', '<leader>2', '"2p')
map('n', '<leader>3', '"3p')
map('n', '<leader>4', '"4p')
map('n', '<leader>5', '"5p')

-- map('n', '<M-w>', ':NERDTreeToggle ~/<CR>')
-- map('n', '<M-e>', ':NERDTreeToggle %:p<CR>')
map('n', '<M-w>', ':silent! NERDTreeToggle ~/<CR>')
map('n', '<M-e>', ':silent! NERDTreeToggle %:p<CR>')
-- map('n', '<C-b>', ':NERDTreeToggle<CR>')
map('n', '<M-d>', ':FZF<CR>')
map('n', '<M-a>', ':FZF ~/<CR>')
map('n', '<M-A>', ':FZF /<CR>')

-- Vimgrep and QuickFix Lists
map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>11hi')
map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>9hi') -- Search all
map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>8hi') -- Search dotfiles
map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>13hi')
-- map('n', '<M-v>', ':cfdo s//x/gc<left><left><left><left><left><C-f>i')
map('n', '<M-c>', ':cnext<CR>')
map('n', '<M-p>', ':cprev<CR>')
map('n', '<M-P>', ':clast<CR>')
map('n', '<M-b>', ':copen<CR>')

-- Window management and movement
map('n', '<M-u>', ':resize +2<CR>')
map('n', '<M-i>', ':resize -2<CR>')
map('n', '<M-o>', ':vertical resize +2<CR>')
map('n', '<M-y>', ':vertical resize -2<CR>')
map('n', '<M-h>', '<Plug>WinMoveLeft')
map('n', '<M-J>', '<Plug>WinMoveDown')
map('n', '<M-K>', '<Plug>WinMoveUp')
map('n', '<M-l>', '<Plug>WinMoveRight')

-- Moving text and indentation
map('x', 'K', ":move '<-2<CR>gv-gv")
map('x', 'J', ":move '>+1<CR>gv-gv")
map('n', '<leader>j', ':join<CR>')
map('n', '<leader>J', ':join!<CR>')
map('n', '<leader>z', '<Plug>Zoom')

-- Indentation
map('v', '<leader><', ':le<CR>')
map('n', '<leader><', ':le<CR>')
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Tab keybinds
map('n', '<M-t>', ':tabe<CR>')
map('n', '<M-s>', ':split<CR>')
map('n', '<M-Enter>', ':vsp<CR>')
if vim.fn.has('win32') == 1 then
    map('n', '<M-Enter>', ':10 sp :let $VIM_DIR=expand("%:p:h")<CR>:terminal<CR>cd $VIM_DIR<CR>')
end

map('n', '<M-<>', ':vsp<CR>')
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

-- Session management
map('n', '<leader>o', '<C-^>')
map('n', '<leader>m', ':mks! ~/.vim/sessions/s.vim<CR>')
map('n', '<leader>,', ':mks! ~/.vim/sessions/s2.vim<CR>')
map('n', '<leader>.', ':so ~/.vim/sessions/s.vim<CR>')
map('n', '<leader>-', ':so ~/.vim/sessions/s2.vim<CR>')

-- Open new tabs
map('n', '<M-n>', ':tabe ~/Documents/vimtutor.txt<CR>')
map('n', '<M-m>', ':tabe ~/.config/nvim/init.lua<CR>')
map('n', '<M-,>', ':tabe ~/.config/i3/config<CR>')
if vim.fn.has('win32') == 1 then
    map('n', '<M-m>', ':tabe ~/AppData/local/nvim/init.lua<CR>')
    map('n', '<M-,>', ':tabe C:/Users/jonas/OneDrive/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1<CR>')
end
map('n', '<M-.>', ':tabe ~/.zshrc<CR>')
-- map('n', '<C-c>', 'y')
map('v', '<C-c>', 'y')

map('n', '<leader>s', "/\\s\\+$/<CR>") -- Show extra whitespace
map('n', '<leader>ws', ':%s/\\s\\+$<CR>') -- Remove all extra whitespace
map('n', '<leader>wu', ':%s/\\%u200b//g<CR>') -- Remove all extra unicode chars
map('n', '<leader>wb', ':%s/[[:cntrl:]]//g<CR>') -- Remove all hidden characters
map('n', '<leader>wf', 'gqG<C-o>zz') -- Format rest of the text with vim formatting, go back and center screen
map('v', '<leader>gu', ':s/\\<./\\u&/g<CR>:noh<CR>:noh<CR>') -- Capitalize first letter of each word on visually selected line
map('v', '<leader>/', '"3y/<C-R>3<CR>') -- Search for highlighted text
map('v', '<leader>%', '/\\%V') -- Search in highlighted text
map("n", "Q", "<nop>") -- Remove Ex Mode
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Replace word under cursor
vim.keymap.set("n", "<leader>t", "<cmd>silent !tmux neww tmux-sessionizer<CR>") -- Start tmux-sessionizer

 -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  -- Use Tab and Shift-Tab to browse through the suggestions.
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      -- elseif vim.fn["vsnip#available"](1) == 1 then
        -- feedkey("<Plug>(vsnip-expand-or-jump)", "")
      -- elseif has_words_before() then
        -- cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      -- elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        -- feedkey("<Plug>(vsnip-jump-prev)", "")
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      -- { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Setup lspconfig (line below deprecated)
  -- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  -- require('lspconfig')['<YOUR_LSP_SERVER>'].setup {
    -- capabilities = capabilities
  -- }


if vim.fn.has('win32') == 1 then
    --vim.g.python3_host_prog = 'C:/Windows/python.exe'
    vim.g.python3_host_prog = os.getenv("PYTHON_PATH")
end

local config = {
     openai_api_key = os.getenv("OPENAI_API_KEY")
}

require("chatgpt").setup(config)
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

--require("gp").setup({openai_api_key: os.getenv("OPENAI_API_KEY")})
--require("gp").setup(config)
--map('n', '<leader>e', ':GpAppend<CR>')
--map('v', '<leader>e', ':GpAppend<CR>')
--map('n', '<leader>x', ':GpTabnew<CR>')
--map('v', '<leader>x', ':GpTabnew<CR>')
--map('n', '<leader>c', ':GpNew<CR>')
--map('v', '<leader>c', ':GpNew<CR>')
--map('n', '<leader>v', ':GpVnew<CR>')
--map('v', '<leader>v', ':GpVnew<CR>')
--map('n', '<leader>g', ':GpRewrite<CR>')
--map('v', '<leader>g', ':GpRewrite<CR>')
--map('n', '<leader>6', ':GpImplement<CR>')
--map('v', '<leader>6', ':GpImplement<CR>')
--map('n', '<leader>7', ':GpChatRespond<CR>')
--map('v', '<leader>7', ':GpChatRespond<CR>')
----map('n', '<leader>8', ':GpChatFinder<CR>')
----map('v', '<leader>8', ':GpChatFinder<CR>')
--map('n', '<leader>8', ':GpContext<CR>')
--map('v', '<leader>8', ':GpContext<CR>')
--map('n', '<leader>9', ':GpChatNew<CR>')
--map('v', '<leader>9', ':GpChatNew<CR>')
--map('n', '<leader>0', ':GpChatToggle<CR>')
--map('v', '<leader>0', ':GpChatToggle<CR>')

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

    local content = vim.fn.json_decode(response).content
    local split_newlines = vim.split(content, '\n', true)

    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
    lines[1] = lines[1] .. split_newlines[1]
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, lines)
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, vim.list_slice(split_newlines, 2))
end

vim.api.nvim_create_user_command('Llm', llm, {})
vim.api.nvim_set_keymap('n', '<C-B>', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('i', '<C-B>', '<Cmd>:Llm<CR>', {noremap = true, silent = true})

-- Filetype shortcuts
vim.cmd([[
autocmd FileType html inoremap <i<Tab> <em></em> <Space><++><Esc>/<<Enter>GNi
autocmd FileType html inoremap <b<Tab> <b></b><Space><++><Esc>/<<Enter>GNi
autocmd FileType html inoremap <h1<Tab> <h1></h1><Space><++><Esc>/<<Enter>GNi
autocmd FileType html inoremap <h2<Tab> <h2></h2><Space><++><Esc>>/<<Enter>GNi
autocmd FileType html inoremap <im<Tab> <img></img><Space><++><Esc>/<<Enter>GNi

autocmd FileType java inoremap fore<Tab> for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw
autocmd FileType java inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType java inoremap sout<Tab> System.out.println("");<Esc>?""<Enter>li
autocmd FileType java inoremap psvm<Tab> public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o
autocmd FileType java inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.java<Enter><Esc>/hellow<Enter>ciw

autocmd FileType c inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType c inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.c<Enter>
autocmd FileType cpp inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType cpp inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.cpp<Enter>

autocmd FileType cs inoremap sout<Tab> Console.WriteLine("");<Esc>?""<Enter>li
autocmd FileType cs inoremap fore<Tab> for each (object o : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw
autocmd FileType cs inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType cs inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.cs<Enter><Esc>/Hellow<Enter>ciw

autocmd FileType py,python inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.py<Enter>

autocmd FileType sql inoremap fun<Tab> delimiter //<Enter>create function x ()<Enter>returns int<Enter>no sql<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN
autocmd FileType sql inoremap pro<Tab> delimiter //<Enter>create procedure x ()<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN
autocmd FileType sql inoremap vie<Tab> create view x as<Enter>select <Esc>/x<Enter>GN

autocmd FileType vtxt,vimwiki,wiki,text inoremap line<Tab> ----------------------------------------------------------------------------------<Enter>
autocmd FileType vtxt,vimwiki,wiki,text inoremap oline<Tab> ******************************************<Enter>
autocmd FileType vtxt,vimwiki,wiki,text inoremap date<Tab> <-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->

autocmd FileType go inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.go<Enter><Esc>/Hellow<Enter>ciw
autocmd FileType perl inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.pl<Enter><Esc>/Hellow<Enter>ciw
autocmd FileType kotlin inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.kt<Enter><Esc>/Hellow<Enter>ciw
autocmd FileType rust inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.rs<Enter><Esc>/Hellow<Enter>ciw
autocmd FileType scala inoremap hellow<Tab> <Esc>:r ~/hellow/hellow.scala<Enter><Esc>/Hellow<Enter>ciw

" Automatically load the session when entering vim
"autocmd! VimEnter * source ~/.vim/sessions/s.vim

map <F4> <Esc>:set cursorline!<CR>
map <F5> <Esc>:setlocal spell! spelllang=en_us<CR>
map <F6> <Esc>:setlocal spell! spelllang=sv<CR>

"inoremap <C-B> <Cmd>call llama#doLlamaGen()<CR>

"function! Llm()
"  let url = "http://127.0.0.1:8080/completion"
"
"  " Get the content of the current buffer
"  let buffer_content = join(getline(1, '$'), "\n")
"
"  " Create the JSON payload
"  let json_payload = {"temp":0.72,"top_k":100,"top_p":0.73,"repeat_penalty":1.100000023841858,"n_predict":256,"stop": ["\n\n\n"],"stream": v:false}
"  let json_payload.prompt = buffer_content
"
"  " Define the curl command
"  let curl_command = 'curl -k -s -X POST -H "Content-Type: application/json" -d @- ' . url
"  let response = system(curl_command, json_encode(json_payload))
"
"  " Extract the content field from the response
"  let content = json_decode(response).content
"
"  let split_newlines = split(content, '\n', 1)
"
"  " Insert the content at the cursor position
"  call setline(line('.'), [ getline('.') . split_newlines[0] ] + split_newlines[1:])
"endfunction
"
"command! Llm call Llm()
"noremap <C-B> <Cmd>:Llm<CR>
"inoremap <C-B> <Cmd>:Llm<CR>

func! CompileRun()
    exec "w"
    if &filetype == 'c'
        if has("win64") || has("win32") || has("win16")
            exec "!gcc -Wall % -o %<"
            exec "!%:r.exe"
        else
            exec "!gcc % && time ./a.out"
        endif
    elseif &filetype == 'cpp'
        if has("win64") || has("win32") || has("win16")
            "exec "!g++ % -o %< -std=c++11 -lpthread -lbgi -lgdi32 -lcomdlg32 -luuid -loleaut32 -lole32"
            exec "!g++ -O2 -Wall % -o %< -std=c++17 -pthread"
            exec "!%:r.exe"
        else
            "exec "!g++ -Ofast/O3 -Wall % -o %< -std=c++20/17/14/11 -lcurl -lcpprest -lcrypto -lssl -lpthread -Wl,--no-as-needed"
            exec "!g++ -O2 -Wall % -o %< -std=c++17 -lcurl -lcpprest -lcrypto -lssl -pthread"
            exec "!time ./%:r"
        endif
    elseif &filetype == 'java'
        if has("win64") || has("win32") || has("win16")
            exec "!javac %"
            exec "!java -cp %:p:h %:t:r"
        else
            exec "!time java %"
        endif
    elseif &filetype == 'sh'
        exec "!time bash %"
    elseif &filetype == 'python'
        if has("win64") || has("win32") || has("win16")
            exec "!python %"
        else
            exec "!time python3 %"
        endif
    elseif &filetype == 'html'
        exec "!firefox % &"
    elseif &filetype == 'php'
        exec "!php %"
    elseif &filetype == 'javascript'
        if has("win64") || has("win32") || has("win16")
            exec "!node %"
        else
            exec "!time node %"
        endif
    elseif &filetype == 'jsx'
        if has("win64") || has("win32") || has("win16")
            exec "!node %"
        else
            exec "!time node %"
        endif
    elseif &filetype == 'typescript'
        if has("win64") || has("win32") || has("win16")
            exec "!node %"
        else
            exec "!time node %"
        endif
    elseif &filetype == 'go'
        exec "!go build %<"
        exec "!time go run %"
    elseif &filetype == 'rust'
        "exec "!rustc %"
        "exec "!time ./%:r"
        exec "!cargo build && cargo run"
    elseif &filetype == 'lua'
        exec "!time lua %"
    elseif &filetype == 'mkd'
        "exec "!~/.vim/markdown.pl % > %.html &"
        "exec "!firefox %.html &"
        exec "!grip"
    elseif &filetype == 'mk'
        "exec "!~/.vim/markdown.pl % > %.html &"
        "exec "!firefox %.html &"
        exec "!grip"
    elseif &filetype == 'cs'
        "if has("win64") || has("win32") || has("win16")
        "    exec "!csc %"
        "    exec "!time %:r.exe"
        "else
        "    exec "!mcs % && time mono ./%:t:r.exe" 
        "endif
        exec "!dotnet build && dotnet run"
    elseif &filetype == 'fs'
        exec "!dotnet build && dotnet run"
    elseif &filetype == 'fsx'
        exec "!dotnet build && dotnet run"
    elseif &filetype == 'fsharp'
        exec "!dotnet build && dotnet run"
    elseif &filetype == 'vb'
        exec "!dotnet build && dotnet run"
    endif
endfunc
map <M-x> :call CompileRun()<CR>
]])

-- useINS
--
-- Only required if you have packer configured as `opt`
-- vim.cmd [[packadd packer.nvim]]
return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- A better status line
  use {
     'nvim-lualine/lualine.nvim',
     requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  -- File management --
  -- use 'scrooloose/nerdtree'
  use 'preservim/nerdtree'
  use 'tiagofumo/vim-nerdtree-syntax-highlight'
  -- use 'vifm/vifm.vim'
  -- use 'ryanoasis/vim-devicons'

  -- Productivity --
  use 'vimwiki/vimwiki'
  use 'tpope/vim-surround'
  use 'junegunn/fzf'
  use 'tpope/vim-commentary'
  -- use 'junegunn/goyo.vim'
  -- use 'junegunn/limelight.vim'
  use 'junegunn/vim-emoji'
  -- use 'jreybert/vimagit'

  -- Syntax Highlighting and Colors --
  use 'vim-python/python-syntax'
  use 'norcalli/nvim-colorizer.lua'
  -- use 'vim-syntastic/syntastic'
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  -- use 'mechatroner/rainbow_csv'
  -- use 'PotatoesMaster/i3-vim-syntax'
  -- use 'kovetskiy/sxhkd-vim'

  -- Colorschemes
  use("gruvbox-community/gruvbox")
  -- use 'RRethy/nvim-base16'

  -- Other stuff
  -- use 'frazrepo/vim-rainbow'

  use({
      "jackMort/ChatGPT.nvim",
      --config = function()
      --    require("chatgpt").setup()
      --end,
      requires = {
          "MunifTanjim/nui.nvim",
          "nvim-lua/plenary.nvim",
          "folke/trouble.nvim",
          "nvim-telescope/telescope.nvim"
      }
  })

  --use("robitx/gp.nvim")
  --use({
  --    "robitx/gp.nvim",
  --    config = function()
  --        require("gp").setup()
  --        or setup with your own config (see Install > Configuration in Readme)
  --        require("gp").setup(config)
  --        shortcuts might be setup here (see Usage > Shortcuts in Readme)
  --    end,
  --})

end)
