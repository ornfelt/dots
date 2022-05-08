if &compatible
  set nocompatible               " Be iMproved
endif

" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf'
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'
Plug 'justinmk/vim-sneak'
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}
Plug 'morhetz/gruvbox'
Plug 'w0ng/vim-hybrid'
Plug 'sainnhe/sonokai'
Plug 'vim-syntastic/syntastic'
Plug 'ap/vim-css-color'
Plug 'tpope/vim-commentary'
Plug 'mhinz/vim-startify'
Plug 'vimwiki/vimwiki'
Plug 'dracula/vim'
Plug 'jalvesaq/vimcmdline'
"Plug 'nvim-treesitter/nvim-treesitter'

" Initialize plugin system
call plug#end()

"let g:python3_host_prog='/bin/python3'
"let g:coc_node_path = "/usr/bin/node"
set runtimepath+=~/.vim
set rtp+=~/.fzf
" Get syntax highlighting
"let mysyntaxfile = "~/.vim/syntax/vtxt.vim"
"au BufRead,BufNewFile *.vtxt set filetype=vtxt
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
"set guifont=Consolas:h10
":winpos -8 -1
set backspace=indent,eol,start
"set lines=48
"set columns=210
"set lines=999" cumns=999 "set fullscreen
"set tw=235
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
set t_Co=256
highlight Normal ctermbg=NONE
highlight CursorLine cterm=NONE ctermbg=darkblue
set cursorline
set autochdir
set scrolloff=8
set noswapfile
set complete+=kspell
set shortmess+=c
set completeopt+=longest,menuone
set completeopt+=preview
let g:jedi#popup_on_dot = 1

" If on laptop
if !empty(glob("~/isLaptop.txt"))
	colorscheme gruvbox
	set tw=180
else
	"colorscheme hybrid
	colorscheme gruvbox
	"colorscheme dracula
endif

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

" Vimgrep and QuickFix Lists
nnoremap <M-f> :vimgrep // **/*.txt<left><left><left><left><left><left><left><left><left><left><C-f>i
nnoremap <M-g> :vimgrep // **/*<Left><Left><Left><Left><Left><Left><C-f>i
nnoremap <M-h> :cfdo s//x/gc<left><left><left><left><left><C-f>i
nnoremap <M-c> :cnext<CR>
nnoremap <M-p> :cprev<CR>
nnoremap <M-l> :clast<CR>
nnoremap <M-b> :copen<CR>

" Format rest of the text with vim formatting, go back and center screen
nnoremap <M-r> gqG<C-o>zz

" Neovim FZF
nnoremap <M-a> :FZF <cr>
nnoremap <M-d> :FZF ../../..<cr>
nnoremap <M-o> :FZF /<cr>

" NERDTree
map <M-w> :NERDTree ~/<CR>
nnoremap <M-e> :NERDTreeToggle %:p<CR>
map <C-b> :NERDTreeToggle<CR>
" Open Nerd Tree in home folder

" Settings
map <M-z> :noh<CR>
map <M-x> :call CompileRun()<CR>
map <F4> <Esc>:set cursorline!<CR>
map <F5> <Esc>:setlocal spell! spelllang=en_us<CR>
map <F6> <Esc>:setlocal spell! spelllang=sv<CR>

" Window management and movement
nnoremap <Down> :resize +2<CR>
nnoremap <Up> :resize -2<CR>
nnoremap <Right> :vertical resize +2<CR>
nnoremap <Left> :vertical resize -2<CR>
map <silent> <C-h> <Plug>WinMoveLeft
map <silent> <C-j> <Plug>WinMoveDown
map <silent> <C-k> <Plug>WinMoveUp
map <silent> <C-l> <Plug>WinMoveRight
xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv
xnoremap <leader>j :join<CR>
xnoremap <leader>ju :join!<CR>
nmap <leader>z <Plug>Zoom

" Tab maps
nnoremap <M-q> :q<cr>
nnoremap <M-t> :tabe<cr>
nnoremap <M-s> :split<cr>
nnoremap <M-Enter> :vsp<cr>
nnoremap <M-<> :vsp<cr>

" Go to tab by number
" noremap <leader>1 1gt
" noremap <leader>2 2gt
" noremap <leader>3 3gt
" noremap <leader>4 4gt
" noremap <leader>5 5gt
" noremap <leader>6 6gt
" noremap <leader>7 7gt
" noremap <leader>8 8gt
" noremap <leader>9 9gt
noremap <M-0> :tablast<cr>
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

" Open vim config in new tab
noremap <M-m> :tabe ~/.config/nvim/init.vim<cr>
" Open i3 config in new tab
noremap <M-,> :tabe ~/.config/i3/config<cr>
" Open zshrc in new tab
noremap <M-.> :tabe ~/.zshrc<cr>

" Go to last active tab
au TabLeave * let g:lasttab = tabpagenr()
nnoremap <silent> <leader>l :exe "tabn ".g:lasttab<cr>
vnoremap <silent> <leader>l :exe "tabn ".g:lasttab<cr>
nnoremap <leder>o <C-^>

