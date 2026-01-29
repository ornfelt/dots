local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path
local code_root_dir = myconfig.code_root_dir
local ps_profile_path = myconfig.ps_profile_path

-- myconfig.map('n', '<leader>wp', ':s,\\\\,/,g<CR>') -- Normalize path
function NormalizePath()
  vim.cmd('normal! 0')
  vim.cmd('silent! s,\\\\,/,g')
  vim.cmd('silent! s,/\\+,/,g')
  vim.cmd('silent! noh')
end
-- bind leader-wp: NormalizePath (n)
vim.api.nvim_set_keymap('n', '<leader>wp', ':lua NormalizePath()<CR>', { noremap = true, silent = true })

function ReplacePathBasedOnContext()
  if not my_notes_path or not code_root_dir then
    print("Environment variables 'my_notes_path' or 'code_root_dir' are not set.")
    return
  end

  local line = vim.fn.getline(".")
  local is_windows = vim.loop.os_uname().sysname:lower():find("windows") ~= nil
  local home_directory = os.getenv("HOME")

  if myconfig.should_debug_print() then
    print("input line: " .. line)
    print("my_notes_path: " .. my_notes_path)
    print("code_root_dir: " .. code_root_dir)
    print("ps_profile_path: " .. ps_profile_path)
    print("conf_dir: " .. myconfig.get_conf_dir())
    print("home_directory: " .. (home_directory or "nil"))
  end

  -- vim.pesc will escape the string for use in Vim regular expressions
  -- It adds necessary backslashes to special chars etc.
  if line:find("{my_notes_path}/", 1, true) or line:find("{code_root_dir}/", 1, true) or line:find("{conf_dir}/", 1, true) then
    line = line:gsub("{my_notes_path}", vim.pesc(my_notes_path))
    line = line:gsub("{code_root_dir}", vim.pesc(code_root_dir))
    line = line:gsub("{conf_dir}", vim.pesc(myconfig.get_conf_dir()))
  else
    line = line:gsub(vim.pesc(my_notes_path), "{my_notes_path}/")
    --line = line:gsub(vim.pesc(code_root_dir), "{code_root_dir}/")
    line = line:gsub(vim.pesc(code_root_dir) .. "(/?Code)", "{code_root_dir}/%1")
    line = line:gsub(vim.pesc(myconfig.get_conf_dir()), "{conf_dir}/")
  end

  if ps_profile_path then
    if line:find("{ps_profile_path}/", 1, true) then
      line = line:gsub("{ps_profile_path}", vim.pesc(ps_profile_path))
    else
      line = line:gsub(vim.pesc(ps_profile_path), "{ps_profile_path}/")
    end
  end

  -- HOME replacement handling for unix
  -- Keep track of home replacement since we don't want to translate
  -- /home/jonas -> $HOME and then translate back later...
  local home_replaced = false
  if not is_windows and home_directory then
    if line:find(home_directory, 1, true) then
      line = line:gsub(vim.pesc(home_directory), "$HOME")
      home_replaced = true
    else
      line = line:gsub("%$HOME", home_directory)
    end
  end

  -- Generalized Unix-like environment variables replacement
  line = line:gsub('%$([%w_]+)', function(env_var_name)
    if env_var_name == "HOME" and home_replaced then
      return "$" .. env_var_name
    end
    local env_var_value = os.getenv(env_var_name)
    if env_var_value then
      return vim.pesc(env_var_value)
    else
      return "$" .. env_var_name -- Leave as is if not found
    end
  end)

  -- Handle potential Windows environment paths like $env:variable_name
  if is_windows then
    line = line:gsub('%$env:([%w_]+)', function(env_var_name)
      local env_var_value = os.getenv(env_var_name)
      if env_var_value then
        return vim.pesc(env_var_value)
      else
        return "$env:" .. env_var_name -- Leave as is if not found
      end
    end)
  end

  line = myconfig.normalize_path(line) -- Just to replace any consecutive slashes again...
  -- Update line in buffer
  vim.fn.setline(".", line)
end

-- bind leader-wo: ReplacePathBasedOnContext (n)
vim.api.nvim_set_keymap('n', '<leader>wo', ':lua ReplacePathBasedOnContext()<CR>', { noremap = true, silent = true })

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

