local myconfig = require("myconfig")

-- QuickFix Lists
myconfig.map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>0f/li')
-- myconfig.map('n', '<M-v>', ':cfdo s//x/gc<left><left><left><left><left><C-f>i')
myconfig.map('n', '<M-n>', ':cnext<CR>')
myconfig.map('n', '<M-p>', ':cprev<CR>')
myconfig.map('n', '<M-P>', ':clast<CR>')
myconfig.map('n', '<M-b>', ':copen<CR>')
myconfig.map('n', '<M-B>', ':cclose<CR>')

function ToggleQuickfix()
  local is_open = false

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
-- vim.api.nvim_set_keymap('n', '<M-b>', ':lua ToggleQuickfix()<CR>', { noremap = true, silent = true })

--vim.keymap.set('n', '<leader>db', '<cmd>lua vim.diagnostic.setqflist()<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>db', function()
  local current_line = vim.fn.line('.')
  vim.diagnostic.setqflist()

  --vim.defer_fn(function()
  local qf_items = vim.fn.getqflist()
  for i, item in ipairs(qf_items) do
    if item.lnum == current_line then
      vim.cmd(tostring(i) .. 'cc')
      vim.cmd('copen')
      return
    end
  end

  vim.cmd('copen')
  --end, 100)

end, { noremap = true, silent = true })

-- Diagnostics
vim.keymap.set('n', '<leader>df', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>dc', function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
  if #diagnostics > 0 then
    --local message = diagnostics[1].message
    local messages = {}
    for _, diagnostic in ipairs(diagnostics) do
      table.insert(messages, diagnostic.message)
    end

    local message = table.concat(messages, '\n')
    vim.fn.setreg('+', message)

    if myconfig.should_debug_print() then
      print('Copied to clipboard:\n' .. message)
    end
  else
    print('No diagnostics on this line.')
  end
end, { noremap = true, silent = true })

