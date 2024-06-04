lspconfig = require'lspconfig'

local function go_to_definition_twice()
    vim.lsp.buf.definition()
    vim.defer_fn(function() vim.lsp.buf.definition() end, 100)
end

local on_attach = function(client, bufnr)
    -- Create a buffer-local keymap function
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    buf_set_keymap('n', '<M-r>', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })
    buf_set_keymap('n', '<M-d>', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
    buf_set_keymap('n', '<M-s-D>', '<cmd>lua vim.lsp.buf.implementation()<CR>', { noremap = true, silent = true })
    buf_set_keymap('n', '<M-s-E>', '<cmd>lua vim.lsp.buf.type_definition()<CR>', { noremap = true, silent = true })
    buf_set_keymap('n', '<M-s-C>', '<cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })
    --buf_set_keymap('n', '<M-s-d>', '', { noremap = true, silent = true, callback = go_to_definition_twice })
end

-- Python language server
--require'lspconfig'.pyright.setup {
--    on_attach = on_attach,
--}

-- C/C++ language server
--require'lspconfig'.clangd.setup {
--    on_attach = on_attach,
--    -- Clangd-specific settings
--    -- cmd = { "clangd", "--background-index" },
--    -- Configure flags, headers, or other clangd-specific options...
--}

-- Java language server
--require'lspconfig'.jdtls.setup {
--    on_attach = on_attach,
--    -- Note: jdtls might require more complex configuration especially for workspace handling
--    -- and Java project management compared to other simpler LSP setups.
--    -- root_dir = function() return vim.fn.getcwd() end,
--}

-- Setup language server if its binary is available
local function setup_lsp_if_available(server_name, config, binary_name)
    binary_name = binary_name or server_name

    if vim.fn.executable(binary_name) == 1 then
        require'lspconfig'[server_name].setup(config)
    --else
    --    print(binary_name .. " is not installed or not found in PATH")
    end
end

local lsp_attach_config = {
    on_attach = on_attach,
}

setup_lsp_if_available('pyright', lsp_attach_config)
setup_lsp_if_available('clangd', lsp_attach_config)
setup_lsp_if_available('gopls', lsp_attach_config)
setup_lsp_if_available('phpactor', lsp_attach_config)
setup_lsp_if_available('tsserver', lsp_attach_config)
-- lua_ls isn't the executable, lua-language-server is
setup_lsp_if_available('lua_ls', lsp_attach_config, 'lua-language-server')
-- rust_analyzer isn't the executable, rust-analyzer is
setup_lsp_if_available('rust_analyzer', lsp_attach_config, 'rust-analyzer')
setup_lsp_if_available('fsautocomplete', lsp_attach_config)

local omnisharp_path = os.getenv('OMNISHARP_PATH')
if omnisharp_path then
    local cmd

    if vim.fn.has('unix') == 1 then
        cmd = { "dotnet", omnisharp_path .. "/OmniSharp.dll" }
    else
        cmd = { omnisharp_path .. "/OmniSharp.exe", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
    end

    require'lspconfig'.omnisharp.setup {
        on_attach = on_attach,
        cmd = cmd,
        settings = {
            FormattingOptions = {
                -- Enables support for reading code style, naming convention and analyzer
                -- settings from .editorconfig.
                EnableEditorConfigSupport = true,
                -- Specifies whether 'using' directives should be grouped and sorted during
                -- document formatting.
                OrganizeImports = nil,
            },
            MsBuild = {
                -- If true, MSBuild project system will only load projects for files that
                -- were opened in the editor. This setting is useful for big C# codebases
                -- and allows for faster initialization of code navigation features only
                -- for projects that are relevant to code that is being edited. With this
                -- setting enabled OmniSharp may load fewer projects and may thus display
                -- incomplete reference lists for symbols.
                LoadProjectsOnDemand = nil,
            },
            RoslynExtensionsOptions = {
                -- Enables support for roslyn analyzers, code fixes and rulesets.
                EnableAnalyzersSupport = nil,
                -- Enables support for showing unimported types and unimported extension
                -- methods in completion lists. When committed, the appropriate using
                -- directive will be added at the top of the current file. This option can
                -- have a negative impact on initial completion responsiveness,
                -- particularly for the first few completion sessions after opening a
                -- solution.
                EnableImportCompletion = nil,
                -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
                -- true
                AnalyzeOpenDocumentsOnly = nil,
            },
            Sdk = {
                -- Specifies whether to include preview versions of the .NET SDK when
                -- determining which version to use for project loading.
                IncludePrereleases = true,
            },
        },
    }
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

-- Setting runtimepath
vim.opt.runtimepath:append('~/.vim')
vim.opt.runtimepath:append('~/.fzf')

-- UI tweaks
vim.opt.errorbells = false
vim.opt.visualbell = false
--vim.opt.t_vb = ''
vim.cmd('set t_vb=')

-- File handling
vim.opt.autoread = true
vim.opt.autowrite = true

-- Command-line completion adjustments
vim.opt.wildmenu = true

-- Editor behavior
--vim.opt.nocompatible = true
vim.cmd('set nocompatible')
vim.opt.shiftround = true
vim.opt.hlsearch = true
vim.opt.autochdir = true

-- Completion settings
vim.opt.complete:append('kspell')
vim.opt.shortmess:append('c')
vim.opt.completeopt:append({'longest', 'menuone', 'preview'})

-- Automatic command to adjust format options
vim.cmd [[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
]]

-- Enable filetype plugins and indentation
vim.cmd [[
  filetype plugin indent on
]]

-- Plugin settings
vim.g['jedi#popup_on_dot'] = 1

-- Syntastic Plugin Settings
vim.g['syntastic_always_populate_loc_list'] = 0
vim.g['syntastic_check_on_open'] = 1
vim.g['syntastic_check_on_wq'] = 0

-- NERDTree Plugin Settings
vim.g['NERDTreeQuitOnOpen'] = 1
vim.g['NERDTreeShowHidden'] = 1

-- Vimwiki Plugin Settings
vim.g['vimwiki_key_mappings'] = { table_mappings = 0 }

-- Python path
-- vim.g['python3_host_prog'] = '/path/to/python3'

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
map('n', '<M-q>', ':q<CR>') -- Quit
map('n', '<M-z>', ':noh<CR>')
-- map('n', '<M-x>', ':call CompileRun()<CR>')
map('n', 'Y', 'y$') -- Yank till end of line
-- map('n', 'F4', ':set cursorline!<CR>')
-- map('n', 'F5', ':setlocal spell! spelllang=en_us<CR>')
-- map('n', 'F6', ':setlocal spell! spelllang=sv<CR>')

map('n', '<leader>p', 'viw"_dP') -- Replace from void
map('v', '<leader>p', '<Esc>viw"_dP') -- Replace from void
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
--map('n', '<M-d>', ':FZF<CR>')
map('n', '<M-a>', ':FZF ../<CR>')
map('n', '<M-A>', ':FZF ~/<CR>')
map('n', '<M-S>', ':FZF C:/<CR>')

-- Vimgrep and QuickFix Lists
-- TODO: leader-f?
map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>11hi')
map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>9hi') -- Search all
map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>8hi') -- Search dotfiles
map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>13hi')
-- map('n', '<M-v>', ':cfdo s//x/gc<left><left><left><left><left><C-f>i')
map('n', '<M-n>', ':cnext<CR>')
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
map('n', '<leader>.', ':silent so ~/.vim/sessions/s.vim<CR>')
map('n', '<leader>-', ':so ~/.vim/sessions/s2.vim<CR>')

-- Open new tabs
map('n', '<M-m>', ':tabe ~/.config/nvim/init.lua<CR>')
map('n', '<M-,>', ':tabe ~/.zshrc<CR>')
map('n', '<M-.>', ':tabe ~/Documents/vimtutor.txt<CR>')

-- Windows
if vim.fn.has('win32') == 1 then
	vim.api.nvim_set_keymap('n', '<M-m>', '<cmd>tabe ' .. vim.fn.expand('$LOCALAPPDATA') .. '/nvim/init.lua<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<M-,>', '<cmd>tabe ' .. (os.getenv('ps_profile_path') or '.') .. '/Microsoft.PowerShell_profile.ps1<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<M-.>', '<cmd>tabe ' .. (os.getenv('my_notes_path') or '.') .. '/vimtutor.txt<CR>', { noremap = true, silent = true })
end

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

local function PythonCommand()
    local code_root_dir = os.getenv("code_root_dir") or "~/"
    code_root_dir = code_root_dir:gsub(" ", '" "')
    local command = "!python " .. code_root_dir .. "Code2/Python/my_py/scripts/"
    --vim.cmd('normal gv')
    vim.fn.feedkeys(":" .. command)
    local pos = #command
    vim.fn.setcmdpos(pos)
end

vim.api.nvim_create_user_command('RunPythonCommand', PythonCommand, {})
vim.api.nvim_set_keymap('v', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })

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
    { name = 'cmp_git' },
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

-- Python path
--vim.g.python3_host_prog = 'C:/Windows/python.exe'
vim.g.python3_host_prog = os.getenv("PYTHON_PATH")

-- GPT binds
local config = {
     openai_api_key = os.getenv("OPENAI_API_KEY"),
}

-- Model can be changed in actions for this plugin
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
map('n', '<M-c>', ':ChatGPTRun send_request<CR>')
map('v', '<M-c>', ':ChatGPTRun send_request<CR>')

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
--map('n', '<leader>h', ':GpNextAgent<CR>')
--map('v', '<leader>h', ':GpNextAgent<CR>')
-- There's also:
-- :GpAgent (for info)
-- :GpWhisper
-- :GpImage
-- :GpStop
-- etc.

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

-- vim.api.nvim_command('autocmd BufEnter *.tex :set wrap linebreak nolist spell')

-- Helper function for setting key mappings for filetypes
local function set_hellow_mapping(ft, template_file)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local map_opts = { noremap = true, silent = true }
      vim.api.nvim_buf_set_keymap(0, 'i', 'hellow<Tab>', '<Esc>:r ' .. template_file .. '<Enter><Esc>/Hellow<Enter>ciw', map_opts)
    end
  })
