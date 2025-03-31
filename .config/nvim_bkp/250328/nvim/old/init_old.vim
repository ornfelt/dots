if &compatible
  set nocompatible               " Be iMproved
endif

call plug#begin('~/.vim/plugged') " Specify a directory for plugins
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'
Plug 'justinmk/vim-sneak'
Plug 'morhetz/gruvbox'
"Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'w0ng/vim-hybrid'
Plug 'vim-syntastic/syntastic'
Plug 'ap/vim-css-color'
Plug 'tpope/vim-commentary'
Plug 'vimwiki/vimwiki'
Plug 'jalvesaq/vimcmdline'
Plug 'junegunn/fzf'
Plug 'neovim/nvim-lspconfig' " Configurations for Nvim LSP
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
"Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
"Plug 'nvim-treesitter/nvim-treesitter'
call plug#end() " Initialize plugin system

set runtimepath+=~/.vim
set rtp+=~/.fzf
" let mysyntaxfile = "~/.vim/syntax/vtxt.vim" " Get syntax highlighting
" au BufRead,BufNewFile *.vtxt set filetype=vtxt

" General settings
filetype plugin indent on
if (has("termguicolors"))
    set termguicolors
endif
syntax on
syntax enable
set encoding=UTF-8
set number relativenumber
set noerrorbells
set noeb vb t_vb=
set autoread
set autowrite
set wildmenu
set backspace=indent,eol,start
set nocompatible
set smartindent
set autoindent
set smarttab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set hls
set ic
set splitright
" set t_Co=256
" highlight Normal ctermbg=NONE
" highlight CursorLine cterm=NONE ctermbg=darkblue
set cursorline
set autochdir
set scrolloff=8
set noswapfile
set complete+=kspell
set shortmess+=c
set completeopt+=longest,menuone
set completeopt+=preview
let g:jedi#popup_on_dot = 1

" Disables automatic commenting on newline:
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
" Turns off highlighting on the bits of code that are changed, so the line that is changed is highlighted but the actual text that has changed stands out on the line and is readable.
if &diff
        highlight! link DiffText MatchParen
endif

" Leader remap
nnoremap <SPACE> <Nop>
let mapleader=" "
" Replace from void
noremap <leader>p viw"_dP
noremap Y y$
" Delete to void
vnoremap <leader>d "_d
nnoremap <leader>d "_d
" Paste from previous registers
noremap <leader>1 "1p
noremap <leader>2 "2p
noremap <leader>3 "3p
noremap <leader>4 "4p
noremap <leader>5 "5p

" Vimgrep and QuickFix Lists
"nnoremap <M-f> :vimgrep // **/*.txt<left><left><left><left><left><left><left><left><left><left><C-f>i
nnoremap <M-f> :vimgrep //g **/*.txt<C-f><Esc>11hi
" Search all
nnoremap <M-g> :vimgrep //g **/*.*<C-f><Esc>9hi
" Search dotfiles
nnoremap <M-G> :vimgrep //g **/.*<C-f><Esc>8hi
nnoremap <M-v> :cdo s///gc \| update<C-f><Esc>13hi
"nnoremap <M-v> :cfdo s//x/gc<left><left><left><left><left><C-f>i
nnoremap <M-c> :cnext<CR>
nnoremap <M-p> :cprev<CR>
nnoremap <M-P> :clast<CR>
nnoremap <M-b> :copen<CR>

" Neovim FZF
nnoremap <M-d> :FZF ./ <cr>
" nnoremap <M-d> :FZF ../../..<cr> " Go up a few levels and FZF
nnoremap <M-a> :FZF ~/<cr>
nnoremap <M-A> :FZF /<cr>

" NERDTree
map <M-w> :NERDTreeToggle ~/<CR>
nnoremap <M-e> :NERDTreeToggle %:p<CR>
" map <C-b> :NERDTreeToggle<CR>

" Settings
map <M-z> :noh<CR>
map <M-x> :call CompileRun()<CR>
map <F4> <Esc>:set cursorline!<CR>
map <F5> <Esc>:setlocal spell! spelllang=en_us<CR>
map <F6> <Esc>:setlocal spell! spelllang=sv<CR>
imap <C-v> <Esc>"+p

" Window management and movement
nnoremap <M-u> :resize +2<CR>
nnoremap <M-i> :resize -2<CR>
nnoremap <M-o> :vertical resize +2<CR>
nnoremap <M-y> :vertical resize -2<CR>
map <silent> <M-h> <Plug>WinMoveLeft
map <silent> <M-J> <Plug>WinMoveDown
map <silent> <M-K> <Plug>WinMoveUp
map <silent> <M-l> <Plug>WinMoveRight

" Moving text and indentation
xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv
noremap <leader>j :join<CR>
noremap <leader>J :join!<CR>
nmap <leader>z <Plug>Zoom
" Remove indent
vnoremap <silent> <leader>< :le<cr>
nmap <silent> <leader>< :le<cr>

