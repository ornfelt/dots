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
-- map('i', '<C-a>', '<Esc>gg"yG') -- Copy everything from file into clipboard
-- map('i', '<C-BS>', '<C-W>a') -- Copy everything from file into clipboard
-- map('i', '<S-Tab>', '<BS>')
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
map('n', '<leader>1', '"0p')
map('n', '<leader>2', '"1p')
map('n', '<leader>3', ':reg<CR>')
map('n', '<leader>4', ':put a<CR>')
map('n', '<leader>5', '"ay$')
map('v', '<leader>1', '"0p')
map('v', '<leader>2', '"1p')
map('v', '<leader>3', ':reg<CR>')
map('v', '<leader>4', ':put a<CR>')
map('v', '<leader>5', '"ay$')

-- Helper functions
local function is_vim_plugin_installed(plugin_name)
    return vim.fn.exists(':' .. plugin_name) ~= 0
end

local function is_plugin_installed(plugin_name)
    local status, _ = pcall(require, plugin_name)
    return status
end

-- File tree
-- map('n', '<M-e>', ':silent! NERDTreeToggle %:p<CR>')
if is_vim_plugin_installed('NERDTreeToggle') then
    map('n', '<M-w>', ':silent! NERDTreeToggle ~/<CR>')
elseif is_plugin_installed('oil') then
	require('oil').setup({
        keymaps = {
            ["<C-s>"] = { "actions.select", opts = { vertical = true, close = true }, desc = "Open the entry in a vertical split" },
            ["<C-h>"] = { "actions.select", opts = { horizontal = true, close = true }, desc = "Open the entry in a horizontal split" },
            ["<C-t>"] = { "actions.select", opts = { tab = true, close = true }, desc = "Open the entry in new tab" },
        },
		view_options = {
			show_hidden = true,
		},
        -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
        skip_confirm_for_simple_edits = false,
        -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
        -- (:help prompt_save_on_select_new_entry)
        prompt_save_on_select_new_entry = true,
    })
    -- map('n', '<M-w>', ':leftabove vsplit | vertical resize 40 | Oil ~/ <CR>')
    -- map('n', '<M-w>', ':Oil ~/ <CR>')
    vim.keymap.set('n', '<M-w>', function()
    if vim.bo.filetype == 'oil' then
        -- vim.cmd('bd')
        vim.cmd('b#')
    else
        vim.cmd('Oil ~/')
    end
    end)
elseif pcall(require, 'mini.files') then
    require('mini.files').setup()
    map('n', '<M-w>', ':lua MiniFiles.open("~/")<CR>')
end

-- vim.api.nvim_create_user_command('OilToggle', function()
   -- vim.cmd((vim.bo.filetype == 'oil') and 'bd' or 'Oil')
-- end, { nargs = 0 })

function toggle_filetree()
    --local filepath = (vim.fn.expand('%:p') == '' and '~/' or vim.fn.expand('%:p'))
    local filepath = vim.fn.expand('%:p') == '' and '~/' or './' -- or vim.fn.expand('%:p:h') -- dir
    if is_vim_plugin_installed('NERDTreeToggle') then
        vim.cmd('silent! NERDTreeToggle ' .. filepath)
    elseif is_plugin_installed('oil') then
        -- vim.cmd('leftabove vsplit | vertical resize 40 | Oil ' .. filepath)
        -- vim.cmd('Oil ' .. filepath)
        vim.cmd((vim.bo.filetype == 'oil') and 'b#' or 'Oil ' .. filepath)
    elseif pcall(require, 'mini.files') then
        require('mini.files').open(filepath)
    else
        print("No file tree plugin installed...")
    end
end

map('n', '<M-e>', ':lua toggle_filetree()<CR>')

-- NERDCommenter
map('n', '<C-k>', ':call nerdcommenter#Comment(0, "toggle")<CR>')
map('v', '<C-k>', '<Plug>NERDCommenterToggle')