end

-- Automatically load the session when entering vim
-- vim.api.nvim_create_autocmd("VimEnter", {
--   pattern = "*",
--   command = "source ~/.vim/sessions/s.vim"
-- })

-- Set mappings for various filetypes
set_hellow_mapping("go", "~/hellow/hellow.go")
set_hellow_mapping("perl", "~/hellow/hellow.pl")
set_hellow_mapping("kotlin", "~/hellow/hellow.kt")
set_hellow_mapping("rust", "~/hellow/hellow.rs")
set_hellow_mapping("scala", "~/hellow/hellow.scala")

-- Function keys mappings
vim.api.nvim_set_keymap('n', '<F4>', '<Esc>:set cursorline!<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F5>', '<Esc>:setlocal spell! spelllang=en_us<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F6>', '<Esc>:setlocal spell! spelllang=sv<CR>', { noremap = true, silent = true })

-- Helper function to create key mappings for given filetypes
local function create_mappings(ft, mappings)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      for lhs, rhs in pairs(mappings) do
        vim.api.nvim_buf_set_keymap(bufnr, 'i', lhs, rhs, { noremap = true, silent = true })
      end
    end
  })
end

-- C# mappings
create_mappings("cs", {
  ["sout<Tab>"] = 'Console.WriteLine("");<Esc>?""<Enter>li',
  ["fore<Tab>"] = 'foreach (object o in obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["hellow<Tab>"] = '<Esc>:r ~/hellow/hellow.cs<Enter><Esc>/Hellow<Enter>ciw'
})

