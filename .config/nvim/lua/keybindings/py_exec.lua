local myconfig = require("myconfig")

local code_root_dir = myconfig.code_root_dir

local function PythonCommand()
  vim.cmd('w') -- Save the file first
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
    vim.schedule(function()
      local move_left_count = #args
      local move_left_keys = vim.api.nvim_replace_termcodes(string.rep("<Left>", move_left_count), true, false, true)
      vim.api.nvim_feedkeys(move_left_keys, "n", false)
    end)
  end
end

vim.api.nvim_create_user_command('RunPythonCommand', PythonCommand, {})
vim.api.nvim_set_keymap('v', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>h', '<cmd>RunPythonCommand<CR>', { noremap = true, silent = true })

function PythonExecCommand()
  vim.cmd('w') -- Save the file first
  code_root_dir = code_root_dir:gsub(" ", '" "')

  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/read_file.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/gpt.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/claude/claude.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/gemini/gemini.py"
  --local script_path = code_root_dir .. "Code2/Python/my_py/scripts/mistral/mistral.py"
  local command = myconfig.get_py_command()
  local script_path = code_root_dir .. "/Code2/Python/my_py/scripts/" .. command .. ".py"

  local use_debug_print = myconfig.should_debug_print()

  if use_debug_print then
    print(script_path)
  end

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

  if use_debug_print then
    print("args: " .. formatted_args)
  end

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