-- fzf
local fzf_vim_installed = pcall(function() return vim.fn['fzf#run'] end)
if fzf_vim_installed then
    ----map('n', '<M-a>', ':FZF ./<CR>')
    --map('n', '<M-W>', ':FZF ./<CR>')
    --map('n', '<M-A>', ':FZF ~/<CR>')
    map('n', '<M-S>', ':FZF ' .. (vim.fn.has('unix') == 1 and '/' or 'C:/') .. '<CR>')
end

-- fzf-lua
local fzf_lua_installed = pcall(require, 'fzf-lua')
if fzf_lua_installed then
    --local opts = { noremap = true, silent = true }
    --vim.api.nvim_set_keymap('n', '<M-a>', ":lua require('fzf-lua').git_files()<CR>", opts)
    --vim.api.nvim_set_keymap('n', '<M-A>', ":lua require('fzf-lua').files()<CR>", opts)
    ----vim.api.nvim_set_keymap('n', 'M-W', ":lua require('fzf-lua').files({ cwd = os.getenv('HOME') })<CR>", opts)
    --map('n', '<M-W>', ":lua require('fzf-lua').files({ cwd = '~/' })<CR>")
    local root_dir = vim.fn.has('unix') == 1 and '/' or 'C:/'
    map('n', '<M-S>', ":lua require('fzf-lua').files({ cwd = '" .. root_dir .. "' })<CR>")
end

-- Start fzf/telescope from a given environment variable
function StartFinder(env_var, additional_path)
    local default_path = (env_var == "my_notes_path") and "~/Documents/my_notes" or "~"
    local path = os.getenv(env_var) or default_path

    if additional_path then
        path = path .. "/" .. additional_path
    end

    -- Search using fzf.vim
    --path = path:gsub(" ", '\\ ')
    --vim.cmd("FZF " .. path)

    -- Search using fzf.lua
    --local fzf_lua = require('fzf-lua')
    --fzf_lua.files({ cwd = path })

    -- Search using telescope
    local telescope_builtin = require('telescope.builtin')
    telescope_builtin.find_files({
        cwd = path,
        hidden = env_var == "my_notes_path",
        prompt_title = "Search in " .. path,
    })
end