-- Python mappings
create_mappings("py,python", {
  ["hellow<Tab>"] = '<Esc>:r ~/hellow/hellow.py<Enter>'
})

-- SQL mappings
create_mappings("sql", {
  ["fun<Tab>"] = 'delimiter //<Enter>create function x ()<Enter>returns int<Enter>no sql<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN',
  ["pro<Tab>"] = 'delimiter //<Enter>create procedure x ()<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN',
  ["vie<Tab>"] = 'create view x as<Enter>select <Esc>/x<Enter>GN'
})

-- Text-based file mappings
create_mappings("vtxt,vimwiki,wiki,text", {
  ["line<Tab>"] = '----------------------------------------------------------------------------------<Enter>',
  ["oline<Tab>"] = '******************************************<Enter>',
  ["date<Tab>"] = '<-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->'
})

-- HTML mappings
create_mappings("html", {
  ["<i<Tab>"] = '<em></em> <Space><++><Esc>/<<Enter>GNi',
  ["<b<Tab>"] = '<b></b><Space><++><Esc>/<<Enter>GNi',
  ["<h1<Tab>"] = '<h1></h1><Space><++><Esc>/<<Enter>GNi',
  ["<h2<Tab>"] = '<h2></h2><Space><++><Esc>/<<Enter>GNi',
  ["<im<Tab>"] = '<img></img><Space><++><Esc>/<<Enter>GNi'
})