" Tab maps
nnoremap <M-q> :q<cr>
nnoremap <M-t> :tabe<cr>
nnoremap <M-s> :split<cr>
nnoremap <M-Enter> :vsp<cr>
nnoremap <M-<> :vsp<cr>

" Go to tab by number
noremap <M-1> 1gt
noremap <M-2> 2gt
noremap <M-3> 3gt
noremap <M-4> 4gt
noremap <M-5> 5gt
noremap <M-6> 6gt
noremap <M-7> 7gt
noremap <M-8> 8gt
noremap <M-9> 9gt
noremap <M-0> :tablast<cr>

" Go to last active tab
"au TabLeave * let g:lasttab = tabpagenr()
"nnoremap <silent> <leader>l :exe "tabn ".g:lasttab<cr>
"vnoremap <silent> <leader>l :exe "tabn ".g:lasttab<cr>
nnoremap <leader>o <C-^>
nnoremap <leader>m :mks! ~/.vim/sessions/s.vim<cr>
nnoremap <leader>, :mks! ~/.vim/sessions/s2.vim<cr>
nnoremap <leader>. :so ~/.vim/sessions/s.vim<cr>
nnoremap <leader>- :so ~/.vim/sessions/s2.vim<cr>

" Filetype shortcuts
autocmd FileType html inoremap <i<Tab> <em></em> <Space><++><Esc>/<<Enter>GNi
autocmd FileType html inoremap <b<Tab> <b></b><Space><++><Esc>/<<Enter>GNi
autocmd FileType html inoremap <h1<Tab> <h1></h1><Space><++><Esc>/<<Enter>GNi
autocmd FileType html inoremap <h2<Tab> <h2></h2><Space><++><Esc>>/<<Enter>GNi
autocmd FileType html inoremap <im<Tab> <img></img><Space><++><Esc>/<<Enter>GNi

autocmd FileType java inoremap fore<Tab> for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw
autocmd FileType java inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType java inoremap sout<Tab> System.out.println("");<Esc>?""<Enter>li
autocmd FileType java inoremap psvm<Tab> public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o
autocmd FileType java inoremap hellow<Tab> <Esc>:r ~/Documents/WindowsPowerShell/nvim/hellow/hellow.java<Enter><Esc>/hellow<Enter>ciw

autocmd FileType c inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType c inoremap hellow<Tab> <Esc>:r ~/Documents/WindowsPowerShell/nvim/hellow/hellow.c<Enter>
autocmd FileType cpp inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType cpp inoremap hellow<Tab> <Esc>:r ~/Documents/WindowsPowerShell/nvim/hellow/hellow.cpp<Enter>

