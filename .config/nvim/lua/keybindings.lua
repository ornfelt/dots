local g   = vim.g

-- Map <leader> to space
g.mapleader = ' '
g.maplocalleader = ' '

-- Keybinds
local function map(m, k, v)
    vim.keymap.set(m, k, v, { silent = true })
end

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

map('n', '<M-q>', ':q<CR>') -- Quit
map('n', '<M-z>', ':noh<CR>')
map('n', 'Y', 'y$') -- Yank till end of line

--map('x', '<leader>p', "\"_dP") -- Replace from void
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

-- NERDTree
-- map('n', '<M-w>', ':NERDTreeToggle ~/<CR>')
-- map('n', '<M-e>', ':NERDTreeToggle %:p<CR>')
map('n', '<M-w>', ':silent! NERDTreeToggle ~/<CR>')
map('n', '<M-e>', ':silent! NERDTreeToggle %:p<CR>')

-- FZF
----map('n', '<M-a>', ':FZF ./<CR>')
--map('n', '<M-W>', ':FZF ./<CR>')
--map('n', '<M-A>', ':FZF ~/<CR>')
map('n', '<M-S>', ':FZF ' .. (vim.fn.has('unix') == 1 and '/' or 'C:/') .. '<CR>')

-- fzf-lua
--local fzf_lua = require('fzf-lua')
--local opts = { noremap = true, silent = true }
--vim.api.nvim_set_keymap('n', '<M-a>', ":lua require('fzf-lua').git_files()<CR>", opts)
--vim.api.nvim_set_keymap('n', '<M-A>', ":lua require('fzf-lua').files()<CR>", opts)
----vim.api.nvim_set_keymap('n', 'M-W', ":lua require('fzf-lua').files({ cwd = os.getenv('HOME') })<CR>", opts)
--map('n', '<M-W>', ":lua require('fzf-lua').files({ cwd = '~/' })<CR>")
--local root_dir = vim.fn.has('unix') == 1 and '/' or 'C:/'
--map('n', '<M-S>', ":lua require('fzf-lua').files({ cwd = '" .. root_dir .. "' })<CR>")

-- Start FZF from a given environment variable
local function FZFStart(env_var)
    local default_path = (env_var == "my_notes_path") and "~/Documents/my_notes" or "~"
    local path = os.getenv(env_var) or default_path
    path = path:gsub(" ", '\\ ')
    vim.cmd("FZF " .. path)
    --fzf_lua.files({ cwd = path })
end

vim.api.nvim_create_user_command('RunFZFCodeRootDir', function() FZFStart("code_root_dir") end, {})
vim.api.nvim_set_keymap('n', '<leader>a', '<cmd>RunFZFCodeRootDir<CR>', { noremap = true, silent = true })

vim.api.nvim_create_user_command('RunFZFMyNotesPath', function() FZFStart("my_notes_path") end, {})
vim.api.nvim_set_keymap('n', '<leader>f', '<cmd>RunFZFMyNotesPath<CR>', { noremap = true, silent = true })

-- Vimgrep and QuickFix Lists
map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>0f/li')
map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>0f/li') -- Search all
map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>0f/li') -- Search dotfiles
map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>0f/li')
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
map('n', '<M-j>', '<Plug>WinMoveDown')
map('n', '<M-k>', '<Plug>WinMoveUp')
map('n', '<M-l>', '<Plug>WinMoveRight')
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', '<leader>l', ':Tabmerge right<CR>')

-- Moving text
map('x', 'J', ":move '>+1<CR>gv=gv")
map('x', 'K', ":move '<-2<CR>gv=gv")
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
map('n', '<M-.>', ':tabe ~/Documents/my_notes/vimtutor.txt<CR>')

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
map('n', '<leader>*', [[:/^\*\*\*$<CR>]]) -- Search for my bookmark
map('v', '<leader>%', '/\\%V') -- Search in highlighted text
map('v', '<leader>/', '"3y/<C-R>3<CR>') -- Search for highlighted text
map("n", "Q", "<nop>") -- Remove Ex Mode
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Replace word under cursor
vim.keymap.set("n", "<leader>t", "<cmd>silent !tmux neww tmux-sessionizer<CR>") -- Start tmux-sessionizer
vim.keymap.set('n', '<leader>df', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>db', '<cmd>lua vim.diagnostic.setqflist()<CR>', { noremap = true, silent = true })

function ReplaceQuotes()
  vim.cmd([[
    %s/[‘’]/'/g
    %s/[“”]/"/g
  ]])
end

vim.api.nvim_set_keymap('n', '<leader>wr', ':lua ReplaceQuotes()<CR>', { noremap = true, silent = true })

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

-- Helper function for setting key mappings for filetypes
local function create_hellow_mapping(ft, template_file)
  local code_root_dir = os.getenv("code_root_dir") or "~/"
  code_root_dir = code_root_dir:gsub(" ", '" "')
  if not template_file then
    template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. ft
  else
    template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. template_file
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local map_opts = { noremap = true, silent = true }
      vim.api.nvim_buf_set_keymap(0, 'i', 'hellow<Tab>', '<Esc>:r ' .. template_file .. '<Enter>', map_opts)
    end
  })
end

vim.keymap.set("i", "<m-,>", function()
    print("hi")
    vim.ui.input({ prompt = "Calc: " }, function(input)
        local calc = load("return " .. (input or ""))()
        if (calc) then
            vim.api.nvim_feedkeys(tostring(calc), "i", true)
        end
    end)
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

function compile_run()
    vim.cmd('w') -- Save the file first

    local filetype = vim.bo.filetype
    local is_windows = vim.fn.has('win32') == 1 -- or vim.fn.has('win16') == 1 or vim.fn.has('win64') == 1

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
        vim.cmd(is_windows and '!tsc; node ' .. js_file or '!tsc && time node ' .. js_file)
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
    else
        print("Compilation of " .. filetype .. " extensions not configured..")
    end
end

vim.api.nvim_set_keymap('n', '<M-x>', '<Cmd>lua compile_run()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-S-X>', '<Cmd>!chmod +x %<CR>', { noremap = true, silent = true })

-- " Execute line under the cursor
-- nnoremap <leader>w yy:@"<CR>
--vim.api.nvim_set_keymap('n', '<leader>w', 'yy:@"<CR>', { noremap = true, silent = true })
--
-- Function to execute command under cursor or highlighted text
function execute_command()
  local mode = vim.fn.mode()
  local command

  if mode == 'v' or mode == 'V' then
    vim.cmd('normal! gv"xy')
    command = vim.fn.getreg('x')
  else
    command = vim.fn.getline('.')
  end

  vim.cmd(command)
end

vim.api.nvim_set_keymap('n', '<leader>w', ':lua execute_command()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>w', ':lua execute_command()<CR>', { noremap = true, silent = true })

