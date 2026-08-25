require('dbg_log').log_file(debug.getinfo(1, 'S').source)

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

-- bind m-a: fuzzy_project_files (n)
vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua fuzzy_project_files()<CR>', { noremap = true, silent = true, desc = "Project Files (git-aware)" })
-- bind m-s-a: fuzzy_files (n)
vim.api.nvim_set_keymap('n', '<M-A>', '<cmd>lua fuzzy_files()<CR>', { noremap = true, silent = true, desc = "All Files" })

-- bind m-c-a: fuzzy search at root directory (n)
vim.keymap.set('n', '<M-C-a>', function()
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
-- bind leader-a: StartFinder code_root_dir/Code (n)
vim.api.nvim_set_keymap('n', '<leader>a', ':lua StartFinder("code_root_dir", "Code")<CR>', { noremap = true, silent = true })
-- bind leader-s: StartFinder code_root_dir/Code2 (n)
vim.api.nvim_set_keymap('n', '<leader>s', ':lua StartFinder("code_root_dir", "Code2")<CR>', { noremap = true, silent = true })
-- bind leader-s-a: StartFinder code_root_dir (n)
vim.api.nvim_set_keymap('n', '<leader>A', ':lua StartFinder("code_root_dir")<CR>', { noremap = true, silent = true })
-- bind leader-f: StartFinder my_notes_path (n)
vim.api.nvim_set_keymap('n', '<leader>f', ':lua StartFinder("my_notes_path")<CR>', { noremap = true, silent = true })

-- files.json: the shared "quick open" list, written with {env_var} placeholders so the
-- same list works on every machine. The same rules live in up.ps1, up.sh and
-- {my_notes_path}/scripts/files/files_json_common.py.
local FILES_JSON_NAME = "files.json"
local FILES_JSON_FILES_KEY = "files"
local FILES_JSON_PATH_KEY = "path"

-- Show every entry the way it is written in files.json ({my_notes_path}/some_file.txt)
-- instead of the resolved absolute path. This only changes what the picker displays,
-- opening always uses the resolved path. Set to false to list plain absolute paths.
local SHOW_PLACEHOLDER_PATHS = true

-- Every placeholder understood in files.json. Each one resolves from the environment
-- variable of the same name when it is set, and from a per platform default otherwise.
local PLACEHOLDER_NAMES = {
  "my_notes_path",
  "code_root_dir",
  "conf_dir",
  "ps_profile_path",
  "wezterm_dir",
  "local_dir",
  "downloads_dir",
  "home_dir",
}

local function is_windows()
  return vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
end

-- Trim leading/trailing whitespace, backslashes -> forward slashes, collapse repeated slashes
local function normalize_list_path(path)
  if not path or path == "" then return "" end
  path = path:gsub("^%s+", ""):gsub("%s+$", "")
  path = path:gsub("\\", "/"):gsub("//+", "/")
  return path
end

-- Drop trailing slashes so a prefix and the rest of the path always join with a single '/'
local function strip_trailing_slash(path)
  local stripped = path:gsub("/+$", "")
  if stripped == "" then return path:sub(1, 1) end
  return stripped
end

local function get_env(name)
  local value = os.getenv(name)
  if value == nil or value == "" then return nil end
  return value
end

local function get_home_dir()
  local first, second = "HOME", "USERPROFILE"
  if is_windows() then
    first, second = "USERPROFILE", "HOME"
  end
  return strip_trailing_slash(normalize_list_path(get_env(first) or get_env(second) or ""))
end

-- Defaults used when the matching environment variable is not set
local function get_placeholder_fallbacks(home)
  if is_windows() then
    return {
      conf_dir = strip_trailing_slash(normalize_list_path(get_env("LOCALAPPDATA") or (home .. "/AppData/Local"))),
      wezterm_dir = home .. "/.wezterm",
      local_dir = "C:/local",
      downloads_dir = home .. "/Downloads",
      home_dir = home,
    }
  end
  return {
    conf_dir = home .. "/.config",
    wezterm_dir = home .. "/.config/wezterm",
    local_dir = home .. "/Documents/local",
    downloads_dir = home .. "/Downloads",
    home_dir = home,
  }
end

local function get_placeholder_values()
  local fallbacks = get_placeholder_fallbacks(get_home_dir())
  local values = {}
  for _, name in ipairs(PLACEHOLDER_NAMES) do
    local raw = get_env(name) or fallbacks[name]
    if raw and raw ~= "" then
      values[name] = strip_trailing_slash(normalize_list_path(raw))
    end
  end
  return values
end

-- {placeholder} path -> absolute path. Returns nil plus the name when one cannot be resolved.
local function resolve_placeholders(path, values)
  local missing = nil
  local resolved = path:gsub("{([%a_][%w_]*)}", function(name)
    local value = values[name]
    if not value then
      missing = missing or name
      return "{" .. name .. "}"
    end
    return value
  end)
  if missing then return nil, missing end
  return normalize_list_path(resolved)
end

local function read_file_contents(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

local function decode_json(content)
  local decoded, data = pcall(vim.json.decode, content)
  if decoded then return data end
  decoded, data = pcall(vim.fn.json_decode, content)
  if decoded then return data end
  return nil
end

-- Raw entry paths from files.json
local function read_list_entries(notes_dir)
  local json_path = notes_dir .. "/" .. FILES_JSON_NAME
  local content = read_file_contents(json_path)
  if not content then
    vim.notify(FILES_JSON_NAME .. " not found in " .. notes_dir, vim.log.levels.WARN)
    return nil
  end

  local data = decode_json(content)
  if not data then
    vim.notify("Could not parse " .. json_path, vim.log.levels.ERROR)
    return nil
  end

  local entries = data[FILES_JSON_FILES_KEY] or data
  local paths = {}
  for _, entry in ipairs(entries) do
    if type(entry) == "table" then
      table.insert(paths, entry[FILES_JSON_PATH_KEY])
    elseif type(entry) == "string" then
      table.insert(paths, entry)
    end
  end
  return paths
end

-- Resolved, de-duplicated entries. Every item is { display = what the picker shows,
-- path = the absolute path to open }. Entries whose file is not on this machine are left
-- out unless include_missing is set.
local function load_file_list(include_missing)
  local notes_dir = strip_trailing_slash(normalize_list_path(my_notes_path))
  local raw_paths = read_list_entries(notes_dir)
  if not raw_paths then return {}, 0, 0 end

  local values = get_placeholder_values()
  local items, seen, missing, unresolved = {}, {}, 0, 0

  for _, raw in ipairs(raw_paths) do
    local path = normalize_list_path(raw)
    if path ~= "" and not path:match("^#") then
      local resolved = resolve_placeholders(path, values)
      if not resolved then
        unresolved = unresolved + 1
      elseif not seen[resolved:lower()] then
        seen[resolved:lower()] = true
        if include_missing or vim.loop.fs_stat(resolved) then
          table.insert(items, {
            display = SHOW_PLACEHOLDER_PATHS and path or resolved,
            path = resolved,
          })
        else
          missing = missing + 1
        end
      end
    end
  end

  return items, missing, unresolved
end

function open_files_from_list(include_missing)
  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA
  local items, missing, unresolved = load_file_list(include_missing)

  if #items == 0 then
    vim.notify("No files to open from " .. FILES_JSON_NAME, vim.log.levels.WARN)
    return
  end
  if unresolved > 0 then
    vim.notify(unresolved .. " entries use a placeholder that is not set on this machine.",
      vim.log.levels.WARN)
  end

  -- fzf and fzf-lua hand back the line they displayed, so keep a way back to the real path
  local entries, path_by_display = {}, {}
  for _, item in ipairs(items) do
    table.insert(entries, item.display)
    path_by_display[item.display] = item.path
  end

  local suffix = missing > 0 and (", " .. missing .. " not here") or ""
  local prompt_title = string.format("Select a file to open (%d%s)", #items, suffix)

  -- Takes either a displayed line or an absolute path
  local function open_file(selected, split_cmd)
    local file = path_by_display[selected] or selected
    if file and file ~= "" then
      vim.cmd(split_cmd .. " " .. vim.fn.fnameescape(file))
    end
  end

  if use_fzf then
    -- Use fzf file picker to display file paths (edit/tabedit)
    vim.fn['fzf#run']({
      source = entries,
      options = '--multi --prompt "' .. prompt_title .. '> " --expect=ctrl-t',
      window = {
        width = 0.6,
        height = 0.6,
        border = 'rounded'
      },
      sinklist = function(selected)
        if not selected or #selected == 0 then return end
        local key = selected[1]
        local split_cmd = key == "ctrl-t" and "tabedit" or "edit"
        for i = 2, #selected do
          open_file(selected[i], split_cmd)
        end
      end
    })
  elseif use_fzf_lua then
    -- Use fzf-lua file picker to display file paths
    require('fzf-lua').fzf_exec(entries, {
      prompt = prompt_title .. '> ',
      actions = {
        ['default'] = function(selected)
          for _, file in ipairs(selected or {}) do open_file(file, 'edit') end
        end,
        ['ctrl-t'] = function(selected)
          for _, file in ipairs(selected or {}) do open_file(file, 'tabedit') end
        end,
      }
    })
  else
    -- Use Telescope file picker to display file paths
    require('telescope.pickers').new({}, {
      prompt_title = prompt_title,
      finder = require('telescope.finders').new_table({
        results = items,
        entry_maker = function(item)
          return {
            value = item.path,
            display = item.display,
            ordinal = item.display,
            path = item.path,
            filename = item.path,
          }
        end,
      }),
      sorter = require('telescope.config').values.generic_sorter({}),
      attach_mappings = function(_, map)
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        local function open_selected(prompt_bufnr, split_cmd)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then open_file(selection.value, split_cmd) end
        end

        map('i', '<CR>', function(prompt_bufnr) open_selected(prompt_bufnr, 'edit') end)
        map('i', '<C-t>', function(prompt_bufnr) open_selected(prompt_bufnr, 'tabedit') end)
        map('n', '<CR>', function(prompt_bufnr) open_selected(prompt_bufnr, 'edit') end)
        map('n', '<C-t>', function(prompt_bufnr) open_selected(prompt_bufnr, 'tabedit') end)

        return true
      end,
    }):find()
  end
end

-- bind leader-w: open_files_from_list (n)
vim.api.nvim_set_keymap('n', '<leader>w', ':lua open_files_from_list()<CR>', { noremap = true, silent = true })
-- bind leader-s-w: open_files_from_list including files missing on this machine (n)
vim.api.nvim_set_keymap('n', '<leader>W', ':lua open_files_from_list(true)<CR>', { noremap = true, silent = true })

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
            index = tonumber(entry:match("^(%d+):")),
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
        map("i", "<C-t>", on_select)
        map("n", "<C-t>", on_select)

        return true
      end,
    }):find()
  end
end

-- bind m-s: list_tabs (n)
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

-- bind m-s-s: list_recent_files (n)
vim.keymap.set("n", "<M-S>", _G.list_recent_files, { noremap = true, silent = true, desc = "Recent git files" })

-- Currently changed files
local function git_changed_files(path_filters)
  local root, is_git = myconfig.get_git_root()
  if not is_git then
    vim.notify("Not a git repo here.", vim.log.levels.WARN)
    return {}, nil
  end

  path_filters = path_filters or {}

  -- Porcelain v1 is easy to parse per-line. Includes staged/unstaged + untracked
  local cmd = { "git", "-C", root, "status", "--porcelain=v1", "--untracked-files=all" }
  if #path_filters > 0 then
    table.insert(cmd, "--")
    for _, p in ipairs(path_filters) do table.insert(cmd, p) end
  end

  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("git status failed.", vim.log.levels.WARN)
    return {}, root
  end
  if #lines == 0 then
    vim.notify("No changes in working tree.", vim.log.levels.INFO)
    return {}, root
  end

  local function status_human(xy)
    local x, y = xy:sub(1,1), xy:sub(2,2)
    if xy == "??" then return "untracked" end
    if x == "A" or y == "A" then return "added" end
    if x == "D" or y == "D" then return "deleted" end
    if x == "R" or y == "R" then return "renamed" end
    if x == "C" or y == "C" then return "copied" end
    if x == "U" or y == "U" then return "unmerged" end
    if x == "M" or y == "M" then return "modified" end
    return xy
  end

  local out = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      -- Format: "XY <path>" or "R<score> <old> -> <new>" etc.
      local xy = line:sub(1,2)
      local rest = line:sub(4) -- after 'XY '

      -- Prefer the "to" path for renames/copies
      local file = rest
      if rest:find(" -> ", 1, true) then
        local _, _, to = rest:find("^(.-) %-> (.+)$")
        if to then file = to end
      end

      -- normalize whitespace
      file = (file:gsub("^%s+", ""):gsub("%s+$", ""))
      local exists = exists_at_root(root, file)
      local human = status_human(xy)

      table.insert(out, {
        file = file,
        status = xy,
        status_text = human,
        exists = exists,
      })
    end
  end

  -- Build display lines compatible with your FZF extraction regex
  for i, it in ipairs(out) do
    it.index = i
    local right = string.format("%s (%s)%s", it.status, it.status_text, it.exists and "" or " [deleted]")
    it.display = string.format("%d: %s   |   %s", i, it.file, right)
  end
  return out, root
end

local function open_diff_in_tab(root, rel)
  if not root or not rel or rel == "" then return end

  local working = root .. "/" .. rel

  -- Temp file for HEAD version
  local temp_dir = (vim.loop.os_uname().sysname == "Windows_NT")
    and "C:/local/git_changed_diff"
    or (os.getenv("HOME") .. "/.cache/nvim/git_changed_diff")
  vim.fn.mkdir(temp_dir, "p")

  local safe = rel:gsub("[/\\:%%]", "_")
  local temp_path = myconfig.normalize_path(temp_dir .. "/HEAD__" .. safe)

  local cmd
  if vim.loop.os_uname().sysname == "Windows_NT" then
    cmd = string.format('git -C "%s" show "HEAD:%s" > "%s"', root, rel:gsub("\\", "/"), temp_path)
  else
    cmd = string.format("git -C %s show %s > %s",
      vim.fn.shellescape(root),
      vim.fn.shellescape("HEAD:" .. rel),
      vim.fn.shellescape(temp_path))
  end

  vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Could not retrieve HEAD version of " .. rel, vim.log.levels.WARN)
    return
  end

  -- Open HEAD version (left) vs working file (right) in a new tab
  vim.cmd("tabnew " .. vim.fn.fnameescape(temp_path))
  vim.api.nvim_buf_set_name(0, "HEAD:" .. rel)
  vim.bo.buftype  = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.cmd("diffthis")
  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(working))