-- Java mappings
create_mappings("java", {
  ["fore<Tab>"] = 'for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["sout<Tab>"] = 'System.out.println("");<Esc>?""<Enter>li',
  ["psvm<Tab>"] = 'public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o',
  ["hellow<Tab>"] = '<Esc>:r ~/hellow/hellow.java<Enter><Esc>/hellow<Enter>ciw'
})

-- C and C++ mappings
create_mappings("c", {
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["hellow<Tab>"] = '<Esc>:r ~/hellow/hellow.c<Enter>'
})

create_mappings("cpp", {
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["hellow<Tab>"] = '<Esc>:r ~/hellow/hellow.cpp<Enter>'
})

function compile_run()
    vim.cmd('w') -- Save the file first

    local filetype = vim.bo.filetype
    local is_windows = vim.fn.has('win32') == 1 -- or vim.fn.has('win16') == 1 or vim.fn.has('win64') == 1

    if filetype == 'c' then
        if is_windows then
            vim.cmd('!gcc -Wall % -o %<')
            vim.cmd('!%:r.exe')
        else
            vim.cmd('!gcc % && time ./a.out')
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
        if is_windows then
            vim.cmd('!javac %')
            vim.cmd('!java -cp %:p:h %:t:r')
        else
            vim.cmd('!time java %')
        end
    elseif filetype == 'sh' then
        vim.cmd('!time bash %')
    elseif filetype == 'python' then
        if is_windows then
            vim.cmd('!python %')
        else
            vim.cmd('!time python3 %')
        end
    elseif filetype == 'html' then
        vim.cmd('!firefox % &')
    elseif filetype == 'php' then
        vim.cmd('!php %')
    elseif filetype == 'javascript' or filetype == 'jsx' or filetype == 'typescript' then
        if is_windows then
            vim.cmd('!node %')
        else
            vim.cmd('!time node %')
        end
    elseif filetype == 'go' then
        vim.cmd('!go build %<')
        vim.cmd('!time go run %')
    elseif filetype == 'rust' then
        vim.cmd('!cargo build && cargo run')
    elseif filetype == 'lua' then
        vim.cmd('!time lua %')
    elseif filetype == 'mkd' or filetype == 'mk' then
        vim.cmd('!grip')
    elseif filetype == 'cs' or filetype == 'fs' or filetype == 'fsx' or filetype == 'fsharp' or filetype == 'vb' then
        vim.cmd('!dotnet build && dotnet run')
    end
end

vim.api.nvim_set_keymap('n', '<M-x>', '<Cmd>lua compile_run()<CR>', { noremap = true, silent = true })

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

  -- Other stuff
  -- use 'frazrepo/vim-rainbow'

  -- use("simrat39/rust-tools.nvim")

  use({
      "ornfelt/ChatGPT.nvim",
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