-- vim.api.nvim_create_user_command('RunFZFCodeRootDirWithCode', function() StartFinder("code_root_dir", "Code") end, {})
-- vim.api.nvim_set_keymap('n', '<leader>a', '<cmd>RunFZFCodeRootDirWithCode<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>a', ':lua StartFinder("code_root_dir", "Code")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>s', ':lua StartFinder("code_root_dir", "Code2")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>A', ':lua StartFinder("code_root_dir")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':lua StartFinder("my_notes_path")<CR>', { noremap = true, silent = true })

-- Vimgrep and QuickFix Lists
map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>0f/li')
map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>0f/li') -- Search all
map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>0f/li') -- Search dotfiles
map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>0f/li')
-- map('n', '<M-v>', ':cfdo s//x/gc<left><left><left><left><left><C-f>i')
map('n', '<M-n>', ':cnext<CR>')
map('n', '<M-p>', ':cprev<CR>')
map('n', '<M-P>', ':clast<CR>')
-- map('n', '<M-b>', ':copen<CR>')
-- Function to toggle the quickfix list
function ToggleQuickfix()
    local is_open = false

    -- Check if the quickfix window is open
    for _, win in ipairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 then
            is_open = true
            break
        end
    end

    if is_open then
        vim.cmd("cclose")
    else
        vim.cmd("copen")
    end
end
vim.api.nvim_set_keymap('n', '<M-b>', ':lua ToggleQuickfix()<CR>', { noremap = true, silent = true })

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
-- Navigate between splits from terminal
map('t', '<M-h>', [[<C-\><C-n><C-w>h]])
map('t', '<M-j>', [[<C-\><C-n><C-w>j]])
map('t', '<M-k>', [[<C-\><C-n><C-w>k]])
map('t', '<M-l>', [[<C-\><C-n><C-w>l]])
map('t', '<M-q>', [[<C-\><C-n>:q<CR>]])
map('t', '<Esc>', [[<C-\><C-n>]])

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
map('n', '<M-Enter>', ':vsp | terminal ' .. (vim.loop.os_uname().sysname == "Windows_NT" and "powershell" or "") .. '<CR>')
map('n', '<M-<>', ':split | terminal ' .. (vim.loop.os_uname().sysname == "Windows_NT" and "powershell" or "") .. '<CR>')
--if vim.fn.has('win32') == 1 and vim.fn.exists('g:GuiLoaded') == 1 then
--if vim.fn.has('win32') == 1 and vim.g.neovide then
    --map('n', '<M-Enter>', ':10 sp :let $VIM_DIR=expand("%:p:h")<CR>:terminal<CR>cd $VIM_DIR<CR>')
--end

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
map('n', '<leader>o', '<C-^>')

-- Session management
-- map('n', '<leader>m', ':mks! ~/.vim/sessions/s.vim<CR>')
map('n', '<leader>.', ':silent so ~/.vim/sessions/s.vim<CR>')

function save_tabs_and_splits()
  local tab_count = vim.fn.tabpagenr('$')
  if tab_count > 2 then
    local current_tab = vim.fn.tabpagenr()
    local current_win = vim.fn.winnr()

    local file = io.open(vim.fn.expand("~/.vim/sessions/s_layout.vim"), "w")
    file:write(tab_count .. "\n")

    for i = 1, tab_count do
      vim.cmd(i .. "tabnext")

      local win_count = vim.fn.winnr('$')
      file:write(win_count .. "\n")

      for j = 1, win_count do
        vim.cmd(j .. "wincmd w")
        local buf_name = vim.fn.bufname('%')
        if buf_name ~= "" then
          local full_path = vim.fn.fnamemodify(buf_name, ':p')
          file:write(full_path .. "\n")
        end
      end
    end

    file:write("TAB:" .. current_tab .. "\n")
    file:close()

    vim.cmd(current_tab .. "tabnext")
    vim.cmd(current_win .. "wincmd w")
    print("Session data saved to ~/.vim/sessions/")

    -- Call mks! to save the session
    vim.cmd("mks! ~/.vim/sessions/s.vim")
  else
    print("Not saving: Less than 3 tabs are open.")
  end
end

function load_tabs_and_splits()
  local file = io.open(vim.fn.expand("~/.vim/sessions/s_layout.vim"), "r")

  if file == nil then
    print("No saved layout found!")
    return
  end

  local tab_count = tonumber(file:read("*line"))
  local saved_tab = 1

  for i = 1, tab_count do
    if i > 1 then
      vim.cmd("tabnew")
    end

    local win_count = tonumber(file:read("*line"))

    for j = 1, win_count do
      if j > 1 then
          -- vim.cmd("split")
        vim.cmd("vsplit")
      end

      local buf_name = file:read("*line")
      if buf_name and buf_name ~= "" and not buf_name:match("^term://") then
        vim.cmd("edit " .. buf_name)
      end
    end
  end

  local last_line = file:read("*line")
  if last_line and last_line:match("^TAB:") then
    saved_tab = tonumber(last_line:sub(5))
  end

  file:close()

  if tab_count > 1 then
    -- vim.cmd("2tabnext")
    vim.cmd(saved_tab .. "tabnext")
  end
end

vim.api.nvim_set_keymap('n', '<leader>m', ':lua save_tabs_and_splits()<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>.', ':lua load_tabs_and_splits()<CR>', { noremap = true, silent = true })

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

map('n', '<leader>ws', "/\\s\\+$/<CR>") -- Show extra whitespace
map('n', '<leader>wr', ':%s/\\s\\+$<CR>') -- Remove all extra whitespace
map('n', '<leader>wu', ':%s/\\%u200b//g<CR>') -- Remove all extra unicode chars
map('n', '<leader>wb', ':%s/[[:cntrl:]]//g<CR>') -- Remove all hidden characters
map('n', '<leader>wf', 'gqG<C-o>zz') -- Format rest of the text with vim formatting, go back and center screen
map('v', '<leader>gu', ':s/\\<./\\u&/g<CR>:noh<CR>:noh<CR>') -- Capitalize first letter of each word on visually selected line
map('n', '<leader>*', [[:/^\*\*\*$<CR>]]) -- Search for my bookmark
map('v', '<leader>%', '/\\%V') -- Search in highlighted text
-- map('v', '<leader>/', '"3y/<C-R>3<CR>') -- Search for highlighted text
map('n', '<leader>/', function()
    local clipboard_text = vim.fn.getreg('+')
    if clipboard_text ~= "" then
        vim.cmd('/' .. vim.fn.escape(clipboard_text, '\\/'))
    else
        vim.notify("Clipboard is empty!", vim.log.levels.WARN)
    end
end)
map("n", "Q", "<nop>") -- Remove Ex Mode
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Replace word under cursor
vim.keymap.set("n", "<leader>ts", "<cmd>silent !tmux neww tmux-sessionizer<CR>") -- Start tmux-sessionizer
vim.keymap.set('n', '<leader>df', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>db', '<cmd>lua vim.diagnostic.setqflist()<CR>', { noremap = true, silent = true })

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

vim.api.nvim_set_keymap('n', '<leader>t', '<cmd>lua goto_last_tab()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>t', '<cmd>lua goto_last_tab()<CR>', { noremap = true, silent = true })

function ReplaceQuotes()
  vim.cmd([[
    silent! %s/[’‘’]/'/g
    silent! %s/[“”]/"/g
  ]])
end

vim.api.nvim_set_keymap('n', '<leader>wq', ':lua ReplaceQuotes()<CR>', { noremap = true, silent = true })

local function PythonCommand()
    vim.cmd('w') -- Save the file first
    local code_root_dir = os.getenv("code_root_dir") or "~/"
    code_root_dir = code_root_dir:gsub(" ", '" "')

    local command = "!python " .. code_root_dir .. "Code2/Python/my_py/scripts/"
    local mode = vim.fn.mode()

    if mode == 'v' or mode == 'V' or mode == '^V' then
        --vim.cmd('normal gv')
        vim.fn.feedkeys(":" .. command)
        -- local pos = #command
        -- vim.fn.setcmdpos(pos)
    else
        local current_file = vim.fn.expand("%:p")
        local current_line = vim.fn.line(".")

        -- local send_file_end = true
        local send_file_end = false
        local last_line = send_file_end and vim.fn.line("$") or ""

        local args = ' "' .. current_file .. '" ' .. current_line
        if send_file_end then
            args = args .. " " .. last_line
        end

        local full_command = command .. args
        vim.fn.feedkeys(":" .. full_command)

        -- vim.schedule(function()
            -- -- local pos = #command + 1
            -- vim.fn.setcmdpos(pos)
        -- end)
        local move_left_count = #args
        local move_left_keys = vim.api.nvim_replace_termcodes(string.rep("<Left>", move_left_count), true, false, true)
        vim.api.nvim_feedkeys(move_left_keys, "n", false)
    end
end

vim.api.nvim_create_user_command('RunPythonCommand', PythonCommand, {})
vim.api.nvim_set_keymap('v', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })

-- GPT binds
if is_plugin_installed('chatgpt') then
    local chatgpt_config = {
        openai_api_key = os.getenv("OPENAI_API_KEY"),
    }

    -- Model can be changed in actions for this plugin
    require("chatgpt").setup(chatgpt_config)

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
    map('i', '<M-c>', ':ChatGPTRun send_request<CR>')
end

if is_plugin_installed('gp') then
    local gp_config = {
        openai_api_key = os.getenv("OPENAI_API_KEY"),
        providers = {
            ollama = {
                disable = false,
                endpoint = "http://localhost:11434/v1/chat/completions",
                -- secret = "dummy_secret",
            },
        }
    }

    --require("gp").setup({openai_api_key: os.getenv("OPENAI_API_KEY")})
    require("gp").setup(gp_config)

    map('n', '<leader>e', ':GpAppend<CR>')
    map('v', '<leader>e', ':GpAppend<CR>')
    map('n', '<leader>x', ':GpTabnew<CR>')
    map('v', '<leader>x', ':GpTabnew<CR>')
    map('n', '<leader>c', ':GpNew<CR>')
    map('v', '<leader>c', ':GpNew<CR>')
    map('n', '<leader>v', ':GpVnew<CR>')
    map('v', '<leader>v', ':GpVnew<CR>')
    map('n', '<leader>g', ':GpRewrite<CR>')
    map('v', '<leader>g', ':GpRewrite<CR>')
    map('n', '<leader>6', ':GpImplement<CR>')
    map('v', '<leader>6', ':GpImplement<CR>')
    map('n', '<leader>7', ':GpChatRespond<CR>')
    map('v', '<leader>7', ':GpChatRespond<CR>')
    -- map('n', '<leader>8', ':GpChatFinder<CR>')
    -- map('v', '<leader>8', ':GpChatFinder<CR>')
    -- map('n', '<leader>8', ':GpContext<CR>')
    -- map('v', '<leader>8', ':GpContext<CR>')
    map('n', '<leader>8', ':GpNextAgent<CR>')
    map('v', '<leader>8', ':GpNextAgent<CR>')
    map('n', '<leader>9', ':GpChatNew<CR>')
    map('v', '<leader>9', ':GpChatNew<CR>')
    map('n', '<leader>0', ':GpChatToggle<CR>')
    map('v', '<leader>0', ':GpChatToggle<CR>')
    -- There's also:
    -- :GpAgent (for info)
    -- :GpWhisper
    -- :GpImage
    -- :GpStop
    -- etc.
end

-- Basic llama.cpp example request (no streaming)
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
    --local content = vim.fn.json_decode(response).content
    --local decoded_response = vim.fn.json_decode(response)
    local success, decoded_response = pcall(vim.fn.json_decode, response)
    if not success then
        decoded_response = nil
    end

    local default_msg = "llama is sleeping"
    local content = (decoded_response and decoded_response.content) or default_msg

    local split_newlines = vim.split(content, '\n', true)
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
    lines[1] = lines[1] .. split_newlines[1]
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, lines)
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, vim.list_slice(split_newlines, 2))
end

