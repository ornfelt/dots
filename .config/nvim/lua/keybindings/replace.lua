-- Replace / substitution keybinds
function VisualSubstituteCommand()
  -- local mode = vim.fn.mode() -- Check mode if needed?
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  -- Ensure start_line <= end_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Leave visual mode first
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', false)
  local cmd_string = ":" .. start_line .. "," .. end_line .. "s,"
  local keys = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
  -- vim.fn.feedkeys(":" .. start_line .. "," .. end_line .. "s,")
  --local left_key = vim.api.nvim_replace_termcodes("<Left>", true, false, true)
  --vim.api.nvim_feedkeys(left_key, 'n', false)
end

local function VisualReplaceCommand()
  local mode = vim.fn.mode()
  if not (mode == 'v' or mode == 'V' or mode == '\22') then -- '\22' represents <C-V> (visual block)
    print("VisualReplaceCommand can only be used in visual mode.")
    return
  end

  -- Yank visually selected text into register z
  vim.cmd('noau normal! "zy')
  local selected_text = vim.fn.getreg('z')

  -- Trim any leading/trailing whitespace
  selected_text = selected_text:gsub("^%s*(.-)%s*$", "%1")

  -- Replace line breaks with spaces to handle multi-line selections
  selected_text = selected_text:gsub("\n", "\\n")

  -- Escape special characters for use in the substitution command
  -- selected_text = selected_text:gsub("([%%%^%$%(%)%%%.%[%]%*%+%-%?%|])", "\\%1")

  local cmd_string = ":%s," .. selected_text .. ","
  -- Replace termcodes to ensure special keys are interpreted correctly
  local keys = vim.api.nvim_replace_termcodes(cmd_string, true, false, true)
  -- Exit visual mode by sending <Esc>
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, 'n', false)
  vim.api.nvim_feedkeys(keys, 'n', false)
end

-- bind leader-r: replace word under cursor (n)
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Replace word under cursor
-- bind leader-s-r: VisualSubstituteCommand (v)
vim.api.nvim_set_keymap('v', '<leader>R', '<cmd>lua VisualSubstituteCommand()<CR>', { noremap = true, silent = true })

-- bind leader-r: VisualReplaceCommand (v)
vim.keymap.set('v', '<leader>r', function()
  VisualReplaceCommand()
end, { noremap = true, silent = true })

