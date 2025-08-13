local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path

local utils = require('telescope.utils')
local builtin = require('telescope.builtin')

function ts_project_files()
  local _, ret, _ = utils.get_os_command_output({ 'git', 'rev-parse', '--is-inside-work-tree' })
  if ret == 0 then
    --builtin.git_files()
    builtin.git_files({
      cwd = utils.buffer_dir(),
      previewer = true,
    })
  else
    --builtin.find_files()
    builtin.find_files({
      cwd = utils.buffer_dir(),
      previewer = true,
    })
  end
end

--if myconfig.get_file_picker() == myconfig.FilePicker.TELESCOPE then
--  vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua ts_project_files()<CR>', { noremap = true, silent = true })
--end

--function ts_project_files_opts(opts)
--  opts = opts or {}
--  local _, ret, _ = utils.get_os_command_output({ 'git', 'rev-parse', '--is-inside-work-tree' })
--  if ret == 0 then
--    builtin.git_files(opts)
--  else
--    builtin.find_files(opts)
--  end
--end
--if myconfig.get_file_picker() == myconfig.FilePicker.TELESCOPE then
--  vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua ts_project_files_opts({ hidden = true })<CR>', { noremap = true, silent = true })
--end

-- Make sure you have ripgrep installed!

--if myconfig.get_file_picker() == myconfig.FilePicker.TELESCOPE then
--  --vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>Telescope git_files<CR>', { noremap = true, silent = true })
--  vim.api.nvim_set_keymap('n', '<M-A>', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })
--end

function fuzzy_project_files()
  local git_root, is_git = myconfig.get_git_root()
  local cwd = is_git and git_root or vim.fn.getcwd()
  local file_picker = myconfig.get_file_picker()

  if file_picker == myconfig.FilePicker.FZF then
    cwd = cwd:gsub(" ", '\\ ')
    vim.cmd("FZF " .. cwd)
  elseif file_picker == myconfig.FilePicker.FZF_LUA then
    if is_git then
      require("fzf-lua").git_files({ cwd = cwd })
    else
      require("fzf-lua").files({})
    end
  else
    ts_project_files()
  end
end

function fuzzy_files()
  local file_picker = myconfig.get_file_picker()

  if file_picker == myconfig.FilePicker.FZF then
    vim.cmd('FZF')
  elseif file_picker == myconfig.FilePicker.FZF_LUA then
    require("fzf-lua").files({})
  else
    --vim.cmd("Telescope find_files")
    require('telescope.builtin').find_files({ cwd = utils.buffer_dir() })
  end
end

vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua fuzzy_project_files()<CR>', { noremap = true, silent = true, desc = "Project Files (git-aware)" })
vim.api.nvim_set_keymap('n', '<M-A>', '<cmd>lua fuzzy_files()<CR>', { noremap = true, silent = true, desc = "All Files" })

-- fuzzy search at '/' or 'C:/'
vim.keymap.set('n', '<M-C-s>', function()
  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA
  local root_dir = (vim.fn.has('unix') == 1) and '/' or 'C:/'

  if use_fzf then
    vim.cmd("FZF " ..root_dir)
  elseif use_fzf_lua then
    require("fzf-lua").files({ cwd = root_dir })
  else
    -- Search using telescope
    local telescope_builtin = require('telescope.builtin')
    telescope_builtin.find_files({
      cwd = root_dir,
      hidden = false,
      prompt_title = "Search in " .. root_dir,
      previewer = true,
    })
  end
end, { noremap = true, silent = true })

-- Start fzf/telescope from a given environment variable
function StartFinder(env_var, additional_path)
  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA
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
  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA
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
  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA

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

local function norm_date(iso)
  return (iso:gsub("T", " "):gsub("%+.*$", ""))
end

local function exists_at_root(root, rel)
  return rel and rel ~= "" and root and vim.loop.fs_stat(root .. "/" .. rel) ~= nil
end