if is_plugin_installed('model') then
    local llamacpp = require('model.providers.llamacpp')

    require('model').setup({
    prompts = {
        zephyr = {
        provider = llamacpp,
        builder = function(input, context)
            return {
            prompt =
                '<|system|>'
                .. (context.args or 'You are a helpful assistant')
                .. '\n</s>\n<|user|>\n'
                .. input
                .. '</s>\n<|assistant|>',
            stop = { '</s>' }
            }
        end
        }
    }
    })

    vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Model zephyr<CR>', {noremap = true, silent = true})
else
    vim.api.nvim_create_user_command('Llm', llm, {})
    vim.api.nvim_set_keymap('n', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('i', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('v', '<M-->', '<Cmd>:Llm<CR>', {noremap = true, silent = true})
end

-- Helper function for setting key mappings for filetypes
local function create_hellow_mapping(ft, fe)
  local code_root_dir = os.getenv("code_root_dir") or "~/"
  code_root_dir = code_root_dir:gsub(" ", '" "')
  local template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. ft
  if fe then
      template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. fe
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local map_opts = { noremap = true, silent = true }
      vim.api.nvim_buf_set_keymap(0, 'i', 'hellow<Tab>', '<Esc>:r ' .. template_file .. '<Enter>', map_opts)
    end
  })
