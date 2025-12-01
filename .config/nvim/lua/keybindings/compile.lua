local myconfig = require("myconfig")

local code_root_dir = myconfig.code_root_dir

local function SqlExecCommand()
  code_root_dir = code_root_dir:gsub(" ", '" "') -- Handle spaces in the path

  -- Add '/' at the end if it doesn't exist
  --if not code_root_dir:match("/$") then
  --    code_root_dir = code_root_dir .. "/"
  --end

  -- Remove '/' at the end if it exists (not necessary really)
  code_root_dir = code_root_dir:gsub("/$", "")

  local executable_net9 = code_root_dir .. '/Code2/SQL/my_sql/SqlExec/SqlExec/bin/Debug/net9.0/SqlExec.exe'
  local executable_net8 = code_root_dir .. '/Code2/SQL/my_sql/SqlExec/SqlExec/bin/Debug/net8.0/SqlExec.exe'
  local executable_net7 = code_root_dir .. '/Code2/SQL/my_sql/SqlExec/SqlExec/bin/Debug/net7.0/SqlExec.exe'

  if vim.fn.has('win32') == 0 then
    executable_net9 = executable_net9:gsub("%.exe$", "")
    executable_net8 = executable_net8:gsub("%.exe$", "")
    executable_net7 = executable_net7:gsub("%.exe$", "")
  end

  local function file_exists(path)
    local stat = vim.loop.fs_stat(path)
    return stat ~= nil
  end
  --local executable = file_exists(executable_net8) and executable_net8 or executable_net7
  -- Priority: net9.0 > net8.0 > net7.0
  local executable =
      file_exists(executable_net9) and executable_net9 or
      file_exists(executable_net8) and executable_net8 or
      executable_net7

  -- Override with other sql_exec lang
  local sql_exec_lang = myconfig.get_sql_exec_lang()
  sql_exec_lang = sql_exec_lang and sql_exec_lang:lower() or ""

  --if sql_exec_lang == "go" then
  --  local go_exec = code_root_dir .. '/Code2/SQL/my_sql/sql_exec/go/sql_exec.exe'
  --  if vim.fn.has('win32') == 0 then
  --    go_exec = go_exec:gsub("%.exe$", "")
  --  end
  --  if file_exists(go_exec) then
  --    executable = go_exec
  --  end
  --elseif sql_exec_lang == "cpp" then
  --  local cpp_exec = code_root_dir .. '/Code2/SQL/my_sql/sql_exec/cpp/build/SqlExec.exe'
  --  if vim.fn.has('win32') == 0 then
  --    cpp_exec = cpp_exec:gsub("%.exe$", "")
  --  end
  --  if file_exists(cpp_exec) then
  --    executable = cpp_exec
  --  end
  --end
  -- cleaner:
  local exec_map = {
    go  = '/Code2/SQL/my_sql/sql_exec/go/sql_exec.exe',
    cpp = '/Code2/SQL/my_sql/sql_exec/cpp/build/SqlExec.exe',
  }

  local rel_path = exec_map[sql_exec_lang]
  if rel_path then
    local candidate = code_root_dir .. rel_path
    if vim.fn.has('win32') == 0 then
      candidate = candidate:gsub('%.exe$', '')
    end

    if file_exists(candidate) then
      executable = candidate
    end
  end

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
  --vim.api.nvim_buf_set_option(new_buf, "bufhidden", "wipe") -- Automatically wipe the buffer when closed
end

local function is_prioritized_filetype(filetype)
  local prioritized_filetypes = {
    'c', 'cpp', 'cs', 'css', 'go', 'h', 'hpp', 'html',
    'java', 'js', 'jsx', 'lua', 'php', 'py', 'python',
    'rs', 'ts', 'tsx', 'zig'
  }

  for _, ft in ipairs(prioritized_filetypes) do
    if ft == filetype then
      return true
    end
  end
  return false
end

function compile_run()
  vim.cmd('w') -- Save the file first

  local filetype = vim.bo.filetype
  local is_windows = vim.fn.has('win32') == 1 -- or vim.fn.has('win16') == 1 or vim.fn.has('win64') == 1
  local build_script = is_windows and './build.ps1' or './build.sh'

  if myconfig.should_prioritize_build_script() and is_prioritized_filetype(filetype) then
    local build_script_exists = vim.fn.filereadable(build_script) == 1
    if build_script_exists then
      if is_windows then
        vim.cmd('!powershell -NoProfile -ExecutionPolicy ByPass -File build.ps1')
      else
        vim.cmd('!bash ./build.sh')
      end
      return
    end
  end

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
    --local build_script = is_windows and './build.ps1' or './build.sh'
    --local build_script_exists = vim.fn.filereadable(build_script) == 1
    --if build_script_exists then
    --    if is_windows then
    --        vim.cmd('!powershell -ExecutionPolicy ByPass -File build.ps1')
    --    else
    --        vim.cmd('!bash ./build.sh')
    --    end
    --    return
    --end
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
    -- local main_py_exists = vim.fn.filereadable('./main.py') == 1
    -- local has_main = vim.fn.search('__main__', 'nw') > 0
    -- if main_py_exists and not has_main then
    -- vim.cmd(is_windows and '!python ./main.py > test.txt' or '!time python3 ./main.py > test.txt')
    -- else
    -- vim.cmd(is_windows and '!python % > test.txt' or '!time python3 % > test.txt')
    -- end
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
    --vim.cmd(is_windows and '!tsc; node ' .. js_file or '!tsc && time node ' .. js_file)

    local package_json_exists = vim.fn.filereadable('./package.json') == 1

    if package_json_exists then
      vim.cmd(is_windows and '!npm start' or '!time npm start')
    else
      --local js_file = "dist/" .. vim.fn.fnamemodify(js_file, ":t")

      if is_windows then
        vim.cmd('!tsc ' .. ts_file)
        vim.cmd('!node ' .. js_file)
      else
        vim.cmd('!tsc ' .. ts_file .. ' && time node ' .. js_file)
      end
    end

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