-- Build recent files via git log
local function git_recent_files(max_commits, max_files, path_filters)
  local root, is_git = myconfig.get_git_root()
  if not is_git then
    vim.notify("Not a git repo here.", vim.log.levels.WARN)
    return {}, nil
  end

  max_commits = max_commits or 100
  max_files = max_files   or 30
  path_filters = path_filters or {}

  -- Run git at the repo root to ensure consistent paths
  local cmd = { "git", "-C", root, "log", "-n", tostring(max_commits),
                "--name-status", "--date=iso-strict", "--pretty=format:@@@%ad" }
  if #path_filters > 0 then
    table.insert(cmd, "--")
    for _, p in ipairs(path_filters) do table.insert(cmd, p) end
  end

  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("git log failed or returned no lines.", vim.log.levels.WARN)
    return {}, root
  end

  local seen, out, current_date = {}, {}, ""
  for _, line in ipairs(lines) do
    if line:sub(1,3) == "@@@" then
      current_date = line:sub(4)
    elseif not line:match("^%s*$") then
      local parts = vim.split(line, "\t", { plain = true })
      if #parts >= 2 then
        local status = parts[1]
        local file = (status:sub(1,1) == "R" and #parts >= 3) and parts[3] or parts[2]
        if not seen[file] and exists_at_root(root, file) then
          seen[file] = true
          table.insert(out, { date = current_date, file = file })
          if #out >= max_files then break end
        end
      end
    end
  end

  table.sort(out, function(a, b) return a.date > b.date end) -- newest first
  for i, it in ipairs(out) do
    it.index = i
    it.date_disp = norm_date(it.date)
    it.display = string.format("%d: %s   |   %s", i, it.file, it.date_disp)
  end
  return out, root
end

-- Picker entrypoint
function _G.list_recent_files()
  local items, root = git_recent_files(100, 30, {})
  if not items or #items == 0 then return end

  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA

  if use_fzf then
    local src = {}
    for _, it in ipairs(items) do table.insert(src, it.display) end

    vim.fn["fzf#run"]({
      source = src,
      -- capture ctrl-t; support multi-select
      options = "--prompt 'Recent> ' --reverse --multi --expect=ctrl-t",
      sinklist = function(selected)
        if not selected or #selected == 0 then return end
        local key = selected[1]
        for i = 2, #selected do
          local rel = selected[i]:match("^%d+:%s+(.-)%s+|%s+")
          if rel and rel ~= "" then
            if key == "ctrl-t" then
              vim.cmd("tabedit " .. vim.fn.fnameescape(root .. "/" .. rel))
            else
              vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. rel))
            end
          end
        end
      end,
    })
  elseif use_fzf_lua then
    local fzf = require("fzf-lua")
    local src = {}
    for _, it in ipairs(items) do table.insert(src, it.display) end

    fzf.fzf_exec(src, {
      prompt = "Recent> ",
      actions = {
        -- Enter
        ["default"] = function(sel)
          if not sel then return end
          for _, line in ipairs(sel) do
            local rel = line:match("^%d+:%s+(.-)%s+|%s+")
            if rel and rel ~= "" then
              vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. rel))
            end
          end
        end,
        -- Ctrl-t
        ["ctrl-t"] = function(sel)
          if not sel then return end
          for _, line in ipairs(sel) do
            local rel = line:match("^%d+:%s+(.-)%s+|%s+")
            if rel and rel ~= "" then
              vim.cmd("tabedit " .. vim.fn.fnameescape(root .. "/" .. rel))
            end
          end
        end,
      },
    })
  else
    pickers.new({}, {
      prompt_title = "Recent Git Files",
      finder = finders.new_table({
        results = items,
        entry_maker = function(it)
          local abs = root .. "/" .. it.file -- absolute path for telescope actions
          return {
            value    = it.file, -- repo-relative (for display/logic)
            display  = it.display,
            ordinal  = it.display,
            path     = abs, -- critical: used by open/preview
            filename = abs, -- some providers check this
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function open_edit()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.path then
            vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
          end
        end
        local function open_tab()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.path then
            vim.cmd("tabedit " .. vim.fn.fnameescape(entry.path))
          end
        end

        -- Enter = edit
        map("i", "<CR>", open_edit); map("n", "<CR>", open_edit)
        -- Ctrl-t = tabedit (works even if you later remove these,
        -- since 'path' is absolute, Telescope's default <C-t> will work)
        map("i", "<C-t>", open_tab); map("n", "<C-t>", open_tab)
        return true
      end,
    }):find()
  end
end

vim.keymap.set("n", "<M-S>", _G.list_recent_files, { noremap = true, silent = true, desc = "Recent git files" })