" Copy everything from file into clipboard
inoremap <C-a> <Esc>gg"*yG
" Copy selection to clipboard
noremap <C-c> y

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

autocmd FileType cs inoremap sout<Tab> Console.WriteLine("");<Esc>?""<Enter>li
autocmd FileType cs inoremap fore<Tab> for each (object o : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw
autocmd FileType cs inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw

autocmd FileType sql inoremap fun<Tab> delimiter //<Enter>create function x ()<Enter>returns int<Enter>no sql<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN
autocmd FileType sql inoremap pro<Tab> delimiter //<Enter>create procedure x ()<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN
autocmd FileType sql inoremap vie<Tab> create view x as<Enter>select <Esc>/x<Enter>GN

autocmd FileType vtxt,text inoremap <line<Tab> --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------<Enter>
autocmd FileType vtxt,text inoremap <date<Tab> <-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->
autocmd FileType c inoremap for<Tab> for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw

" Statusline
"set statusline=
"set laststatus=2
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"set statusline+=%#Difftext#
"set statusline+=\ %M "track if changes has been made to file
"set statusline+=\ %y "show filetype
"set statusline+=\ %r "ReadOnly flag
"set statusline+=\ %F "show full path to file
"set statusline+=%= "right side settings
"set statusline+=%#DiffChange#
"set statusline+=\ %c:%l/%L "display column and line pos
"set statusline+=\ %p%% "display percentage traversed of file

" Syntastic
"let g:syntastic_always_populate_loc_list = 0
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" Better tabbing
vnoremap < <gv
vnoremap > >gv
"imap <C-v> <C-r>+
imap <C-v> <Esc>"+gP
vnoremap  <leader>d "xd
nnoremap  <leader>d "xd

" Function for compiling code
func! CompileRun()
    exec "w"
    if &filetype == 'c'
        exec "!gcc % && ./a.out"
    elseif &filetype == 'cpp'
        exec "!g++ % -o %<"
		exec "!%:r.exe"
    elseif &filetype == 'java'
        "exec "!java -cp %:p:h %:t:r"
        exec "!java %"
    elseif &filetype == 'sh'
        exec "!time bash %"
    elseif &filetype == 'python'
        exec "!python3 %"
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
        exec "!mcs % && mono ./%:t:r.exe"
    endif
endfunc

" Syntax highlighting for vtxt
"hi vtxtBlueRegion ctermfg=blue  guifg=#0000FF
"hi vtxtCyanRegion ctermfg=cyan  guifg=#00CED1
"hi vtxtGreenRegion ctermfg=green  guifg=#98FB98
"hi vtxtPurpleRegion ctermfg=Magenta  guifg=#ae81ff
"hi vtxtRedRegion ctermfg=red  guifg=#fb4934
"hi vtxtOrangeRegion ctermfg=yellow  guifg=#d79921
"hi vtxtYellowRegion ctermfg=lightyellow  guifg=#E6DB74
"hi vtxtDateRegion ctermfg=Magenta  guifg=#ae81ff
"hi vtxtDot ctermfg=green  guifg=#98FB98
"hi vtxtStar ctermfg=red  guifg=#fb4934
"hi vtxtLine ctermfg=yellow  guifg=#d79921
"hi vtxtComment ctermfg=cyan  guifg=#00CED1

" Function for toggling the bottom statusbar:
let s:hidden_all = 1
function! ToggleHiddenAll()
    if s:hidden_all  == 0
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
nnoremap <leader>h :call ToggleHiddenAll()<CR>

" Use tab and s-tab to navigate the completion list
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Make shift-insert work like in Xterm
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>
inoremap <S-Insert> <Esc><MiddleMouse>A

" Coc config deleted: \ 'coc-python', at: 21-07-02
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-java',
  \ 'coc-tsserver',
  \ 'coc-json',
  \ 'coc-clangd',
  \ ]
" Remap for rename current word
nmap <F2> <Plug>(coc-rename)
" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
xmap <leader>fg  mcggVG<Plug>(coc-format-selected)'c
nmap <leader>fg  mcggVG<Plug>(coc-format-selected)'c
" Show all diagnostics using CocList
nnoremap <silent> <leader>g  :<C-u>CocList diagnostics<cr>
" Prettier command for coc
command! -nargs=0 Prettier :CocCommand prettier.formatFile

" Show extra whitespace
nmap <leader>ws /\s\+$/<cr>
" Remove extra whitespace
nmap <leader>fs :%s/\s\+$<cr>

" Map Ctrl-Backspace to delete the previous word in insert mode.
imap <C-BS> <C-W>a

highlight Normal guibg=none
highlight NonText guibg=none
highlight LineNr cterm=NONE ctermfg=grey gui=NONE guifg=grey guibg=NONE term=bold

set clipboard=unnamedplus