local function remove_file_name(path)
  -- Use a pattern to find the last `/`, including everything up to it but not beyond
  local directory_path = path:match("(.*/)")
  if directory_path then
    return directory_path
  else
    return path -- In case there's no slash found
  end
end

function copy_current_file_path_old(replace_env)
  local path = get_current_file_path()
  if path == "" then
    print("No file in current buffer")
    return
  end

  path = myconfig.normalize_path(path)
  path = path:gsub("oil:", "")

  if replace_env then
    -- Replace "my_notes_path"
    if my_notes_path then
      if my_notes_path:sub(-1) == "/" then
        my_notes_path = my_notes_path:sub(1, -2)
      end

      local pattern = "^" .. vim.pesc(my_notes_path)
      path = path:gsub(pattern, "{my_notes_path}")
    end

    -- Replace "ps_profile_path"
    if ps_profile_path then
      if ps_profile_path:sub(-1) == "/" then
        ps_profile_path = ps_profile_path:sub(1, -2)
      end

      local pattern = "^" .. vim.pesc(ps_profile_path)
      path = path:gsub(pattern, "{ps_profile_path}")
    end

    -- Replace "code_root_dir"
    if code_root_dir then
      if code_root_dir:sub(-1) == "/" then
        code_root_dir = code_root_dir:sub(1, -2)
      end

      --local pattern = "^" .. vim.pesc(code_root_dir)
      --path = path:gsub(pattern, "{code_root_dir}")
      local pattern = "^" .. vim.pesc(code_root_dir .. "/Code")
      path = path:gsub(pattern, "{code_root_dir}/Code")
    end
  else
    path = remove_file_name(path)
  end

  vim.fn.setreg('+', path)
  print("Copied to clipboard: " .. path)
end

local function replace_env(path, env, placeholder)
  if env then
    -- Remove trailing slash, if any.
    if env:sub(-1) == "/" then
      env = env:sub(1, -2)
    end

    -- Convert both strings to lowercase for a case-insensitive comparison.
    local lower_path = path:lower()
    local lower_env = env:lower()

    -- Create the pattern for matching from the start.
    local env_pattern = "^" .. vim.pesc(lower_env)

    -- If a match is found, replace the matched portion with the placeholder.
    if lower_path:find(env_pattern) then
      local env_len = #env  -- length remains the same since case doesn't affect length.
      return placeholder .. path:sub(env_len + 1)
    end
  end
  return path
end

function copy_current_file_path(replace_env_vars)
  local path = get_current_file_path()
  if path == "" then
    print("No file in current buffer")
    return
  end

  path = myconfig.normalize_path(path)
  path = path:gsub("oil:", "")
  path = path:gsub("c:", "C:")

  if replace_env_vars then
    path = replace_env(path, ps_profile_path, "{ps_profile_path}")
    path = replace_env(path, my_notes_path, "{my_notes_path}")

    if code_root_dir then
      local code_env = code_root_dir
      if code_env:sub(-1) == "/" then
        code_env = code_env:sub(1, -2)
      end
      local code_prefix = code_env .. "/Code"
      path = replace_env(path, code_prefix, "{code_root_dir}/Code")
    end

    path = path:gsub(vim.pesc(myconfig.get_conf_dir()), "{conf_dir}/")

  else
    path = remove_file_name(path)
  end

  path = myconfig.normalize_path(path)

  vim.fn.setreg('+', path)
  print("Copied to clipboard: " .. path)
end

-- bind leader--: copy file path with env vars replaced (n)
vim.api.nvim_set_keymap('n', '<leader>-', ':lua copy_current_file_path(true)<CR>', { noremap = true, silent = true })
-- bind leader--: copy directory path (v)
vim.api.nvim_set_keymap('v', '<leader>-', ':lua copy_current_file_path(false)<CR>', { noremap = true, silent = true })

