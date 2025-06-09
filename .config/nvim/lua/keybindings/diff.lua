local myconfig = require("myconfig")

local my_notes_path = myconfig.my_notes_path
local code_root_dir = myconfig.code_root_dir
local ps_profile_path = myconfig.ps_profile_path

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

  local target_dir
  if vim.loop.os_uname().sysname == "Windows_NT" then
    target_dir = "C:/local/testing_files"
  else
    target_dir = os.getenv("HOME") .. "/Documents/local/testing_files"
  end

  vim.fn.mkdir(target_dir, "p")

  local target1 = target_dir .. "/test1.txt"
  local target2 = target_dir .. "/test2.txt"

  vim.cmd(string.format("silent !cp %s %s", vim.fn.shellescape(file_paths[1]), vim.fn.shellescape(target1)))
  vim.cmd(string.format("silent !cp %s %s", vim.fn.shellescape(file_paths[2]), vim.fn.shellescape(target2)))

  print("Files copied to " .. target_dir)
end

local function diff_current_lines()
  local line_number = vim.fn.line('.')
  local current_line = vim.fn.getline(line_number)
  local next_line = vim.fn.getline(line_number + 1)
  local third_line = vim.fn.getline(line_number + 2)
  local combined_lines = current_line .. "\n" .. next_line .. "\n" .. third_line

  local file_paths = {}
  local unique_paths = {}

  for prefix, path in combined_lines:gmatch('([ab])/([^\n%s]+)') do
    local full_path = path
    if vim.loop.os_uname().sysname == "Windows_NT" then
      full_path = full_path:gsub("/", "\\")
    else
      if not full_path:match("^/") then
        full_path = "/" .. full_path -- Add '/' prefix for Linux paths
      end
    end

    if not unique_paths[full_path] then
      table.insert(file_paths, full_path)
      unique_paths[full_path] = true
    end

    if #file_paths >= 2 then
      break
    end
  end

  if myconfig.should_debug_print() then
    print("File paths read:")
    for i, file_path in ipairs(file_paths) do
      print(string.format("File %d: %s", i, file_path))
    end
  end

  if #file_paths < 2 then
    print("Not enough file paths found for diff.")
    return
  end

  for i, file_path in ipairs(file_paths) do
    local trimmed_fp = file_path:match("([a-zA-Z]:.*)")
    if trimmed_fp ~= nil then
      trimmed_fp = trimmed_fp:gsub("#", "\\#")
      file_paths[i] = trimmed_fp
    end
  end

  vim.cmd(string.format("edit %s", file_paths[1]))
  vim.cmd("diffthis")
  vim.cmd(string.format("vert diffsplit %s", file_paths[2]))
end