end

-- Picker entrypoint for changed files
function _G.list_changed_files()
  local items, root = git_changed_files({})
  if not items or #items == 0 then return end

  local function open_abs(abs, open_cmd)
    if vim.loop.fs_stat(abs) then
      vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(abs))
    else
      vim.notify("Cannot open '" .. abs .. "': file no longer exists on disk.", vim.log.levels.WARN)
    end
  end

  local use_fzf = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA

  if use_fzf then
    local src = {}
    for _, it in ipairs(items) do table.insert(src, it.display) end

    vim.fn["fzf#run"]({
      source = src,
      options = "--prompt 'Changed> ' --reverse --multi --expect=ctrl-t,ctrl-d",
      sinklist = function(selected)
        if not selected or #selected == 0 then return end
        local key = selected[1]
        for i = 2, #selected do
          local rel = selected[i]:match("^%d+:%s+(.-)%s+|%s+")
          if rel and rel ~= "" then
            local abs = root .. "/" .. rel
            if key == "ctrl-t" then
              open_abs(abs, "tabedit")
            elseif key == "ctrl-d" then
              open_diff_in_tab(root, rel)
            else
              open_abs(abs, "edit")
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
      prompt = "Changed> ",
      actions = {
        ["default"] = function(sel)
          if not sel then return end
          for _, line in ipairs(sel) do
            local rel = line:match("^%d+:%s+(.-)%s+|%s+")
            if rel and rel ~= "" then
              open_abs(root .. "/" .. rel, "edit")
            end
          end
        end,
        ["ctrl-t"] = function(sel)
          if not sel then return end
          for _, line in ipairs(sel) do
            local rel = line:match("^%d+:%s+(.-)%s+|%s+")
            if rel and rel ~= "" then
              open_abs(root .. "/" .. rel, "tabedit")
            end
          end
        end,
        ["ctrl-d"] = function(sel)
          if not sel then return end
          for _, line in ipairs(sel) do
            local rel = line:match("^%d+:%s+(.-)%s+|%s+")
            if rel and rel ~= "" then
              open_diff_in_tab(root, rel)
            end
          end
        end,
      },
    })

  else
    -- Telescope
    pickers.new({}, {
      prompt_title = "Changed Git Files",
      finder = finders.new_table({
        results = items,
        entry_maker = function(it)
          local abs = root .. "/" .. it.file
          return {
            value    = it.file,
            display  = it.display,
            ordinal  = it.display,
            path     = abs,
            filename = abs,
            exists   = it.exists,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function open_with(cmd)
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not entry or not entry.path then return end
          if vim.loop.fs_stat(entry.path) then
            vim.cmd(cmd .. " " .. vim.fn.fnameescape(entry.path))
          else
            vim.notify("Cannot open '" .. entry.path .. "': file no longer exists on disk.", vim.log.levels.WARN)
          end
        end
        local function diff_tab()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not entry then return end
          open_diff_in_tab(root, entry.value)   -- entry.value is the repo-relative path
        end
        map("i", "<CR>", function() open_with("edit") end); map("n", "<CR>", function() open_with("edit") end)
        map("i", "<C-t>", function() open_with("tabedit") end); map("n", "<C-t>", function() open_with("tabedit") end)
        map("i", "<C-d>", diff_tab); map("n", "<C-d>", diff_tab)
        return true
      end,
    }):find()
  end
end

-- bind m-c-s: list_changed_files (n)
vim.keymap.set("n", "<M-C-s>", _G.list_changed_files, { noremap = true, silent = true, desc = "Changed git files" })