end

vim.keymap.set("i", "<m-+>", function()
    vim.ui.input({ prompt = "Calc: " }, function(input)
        local calc = load("return " .. (input or ""))()
        if (calc) then
            vim.api.nvim_feedkeys(tostring(calc), "i", true)
        end
    end)
end)

vim.keymap.set("v", "<m-+>", function()
    -- local start_pos = vim.fn.getpos("'<")
    -- local end_pos = vim.fn.getpos("'>")
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])
    local selected_text = table.concat(lines, "\n")
    local calc = load("return " .. selected_text)()
    if calc then
        vim.fn.cursor(end_pos[2], end_pos[3])
        vim.api.nvim_put({tostring(calc)}, 'l', true, true)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>k', true, false, true), 'n', true)
    end
end)

vim.keymap.set("n", "<m-+>", function()
    local current_line = vim.fn.getline('.')
    local calc = load("return " .. current_line)()
    if calc then
        local line_num = vim.fn.line('.')
        vim.fn.append(line_num, tostring(calc))
        -- All of these work
        -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('j', true, false, true), 'n', true)
        -- vim.fn.cursor(line_num + 1, 0)
        vim.cmd('normal! j')
        -- vim.api.nvim_exec('normal! j', false)
        -- vim.api.nvim_command('normal! j')
    end
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