autocmd FileType cs inoremap sout<Tab> Console.WriteLine("");<Esc>?""<Enter>li
autocmd FileType cs inoremap fore<Tab> for each (object o : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw
autocmd FileType cs inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw
autocmd FileType cs inoremap hellow<Tab> <Esc>:r ~/Documents/WindowsPowerShell/nvim/hellow/hellow.cs<Enter><Esc>/Hellow<Enter>ciw

autocmd FileType py,python inoremap hellow<Tab> <Esc>:r ~/Documents/WindowsPowerShell/nvim/hellow/hellow.py<Enter>

autocmd FileType sql inoremap fun<Tab> delimiter //<Enter>create function x ()<Enter>returns int<Enter>no sql<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN
autocmd FileType sql inoremap pro<Tab> delimiter //<Enter>create procedure x ()<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN
autocmd FileType sql inoremap vie<Tab> create view x as<Enter>select <Esc>/x<Enter>GN

autocmd FileType vtxt,vimwiki,wiki,text inoremap line<Tab> ----------------------------------------------------------------------------------<Enter>
autocmd FileType vtxt,vimwiki,wiki,text inoremap date<Tab> <-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->

" Disable tab key for vimwiki (enables autocomplete via tabbing)
let g:vimwiki_key_mappings = { 'table_mappings': 0 }
" Quit NERDTree on opening file
let g:NERDTreeQuitOnOpen = 1

" StatusLine
autocmd BufReadPost,BufRead,BufNewFile,BufWritePost *.* :call GetStatusLine()
autocmd BufReadPost,BufRead,BufNewFile,BufWritePost *.wiki,*.txt :call GetStatusLineText()

" Syntastic
let g:syntastic_always_populate_loc_list = 0
" let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
" Toggle statusbar
nnoremap <leader>b :call ToggleHiddenAll()<CR>

" Better tabbing
vnoremap < <gv
vnoremap > >gv

" --------------------------------
" --------------------------------

" Make shift-insert work like in Xterm
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>
inoremap <S-Insert> <Esc><MiddleMouse>A

" Show extra whitespace
nmap <leader>s /\s\+$/<cr>
" Remove all extra whitespace
nmap <leader>ws :%s/\s\+$<cr>
" Remove all extra unicode chars
nmap <leader>wu :%s/\%u200b//g<cr>
" Remove all hidden characters
nmap <leader>wb :%s/[[:cntrl:]]//g<cr>
" Format rest of the text with vim formatting, go back and center screen
nmap <leader>wf gqG<C-o>zz
" Replace all weird citation and hypens to regular ones
nmap <leader>wa :%s/“/"/g <bar> :%s/’/'/g <bar> :%s/—/-/g <bar> :%s/”/"/g
" Capitalize first letter of each word on visually selected line
vmap <leader>gu :s/\<./\u&/g<cr>:noh<CR>
" Search for highlighted text
vmap <leader>/ "3y/<C-R>3<CR>
" Search in highlighted text
vmap <leader>% /\%V
nmap <leader>r :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>
nmap <leader>t <cmd>silent !tmux neww tmux-sessionizer<CR>
nmap Q <nop>

" Undo break points
"inoremap , ,<c-g>u
"inoremap . .<c-g>u
"inoremap ! !<c-g>u
"inoremap ? ?<c-g>u

" Map Ctrl-Backspace to delete the previous word in insert mode.
imap <C-BS> <C-W>a

" Function for toggling the bottom statusbar:
let s:hidden_all = 1
function! ToggleHiddenAll()
    if s:hidden_all == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction

" Function for showing status line for text documents
function! GetStatusLineText()
	set statusline=
	set statusline=
	set laststatus=2
	set statusline+=%#warningmsg#
	set statusline+=%{SyntasticStatuslineFlag()}
	set statusline+=%*
	set statusline+=%#Difftext#
	set statusline+=\ %M "track if changes has been made to file
	set statusline+=\ %y "show filetype
	set statusline+=\ %r "ReadOnly flag
	set statusline+=\ %F "show full path to file
	set statusline+=%= "right side settings
	set statusline+=%#DiffChange#
	set statusline+=\ %{wordcount().words}\ words\ \| "display wordcount
	set statusline+=\ %c:%l/%L\  "display column and line pos
endfunction

" Function for showing status line for other files
function! GetStatusLine()
	set statusline=
	set statusline=
	set laststatus=2
	set statusline+=%#warningmsg#
	set statusline+=%{SyntasticStatuslineFlag()}
	set statusline+=%*
	set statusline+=%#Difftext#
	set statusline+=\ %M "track if changes has been made to file
	set statusline+=\ %y "show filetype
	set statusline+=\ %r "ReadOnly flag
	set statusline+=\ %F "show full path to file
	set statusline+=%= "right side settings
	set statusline+=%#DiffChange#
	set statusline+=\ %c:%l/%L\  "display column and line pos
endfunction

" let g:python3_host_prog='~\anaconda3\envs\pynvim\python.exe'
let g:python3_host_prog='C:\Windows\python.exe'
" set guifont=Consolas:h10
" :winpos -8 -1
set lines=48
set columns=210
set lines=999" cumns=999 "set fullscreen
"set tw=235
"set tw=187
set tw=90
noremap <M-m> :tabe $myvimrc<cr>
" Copy everything from file into clipboard
inoremap <C-a> <Esc>gg"*yG
" Copy selection to clipboard
noremap <C-c> "*y
"colorscheme hybrid
colorscheme gruvbox
"colorscheme catppuccin-mocha

func! CompileRun()
	exec "w"
	if &filetype == 'c'
		exec "!gcc -Wall % -o %<"
		exec "!%:r.exe"
		"exec "!time ./%<"
	elseif &filetype == 'cpp'
		"exec "!g++ % -o %< -lbgi -lgdi32 -lcomdlg32 -luuid -loleaut32 -lole32"
		exec "!g++ % -o %<"
		exec "!%:r.exe"
		"exec "!time ./%<"
	elseif &filetype == 'java'
		exec "!javac %"
		exec "!java -cp %:p:h %:t:r"
	elseif &filetype == 'sh'
		exec "!time bash %"
	elseif &filetype == 'python'
		exec "!python %"
	elseif &filetype == 'html'
		exec "!firefox % &"
	elseif &filetype == 'javascript'
		exec "!node %"
	elseif &filetype == 'jsx'
		exec "!node %"
	elseif &filetype == 'typescript'
		exec "!node %"
	elseif &filetype == 'go'
		exec "!go build %<"
		exec "!time go run %"
	elseif &filetype == 'mkd'
		exec "!~/.vim/markdown.pl % > %.html &"
		exec "!firefox %.html &"
	elseif &filetype == 'cs'
		exec "!csc %"
		exec "!%:r.exe"
	endif
endfunc
endif

set completeopt=menu,menuone,noselect
set completeopt+=longest,menuone
set completeopt+=preview

lua <<EOF
  -- Set up nvim-cmp.
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

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Set up lspconfig.
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  require('lspconfig')['pyright'].setup {
    capabilities = capabilities
  }
EOF
