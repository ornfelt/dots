local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path
local selected_file_picker = myconfig.get_file_picker()

-- fzf
local fzf_vim_installed = pcall(function() return vim.fn['fzf#run'] end)
--if fzf_vim_installed then
--    ----myconfig.map('n', '<M-a>', ':FZF ./<CR>')
--    --myconfig.map('n', '<M-W>', ':FZF ./<CR>')
--    --myconfig.map('n', '<M-A>', ':FZF ~/<CR>')
--    myconfig.map('n', '<M-S>', ':FZF ' .. (vim.fn.has('unix') == 1 and '/' or 'C:/') .. '<CR>')
--end
--
-- fzf-lua
local fzf_lua_installed = pcall(require, 'fzf-lua')
--if fzf_lua_installed then
--    --local opts = { noremap = true, silent = true }
--    --vim.api.nvim_set_keymap('n', '<M-a>', ":lua require('fzf-lua').git_files()<CR>", opts)
--    --vim.api.nvim_set_keymap('n', '<M-A>', ":lua require('fzf-lua').files()<CR>", opts)
--    ----vim.api.nvim_set_keymap('n', 'M-W', ":lua require('fzf-lua').files({ cwd = os.getenv('HOME') })<CR>", opts)
--    --myconfig.map('n', '<M-W>', ":lua require('fzf-lua').files({ cwd = '~/' })<CR>")
--    local root_dir = vim.fn.has('unix') == 1 and '/' or 'C:/'
--    myconfig.map('n', '<M-S>', ":lua require('fzf-lua').files({ cwd = '" .. root_dir .. "' })<CR>")
--end

local use_fzf = selected_file_picker == myconfig.FilePicker.FZF
local use_fzf_lua = selected_file_picker == myconfig.FilePicker.FZF_LUA
-- else telescope...

-- fzf
if use_fzf and fzf_vim_installed then
  myconfig.map('n', '<M-S>', ':FZF ' .. (vim.fn.has('unix') == 1 and '/' or 'C:/') .. '<CR>')
end

-- fzf-lua
if (use_fzf_lua or not use_fzf) and fzf_lua_installed then
  local root_dir = vim.fn.has('unix') == 1 and '/' or 'C:/'
  myconfig.map('n', '<M-S>', ":lua require('fzf-lua').files({ cwd = '" .. root_dir .. "' })<CR>")
end

-- Start fzf/telescope from a given environment variable
function StartFinder(env_var, additional_path)
  local path = os.getenv(env_var) or "~/"

  if additional_path then
    path = path .. "/" .. additional_path
  end
  path = myconfig.normalize_path(path)

  if use_fzf then
    -- Search using fzf.vim
    path = path:gsub(" ", '\\ ')
    vim.cmd("FZF " .. path)
  elseif use_fzf_lua then
    -- Search using fzf-lua
    local fzf_lua = require('fzf-lua')
    fzf_lua.files({ cwd = path })
  else
    -- Search using telescope
    local telescope_builtin = require('telescope.builtin')
    telescope_builtin.find_files({
      cwd = path,
      hidden = env_var == "my_notes_path",
      prompt_title = "Search in " .. path,
      previewer = true,
    })
  end
end

-- vim.api.nvim_create_user_command('RunFZFCodeRootDirWithCode', function() StartFinder("code_root_dir", "Code") end, {})
-- vim.api.nvim_set_keymap('n', '<leader>a', '<cmd>RunFZFCodeRootDirWithCode<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>a', ':lua StartFinder("code_root_dir", "Code")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>s', ':lua StartFinder("code_root_dir", "Code2")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>A', ':lua StartFinder("code_root_dir")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':lua StartFinder("my_notes_path")<CR>', { noremap = true, silent = true })

function open_files_from_list()
  local file_path = my_notes_path .. "/files.txt"
  local files = myconfig.read_lines_from_file(file_path, true)

  if use_fzf then
    -- Use fzf file picker to display file paths (edit/tabedit)
    vim.fn['fzf#run']({
      source = files,
      -- sink = function(selected)
      -- vim.cmd('edit ' .. selected)
      -- end,
      options = '--multi --prompt "Select a file to open> " --expect=ctrl-t',
      window = {
        width = 0.6,
        height = 0.6,
        border = 'rounded'
      },
      sinklist = function(selected)
        local key = selected[1]
        local file = selected[2]
        if key == "ctrl-t" then
          vim.cmd('tabedit ' .. file)
        else
          vim.cmd('edit ' .. file)
        end
      end
    })
  elseif use_fzf_lua then
    -- Use fzf-lua file picker to display file paths
    require('fzf-lua').fzf_exec(files, {
      prompt = 'Select a file: ',
      actions = {
        ['default'] = function(selected)
          vim.cmd('edit ' .. selected[1])
        end,
        ['ctrl-t'] = function(selected)
          vim.cmd('tabedit ' .. selected[1])
        end,
      }
    })
  else
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
end

vim.api.nvim_set_keymap('n', '<leader>w', ':lua open_files_from_list()<CR>', { noremap = true, silent = true })

-- List tabs with telescope
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

function list_tabs()
  local tabs = {}
  for i = 1, vim.fn.tabpagenr("$") do
    --local tabname = vim.fn.gettabvar(i, "tabname", "[No Name]")
    local bufname = vim.fn.bufname(vim.fn.tabpagebuflist(i)[1]) or "[No Buffer]"
    table.insert(tabs, string.format("%d: (%s)", i, myconfig.normalize_path(bufname)))
  end

  if use_fzf then
    -- fzf
    vim.fn["fzf#run"]({
      source = tabs,
      sink = function(selected)
        local index = tonumber(selected:match("^(%d+):"))
        if index then
          vim.cmd("tabnext " .. index)
        end
      end,
      options = "--prompt 'Tabs> ' --reverse",
    })
  elseif use_fzf_lua then
    -- fzf-lua
    local fzf = require("fzf-lua")
    fzf.fzf_exec(tabs, {
      prompt = "Tabs> ",
      actions = {
        ["default"] = function(selected)
          local index = tonumber(selected[1]:match("^(%d+):"))
          if index then
            vim.cmd("tabnext " .. index)
          end
        end,
      },
    })
  else
    -- Telescope
    pickers.new({}, {
      prompt_title = "Tabs",
      finder = finders.new_table({
        results = tabs,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
            index = tonumber(entry:match("Tab (%d+):")),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function on_select()
          local selected = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selected then
            vim.cmd("tabnext " .. selected.index)
          end
        end

        map("i", "<CR>", on_select)
        map("n", "<CR>", on_select)

        return true
      end,
    }):find()
  end
end

vim.api.nvim_set_keymap("n", "<M-s>", ":lua list_tabs()<CR>", { noremap = true, silent = true })