local function SqlExecCommand()
    local code_root_dir = os.getenv("code_root_dir") or "~/"
    code_root_dir = code_root_dir:gsub(" ", '" "') -- Handle spaces in the path
    local executable = code_root_dir .. "Code2/Sql/my_sql/SqlExec/SqlExec/bin/Debug/net8.0/SqlExec.exe"
    local current_file = vim.fn.expand('%:p') -- Full path of current file
    local mode = vim.fn.mode()
    local args = { '"' .. current_file .. '"' }

    if mode == 'v' or mode == 'V' then
        -- vim.cmd('normal! gv') -- Re-select last visual selection to ensure it's active
        -- local start_pos = vim.fn.getpos("'<")
        -- local end_pos = vim.fn.getpos("'>")
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.fn.getpos(".")

        if start_pos[2] >= 1 and end_pos[2] >= 1 then
            if start_pos[2] > end_pos[2] then
                -- Visual select starts from bottom
                table.insert(args, end_pos[2]) -- Start line number
                table.insert(args, start_pos[2]) -- End line number
            else
                table.insert(args, start_pos[2]) -- Start line number
                table.insert(args, end_pos[2]) -- End line number
            end
        else
            print("Invalid visual selection range.")
            return
        end
    else
        local current_line = vim.fn.line(".")
        table.insert(args, current_line)
    end

    local formatted_args = table.concat(args, " ")
    local output = vim.fn.system(executable .. " " .. formatted_args)

    vim.cmd('belowright 15new')
    local new_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(output, "\n"))
end

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
    elseif filetype == 'sql' then
        SqlExecCommand()
    else
        print("Compilation of " .. filetype .. " extensions not configured..")
    end
end

vim.api.nvim_set_keymap('n', '<M-x>', '<Cmd>lua compile_run()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<M-x>', '<Cmd>lua compile_run()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-S-X>', '<Cmd>!chmod +x %<CR>', { noremap = true, silent = true })

-- " Execute line under the cursor
-- nnoremap <leader>, yy:@"<CR>
--vim.api.nvim_set_keymap('n', '<leader>,', 'yy:@"<CR>', { noremap = true, silent = true })
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

    -- Copy to clipboard
    --vim.fn.setreg('+', command)
    --print("Copied to clipboard: " .. command)
    -- Execute it
    vim.cmd(command)
end

vim.api.nvim_set_keymap('n', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })

--local actions_preview = require("actions-preview")
-- pcall for checking requirement safely
local actions_preview = pcall(require, "actions-preview") and require("actions-preview")
if actions_preview then
    vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
end

local function replace_placeholders(line)
    --  line = line:gsub("{code_root_dir}", vim.fn.getenv("code_root_dir") or "")
    -- Use gsub to find and replace all occurrences of {ENV_VAR_NAME}
    -- with corresponding environment variable value
    line = line:gsub("{(.-)}", function(env_var)
        return vim.fn.getenv(env_var) or ""
    end)
    return line
end

local function read_lines_from_file(file)
    local lines = {}
    for line in io.lines(file) do
        line = replace_placeholders(line)
        table.insert(lines, line)
    end
    return lines
end

