local myconfig = require("myconfig")

-- lualine
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

myconfig.map('n', '<leader>b', togglebar) -- Toggle lualine

-- lua calculator
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

-- " Execute line under the cursor
-- nnoremap <leader>, yy:@"<CR>
--vim.api.nvim_set_keymap('n', '<leader>,', 'yy:@"<CR>', { noremap = true, silent = true })
--
-- Function to execute command under cursor or highlighted text
function execute_command()
  local mode = vim.fn.mode()
  local command

  if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is for visual block mode
    -- Yank selection to "v" register
    vim.cmd('normal! "vy')
    command = vim.fn.getreg("v")
  else
    command = vim.fn.getline('.')
  end

  if myconfig.should_debug_print() then
    -- Copy to clipboard
    vim.fn.setreg('+', command)
    print("Copied to clipboard: " .. command)
  else
    -- Execute it
    vim.cmd(command)
  end
end

-- Try with these:
-- lua print(vim.fn.getenv("my_notes_path"))
-- lua print(vim.fn.getenv("code_root_dir"))
-- lua print(vim.fn.getenv("ps_profile_path"))
vim.api.nvim_set_keymap('n', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })

function count_characters()
  local mode = vim.api.nvim_get_mode().mode
  local text = ""

  if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is for visual block mode
    -- Yank selection to "v" register
    vim.cmd('normal! "vy')
    text = vim.fn.getreg("v")
  else
    -- Word under cursor
    text = vim.fn.expand("<cword>")
  end

  local char_count = #text
  print("Character count: " .. char_count)
end

-- Keybindings for counting characters
vim.api.nvim_set_keymap("n", "<leader>cc", ":lua count_characters()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<leader>cc", "<cmd>lua count_characters()<CR>", { noremap = true, silent = true })