-- keybind for vscode-like copying of active file path
-- Note: Alternative path formats:
--vim.fn.expand('%:~') -- Relative to home: ~/test/file.txt
--vim.fn.expand('%:.') -- Relative to cwd: test/file.txt
--vim.fn.expand('%:t') -- Just filename: file.txt
-- alt-shift-c conflicts with wezterm copy...
--vim.keymap.set('n', '<M-C>', function()
-- bind m-c-c: copy full file path to clipboard (n)
vim.keymap.set('n', '<M-c-c>', function()
    local path = vim.fn.expand('%:p') -- full path
    if path == '' then
        print('Buffer has no file path')
        return
    end

    vim.fn.setreg('+', path) -- clipboard register
    --vim.fn.setreg('*', path) -- primary register (x11 only)
    print('Copied: ' .. path)
end, { desc = 'Copy current file path to clipboard' })

-- lua print(vim.fn.expand("<cWORD>"))
function open_file_with_env()
  -- local cword = vim.fn.expand("<cfile>")
  local cword = vim.fn.expand("<cWORD>")

  local use_debug_print = myconfig.should_debug_print()

  if use_debug_print then
    print("original cword: " .. cword)
  end

  -- Removes everything before drive letter (may appear in diff files)
  local trimmed_cword = cword:match("([a-zA-Z]:.*)")
  if trimmed_cword ~= nil then
    cword = trimmed_cword
  end

  cword = cword:gsub("#", "\\#")
  if use_debug_print then
    print("cword after drive trim and '#' fix: " .. cword)
  end

  cword = myconfig.normalize_path(cword)
  if use_debug_print then
    print("cword after normalize_path: " .. cword)
  end

  -- Remove some characters: ', ", parenthesis and brackets
  cword = cword:gsub("[\'\"(),%[%] ]", "")

  if cword:match("^a/") or cword:match("^b/") then
    --local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
    local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
    if git_root == "" then
      print("Current file is not in a Git repository.")
      return
    end

    -- Replace 'a/' or 'b/' with git root dir
    cword = cword:gsub("^[ab]/", git_root .. "/")
  end

  if cword:find("{") then
    local new_cword = cword:gsub("{(.-)}", function(var)
      if var == "conf_dir" then
        return myconfig.get_conf_dir()
      end
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

    if use_debug_print then
      print("new_cword (from placeholder): " .. new_cword)
    end

    -- vim.cmd("edit " .. new_cword)
    vim.cmd("tabe " .. new_cword)

  -- Match colon followed by word that's not '/', like $env:code_root_dir
  elseif cword:match(":[^/]+/") then
    -- Strip everything before colon
    local colon_index = cword:find(":[^/]+/")
    if not colon_index then
      print("Could not find env-style path after colon.")
      return
    end

    -- Trim everything before colon
    local trimmed = cword:sub(colon_index)

    -- Extract env var and path tail
    local varname, path_after = trimmed:match(":([^/]+)/(.*)")
    if not varname or not path_after then
      print("Invalid env-style path format.")
      return
    end

    local env_value = os.getenv(varname)
    if not env_value then
      print("Environment variable " .. varname .. " not found.")
      return
    end

    local new_cword = env_value .. "/" .. path_after
    new_cword = myconfig.normalize_path(new_cword)

    if use_debug_print then
      print("new_cword (from :var): " .. new_cword)
    end

    vim.cmd("tabe " .. new_cword)

  else
    -- vim.cmd("edit " .. cword)
    vim.cmd("tabe " .. cword)
  end
end

-- bind gf: open_file_with_env (n)
vim.api.nvim_set_keymap('n', 'gf', ':lua open_file_with_env()<CR>', { noremap = true, silent = true })

function open_in_firefox()
  local cword = vim.fn.expand("<cWORD>")
  if cword:find("http") or cword:find(":") then
    vim.fn.system("firefox " .. vim.fn.shellescape(cword) .. " &")
  else
    -- cword = cword:gsub('"', ''):gsub(',', ''):gsub("'", '')
    cword = cword:match([["(.-)"]]) or cword:match([['(.-)']]) or cword
    local url = "https://github.com/" .. cword

    if cword:lower():find("github.com") then
      -- Capture up to two slashes after github.com
      local match = cword:match("^(.-/[^/]+/[^/]+)")
      url = match or cword
    end

    vim.fn.system("firefox " .. vim.fn.shellescape(url) .. " &")
  end
end

-- vim.api.nvim_set_keymap('n', 'gx', ':!open <cWORD><CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'gx', ':!nohup firefox <cWORD> &<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'gx', ':!firefox <cWORD> &<CR>', { noremap = true, silent = true })
-- bind gx: open_in_firefox (n)
vim.api.nvim_set_keymap('n', 'gx', ':lua open_in_firefox()<CR>', { noremap = true, silent = true })