function open_files_from_list()
    local my_notes_path = vim.fn.getenv("my_notes_path")
    local file_path = my_notes_path .. "/files.txt"
    local files = read_lines_from_file(file_path)

    ---- Use fzf file picker to display file paths (edit/tabedit)
    --vim.fn['fzf#run']({
    --  source = files,
    --  sink = function(selected)
    --    vim.cmd('edit ' .. selected)
    --  end,
    --  options = '--multi --prompt "Select a file to open> " --expect=ctrl-t',
    --  sinklist = function(selected)
    --    local key = selected[1]
    --    local file = selected[2]
    --    if key == "ctrl-t" then
    --      vim.cmd('tabedit ' .. file)
    --    else
    --      vim.cmd('edit ' .. file)
    --    end
    --  end
    --})

    ---- Use fzf-lua file picker to display file paths
    --require('fzf-lua').fzf_exec(files, {
    --  prompt = 'Select a file: ',
    --  actions = {
    --    ['default'] = function(selected)
    --      vim.cmd('edit ' .. selected[1])
    --    end,
    --    ['ctrl-t'] = function(selected)
    --      vim.cmd('tabedit ' .. selected[1])
    --    end,
    --  }
    --})

    -- Use Telescope file picker to display file paths
    require('telescope.pickers').new({}, {
        prompt_title = "Select a file to open",
        finder = require('telescope.finders').new_table({
            results = files,
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        attach_mappings = function(_, map)
            local actions = require('telescope.actions')
            local action_state = require('telescope.actions.state')

            map('i', '<CR>', function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.cmd('edit ' .. selection.value)
            end)

            map('i', '<C-t>', function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.cmd('tabedit ' .. selection.value)
            end)

            map('n', '<CR>', function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.cmd('edit ' .. selection.value)
            end)

            map('n', '<C-t>', function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.cmd('tabedit ' .. selection.value)
            end)

            return true
        end,
    }):find()
end

vim.api.nvim_set_keymap('n', '<leader>w', ':lua open_files_from_list()<CR>', { noremap = true, silent = true })

local function get_current_file_path()
    local file_path = vim.api.nvim_buf_get_name(0) -- Name of current buffer
    if file_path == "" then
        return ""
    else
        return vim.fn.fnamemodify(file_path, ":p") -- Convert to full path
    end
    --return vim.fn.expand("%:p")
end

function copy_current_file_path()
    local path = get_current_file_path()
    if path == "" then
        print("No file in current buffer")
    else
        vim.fn.setreg('+', path)
        print("Copied to clipboard: " .. path)
    end
end

vim.api.nvim_set_keymap('n', '<leader>-', ':lua copy_current_file_path()<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>gl', function()
    require('gitgraph').draw({}, { all = true, max_count = 5000 })
end, { desc = "GitGraph - Draw" })

function PythonExecCommand()
    vim.cmd('w') -- Save the file first
    local code_root_dir = os.getenv("code_root_dir") or "~/"
    code_root_dir = code_root_dir:gsub(" ", '" "')
    -- local script_path = code_root_dir .. "Code2/Python/my_py/scripts/read_file.py"
    local script_path = code_root_dir .. "Code2/Python/my_py/scripts/gpt.py"
    -- local script_path = code_root_dir .. "Code2/Python/my_py/scripts/claude/claude.py"
    -- local script_path = code_root_dir .. "Code2/Python/my_py/scripts/gemini/gemini.py"
    -- local script_path = code_root_dir .. "Code2/Python/my_py/scripts/mistral/mistral.py"
    local print_to_current_buffer = false
    local current_file = vim.fn.expand('%:p')
    local mode = vim.fn.mode()
    local args = { '"' .. current_file .. '"' }

    if mode == 'v' or mode == 'V' then
        -- vim.cmd('normal! gv')
        -- local start_pos = vim.fn.getpos("'<")
        -- local end_pos = vim.fn.getpos("'>")
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.fn.getpos(".")

        if start_pos[2] >= 1 and end_pos[2] >= 1 then
            if start_pos[2] > end_pos[2] then
                -- Visual select starts from bottom
                table.insert(args, end_pos[2]) -- Start line number
                table.insert(args, start_pos[2]) -- End line number
            else
                table.insert(args, start_pos[2]) -- Start line number
                table.insert(args, end_pos[2]) -- End line number
            end
        else
            print("Invalid visual selection range.")
            return
        end
    elseif mode == 'i' then
        local current_line = vim.fn.line(".")
        table.insert(args, current_line)
    else
        local current_line = vim.fn.line(".")
        table.insert(args, current_line)
    end

    local formatted_args = table.concat(args, " ")
    local cmd = "python " .. script_path .. " " .. formatted_args
    local output = vim.fn.system(cmd)
    -- print("args: " .. formatted_args)

    if print_to_current_buffer then
        local current_buf = vim.api.nvim_get_current_buf()
        local line_count = vim.api.nvim_buf_line_count(current_buf)
        vim.api.nvim_buf_set_lines(current_buf, line_count, line_count, false, vim.split(output, "\n"))
    else
        vim.cmd('belowright 20new')
        local new_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(output, "\n"))
        -- Testing args
        -- vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(formatted_args, "\n"))
    end