local function get_default_branch()
  local use_debug_print = myconfig.should_debug_print()
  if vim.loop.os_uname().sysname == "Windows_NT" then
    -- Test in ps:
    -- (git remote show upstream | Select-String -Pattern 'HEAD branch' | ForEach-Object { $_.Line }) -replace '^.*HEAD branch: ', ''
    local cmd = [[powershell -NoProfile -Command "(git remote show upstream | Select-String -Pattern 'HEAD branch' | ForEach-Object { $_.Line }) -replace '^.*HEAD branch: ', ''''"]]
    if use_debug_print then
      print("[get_default_branch] cmd: " .. cmd)
    end

    local output = vim.fn.system(cmd):gsub("\n", "")
    if output and use_debug_print then
      print("[get_default_branch] output: " .. output)
    end

    if vim.v.shell_error ~= 0 or output == "" then
      return ""
    end

    if output:lower():find("fatal:") then
      return ""
    end

    -- Extract last word (branch name)
    local branch_name = output:match("%S+$") or ""
    -- Remove any quotes or single quotes (')
    branch_name = branch_name:gsub("[\"']", "")

    return "upstream/" .. branch_name
  else
    local cmd = "git remote show upstream | grep 'HEAD branch' | awk '{print $NF}'"
    local output = vim.fn.system(cmd):gsub("\n", "")
    if vim.v.shell_error ~= 0 or output == "" or output:find("does not appear to be a git repo") then
      return ""
    end
    return "upstream/" .. output
  end
end

local function get_branches_sorted()
  local use_debug_print = myconfig.should_debug_print()
  local cmd = "git branch --sort=-committerdate -v"

  if use_debug_print then
    print("[get_branches_sorted] cmd: " .. cmd)
  end

  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    if use_debug_print then
      print("[get_branches_sorted] Error getting branches")
    end
    return {}
  end

  -- Get current branch name
  local current_branch_cmd = "git branch --show-current"
  local current_branch = vim.fn.system(current_branch_cmd):gsub("\n", "")
  if use_debug_print then
    print("[get_branches_sorted] Current branch: " .. current_branch)
  end

  local branches = {}
  local found_master = false
  local found_main = false

  for line in output:gmatch("[^\r\n]+") do
    -- Check if this is the current branch (marked with *)
    local is_current = line:match("^%s*%*")

    -- Remove leading spaces and asterisk (current branch marker)
    local branch_info = line:gsub("^%s*%*?%s*", "")
    if branch_info ~= "" then
      -- Extract just the branch name (first word)
      local branch_name = branch_info:match("^(%S+)")
      if branch_name then
        -- Skip current branch
        if not is_current and branch_name ~= current_branch then
          -- Track if we found master or main
          if branch_name == "master" then
            found_master = true
          elseif branch_name == "main" then
            found_main = true
          end

          table.insert(branches, branch_name)
        end
      end
    end
  end

  -- Add origin versions for master and main if they were found
  if found_master then
    table.insert(branches, "origin/master")
  end

  if found_main then
    table.insert(branches, "origin/main")
  end

  if use_debug_print then
    print("[get_branches_sorted] Found branches (excluding current): " .. vim.inspect(branches))
    if found_master then
      print("[get_branches_sorted] Added origin/master")
    end
    if found_main then
      print("[get_branches_sorted] Added origin/main")
    end
  end

  return branches
end

local function select_branch(callback)
  local use_debug_print = myconfig.should_debug_print()

  -- Get any existing upstream branch
  local default_branch = get_default_branch()

  -- Get all branches sorted by commit date
  local branches = get_branches_sorted()

  if #branches == 0 and not default_branch then
    print("No branches found.")
    if callback then callback("") end
    return
  end

  -- Create options list
  local options = {}
  local labels = {}
  local has_upstream = default_branch ~= ""

  -- Add upstream branch as first option if it exists
  if has_upstream then
    table.insert(options, default_branch)
    table.insert(labels, "[upstream] " .. default_branch)
  end

  -- Add other branches, avoiding duplicates
  for _, branch in ipairs(branches) do
    local should_add = true

    -- Skip if it's the same as upstream branch (without upstream/ prefix)
    --if has_upstream then
    --  local upstream_branch_name = default_branch:match("upstream/(.+)")
    --  if upstream_branch_name and branch == upstream_branch_name then
    --    should_add = false
    --  end
    --end

    if should_add then
      table.insert(options, branch)
      table.insert(labels, branch)
    end
  end

  if use_debug_print then
    print("[select_branch] Options: " .. vim.inspect(options))
    print("[select_branch] Labels: " .. vim.inspect(labels))
  end

  local function run_selection(selected_label)
    if use_debug_print then
      print("[select_branch] Selected label: " .. selected_label)
    end

    -- Find the corresponding branch name
    local selected_branch = ""
    for i, label in ipairs(labels) do
      if label == selected_label then
        selected_branch = options[i]
        break
      end
    end

    if use_debug_print then
      print("[select_branch] Selected branch: " .. selected_branch)
    end

    if callback then
      callback(selected_branch)
    end
  end

  -- Use fzf/telescope or vim.ui.select fallback
  local picker = myconfig.get_file_picker()
  local use_fzf = picker == myconfig.FilePicker.FZF
  local use_fzf_lua = picker == myconfig.FilePicker.FZF_LUA
  local use_file_picker = myconfig.use_file_picker_for_commands()

  if use_file_picker then
    -- fzf
    if use_fzf then
      vim.fn["fzf#run"]({
        source  = labels,
        sink    = run_selection,
        options = "--prompt 'Branch> ' --reverse",
      })
    -- fzf-lua
    elseif use_fzf_lua then
      require("fzf-lua").fzf_exec(labels, {
        prompt  = "Branch> ",
        actions = {
          ["default"] = function(selected)
            run_selection(selected[1])
          end,
        },
      })
    else
      -- telescope
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values

      -- Create entries for telescope
      local entries = {}
      for i, label in ipairs(labels) do
        table.insert(entries, {
          branch = options[i],
          label = label,
        })
      end

      pickers.new({}, {
        prompt_title = "Choose Branch",
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            return {
              value   = entry.branch,
              display = entry.label,
              ordinal = entry.label,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            run_selection(sel.display)
          end)
          return true
        end,
      }):find()
    end
  else
    -- vim.ui.select fallback
    vim.ui.select(labels, { prompt = "Choose Branch:" }, function(choice)
      if choice then
        run_selection(choice)
      elseif callback then
        callback("")
      end
    end)
  end
end

function continue_diff_process(current_file, relative_path, branch_name, use_debug_print)
  local target_dir = vim.loop.os_uname().sysname == "Windows_NT"
      and "C:/local/testing_files"
      or os.getenv("HOME") .. "/Documents/local/testing_files"
  vim.fn.mkdir(target_dir, "p")

  local target_file1 = target_dir .. "/test1.txt"
  local target_file2 = target_dir .. "/test2.txt"

  local copy_command = string.format("cp %s %s", vim.fn.shellescape(current_file), vim.fn.shellescape(target_file1))
  vim.fn.system(copy_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to copy the current file to: " .. target_file1)
    return
  end

  local checkout_command = string.format("git show %s:%s > %s", branch_name, relative_path, target_file2)
  checkout_command = checkout_command:gsub("\\", "/"):gsub("//+", "/")

  if use_debug_print then
    print("checkout_command: " .. checkout_command)
  end

  vim.fn.system(checkout_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to checkout file from branch: " .. branch_name)
    return
  end

  if use_debug_print then
    print("File checked out to: " .. target_file2)
  end

  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(target_file2))
end

local function diffg_command()
  local current_file = vim.fn.expand('%:p')
  if current_file == "" then
    print("No file is currently open.")
    return
  end

  --local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
  if git_root == "" then
    print("Current file is not in a Git repository.")
    return
  end

  local use_debug_print = myconfig.should_debug_print()
  if use_debug_print then
    print("git_root: " .. git_root)
  end

  -- Remove git_root and the trailing '/'
  -- (this worked with commented git_root code above on linux)
  --local relative_path = current_file:sub(#git_root + 2)

  local relative_path = current_file:sub(#git_root)
  relative_path = relative_path:gsub("^[/\\]+", "") -- Remove leading slashes
  if use_debug_print then
    print("relative_path: " .. relative_path)
  end

  select_branch(function(branch_name)
    if branch_name == "" then
      if use_debug_print then
        print("No branch selected.")
      end
      return
    end

    continue_diff_process(current_file, relative_path, branch_name, use_debug_print)
  end)
end

-- Same as diffg but enter branch name via free text
local function diffgf_command()
  local current_file = vim.fn.expand('%:p')
  if current_file == "" then
    print("No file is currently open.")
    return
  end

  --local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  local git_root = vim.fn.system('git -C "' .. vim.fn.getcwd() .. '" rev-parse --show-toplevel')
  if git_root == "" then
    print("Current file is not in a Git repository.")
    return
  end

  local use_debug_print = myconfig.should_debug_print()
  if use_debug_print then
    print("git_root: " .. git_root)
  end

  -- Remove git_root and the trailing '/'
  -- (this worked with commented git_root code above on linux)
  --local relative_path = current_file:sub(#git_root + 2)

  local relative_path = current_file:sub(#git_root)
  relative_path = relative_path:gsub("^[/\\]+", "") -- Remove leading slashes
  if use_debug_print then
    print("relative_path: " .. relative_path)
  end

  --local default_branch = "upstream/npcbots_3.3.5"
  local default_branch = get_default_branch()
  local branch_name = vim.fn.input("Enter the Git branch name: ", default_branch)
  if branch_name == "" then
    if use_debug_print then
      print("Branch name cannot be empty.")
    end
    return
  end

  -- Comment for now since I sometimes want to diff upstream branch
  --local _ = vim.fn.system("git show-ref --verify --quiet refs/heads/" .. branch_name)
  --if vim.v.shell_error ~= 0 then
  --  print("Branch does not exist: " .. branch_name)
  --  return
  --end

    continue_diff_process(current_file, relative_path, branch_name, use_debug_print)
end

local function replace_env_paths(file_path)
  if file_path:find("{my_notes_path}/", 1, true) or file_path:find("{code_root_dir}/", 1, true) or file_path:find("{ps_profile_path}/", 1, true) then
    file_path = file_path:gsub("{my_notes_path}/", vim.pesc(my_notes_path))
    file_path = file_path:gsub("{code_root_dir}/", vim.pesc(code_root_dir))
    file_path = file_path:gsub("{ps_profile_path}/", vim.pesc(ps_profile_path))
    file_path = myconfig.normalize_path(file_path)
  end
  return file_path
end

local function clean_selected_path(cwd, selected_path)
  selected_path = selected_path:match("[A-Za-z].*$") or selected_path
  if not selected_path:match("^/") and not selected_path:match("^%a:") then
    selected_path = vim.fn.fnamemodify(cwd .. "/" .. selected_path, ":p")
  end

  return myconfig.normalize_path(selected_path)
end

function diff_buffers_or_file()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)

  local use_fzf_for_diff = myconfig.get_file_picker() == myconfig.FilePicker.FZF
  local use_fzf_lua_for_diff = myconfig.get_file_picker() == myconfig.FilePicker.FZF_LUA
  local use_debug_print = myconfig.should_debug_print()

  if #windows == 2 then
    vim.cmd("windo diffthis")
    print("Diff mode enabled for the two open splits.")
  else
    local file_to_diff = vim.fn.input("Enter file path or directory to diff with current buffer: ")
    if file_to_diff ~= "" then
      file_to_diff = replace_env_paths(file_to_diff)

      if vim.fn.isdirectory(file_to_diff) == 1 then
        if use_fzf_lua_for_diff then
          require('fzf-lua').files({
            cwd = file_to_diff,
            prompt = "Select a file to diff",
            actions = {
              ["default"] = function(selected_paths)
                local cwd = file_to_diff
                local selected_path = selected_paths[1]

                if selected_path then
                  if use_debug_print then
                    print("path: " .. selected_path)
                  end
                  selected_path = clean_selected_path(cwd, selected_path)
                  if use_debug_print then
                    print("Cleaned path: " .. selected_path)
                  end

                  vim.cmd("vsplit " .. vim.fn.fnameescape(selected_path))
                  vim.cmd("diffthis")
                  vim.cmd("windo diffthis")
                  print("Diff mode enabled for current buffer and " .. selected_path)
                else
                  print("No file selected. Diff mode aborted.")
                end
              end,
            },
          })
        elseif use_fzf_for_diff then
          vim.fn['fzf#run']({
            dir = file_to_diff,
            options = '--prompt="Select file to diff> " --reverse',
            sink = function(selected)
              local file = clean_selected_path(file_to_diff, selected)
              vim.cmd("vsplit " .. vim.fn.fnameescape(file))
              vim.cmd("diffthis | windo diffthis")
              print("Diff mode enabled for current buffer and " .. file)
            end,
            window = {
              width = 0.6,
              height = 0.6,
              border = 'rounded',
            },
          })
        else
          require('telescope.builtin').find_files({
            cwd = file_to_diff,
            prompt_title = "Select a file to diff",
            attach_mappings = function(_, map)
              map("i", "<CR>", function(prompt_bufnr)
                local selected = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)
                if selected and selected.path then
                  vim.cmd("vsplit " .. vim.fn.fnameescape(selected.path))
                  vim.cmd("diffthis")
                  vim.cmd("windo diffthis")
                  print("Diff mode enabled for current buffer and " .. selected.path)
                end
              end)
              return true
            end,
          })
        end
      elseif vim.fn.filereadable(file_to_diff) == 1 then
        vim.cmd("vsplit " .. vim.fn.fnameescape(file_to_diff))
        vim.cmd("diffthis")
        vim.cmd("windo diffthis")
        print("Diff mode enabled for current buffer and " .. file_to_diff)
      else
        print("Invalid file or directory path. Please try again.")
      end
    else
      print("No file path provided. Diff mode aborted.")
    end
  end
end

vim.api.nvim_create_user_command('DiffCp', diff_copy, {})
vim.api.nvim_create_user_command('Diffi', diff_current_lines, {})
vim.api.nvim_create_user_command('Diffg', diffg_command, {})
vim.api.nvim_create_user_command('Diffgf', diffgf_command, {})
vim.api.nvim_set_keymap("n", "<leader>di", ":lua diff_buffers_or_file()<CR>", { noremap = true, silent = true })