end

vim.api.nvim_set_keymap('n', '<M-c>', '<cmd>lua PythonExecCommand()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<M-c>', '<cmd>lua PythonExecCommand()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<M-c>', '<cmd>lua PythonExecCommand()<CR>', { noremap = true, silent = true })

function open_file_with_env()
    -- local cword = vim.fn.expand("<cfile>")
    local cword = vim.fn.expand("<cWORD>")
    -- Removes everything before drive letter (may appear in diff files)
    local trimmed_cword = cword:match("([a-zA-Z]:.*)")
    if trimmed_cword ~= nil then
        cword = trimmed_cword
    end
    -- print("cword: " .. cword)

    if cword:find("{") then
        local new_cword = cword:gsub("{(.-)}", function(var)
            local value = os.getenv(var)
            if value then
                return value
            else
                print("Environment variable " .. var .. " not found.")
                return nil
            end
        end)

        if new_cword == cword then
            return
        end
        -- print("new_cword: " .. new_cword)

        -- vim.cmd("edit " .. new_cword)
        vim.cmd("tabe " .. new_cword)
    else
        -- vim.cmd("edit " .. cword)
        vim.cmd("tabe " .. cword)
    end
end

vim.api.nvim_set_keymap('n', 'gf', ':lua open_file_with_env()<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'gx', ':!open <cWORD><CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gx', ':!nohup firefox <cWORD> &<CR>', { noremap = true, silent = true })

local function diff_copy()
    local current_buf = vim.api.nvim_get_current_buf()

    local windows = vim.api.nvim_list_wins()
    local other_buf
    for _, win in ipairs(windows) do
        if vim.api.nvim_win_get_buf(win) ~= current_buf then
            other_buf = vim.api.nvim_win_get_buf(win)
            break
        end
    end

    local file_paths = {}
    if current_buf and vim.api.nvim_buf_is_loaded(current_buf) then
        local path = vim.api.nvim_buf_get_name(current_buf)
        if path ~= "" then
            table.insert(file_paths, path)
        end
    end

    if other_buf and vim.api.nvim_buf_is_loaded(other_buf) then
        local path = vim.api.nvim_buf_get_name(other_buf)
        if path ~= "" then
            table.insert(file_paths, path)
        end
    end

    if #file_paths < 2 then
        print("Not enough files to copy.")
        return
    end

    local target1 = "C:/local/testing_files/test1.txt"
    local target2 = "C:/local/testing_files/test2.txt"

    vim.cmd(string.format("silent !cp %s %s", file_paths[1], target1))
    vim.cmd(string.format("silent !cp %s %s", file_paths[2], target2))
    print("Files copied to C:/local/testing_files.")
end

vim.api.nvim_create_user_command('DiffCp', diff_copy, {})

local function diff_current_lines()
    local line_number = vim.fn.line('.')
    local current_line = vim.fn.getline(line_number)
    local next_line = vim.fn.getline(line_number + 1)

    local file_paths = {}
    for path in current_line:gmatch('"%s*(%S+)"%s*') do
        table.insert(file_paths, path)
    end

    if #file_paths < 2 and next_line ~= "" then
        for path in next_line:gmatch('"%s*(%S+)"%s*') do
            table.insert(file_paths, path)
            if #file_paths >= 2 then
                break
            end
        end
    end

    if #file_paths < 2 then
        print("Not enough file paths found for diff.")
        return
    end

    for i, file_path in ipairs(file_paths) do
        local trimmed_fp = file_path:match("([a-zA-Z]:.*)")
        if trimmed_fp ~= nil then
            file_paths[i] = trimmed_fp
        end
    end

    vim.cmd(string.format("edit %s", file_paths[1]))
    vim.cmd("diffthis")
    vim.cmd(string.format("vert diffsplit %s", file_paths[2]))
end

vim.api.nvim_create_user_command('Diffi', diff_current_lines, {})

