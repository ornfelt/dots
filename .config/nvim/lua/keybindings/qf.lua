require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

-- QuickFix Lists
-- bind m-v: quickfix search and replace (n)
myconfig.map('n', '<M-v>', ':cdo s///gc | update<C-f><Esc>0f/li')
-- myconfig.map('n', '<M-v>', ':cfdo s//x/gc<left><left><left><left><left><C-f>i')
-- bind m-n: next quickfix item (n)
myconfig.map('n', '<M-n>', ':cnext<CR>')
-- bind m-p: previous quickfix item (n)
myconfig.map('n', '<M-p>', ':cprev<CR>')
-- bind m-s-p: last quickfix item (n)
myconfig.map('n', '<M-P>', ':clast<CR>')
-- bind m-b: open quickfix list (n)
myconfig.map('n', '<M-b>', ':copen<CR>')
-- bind m-s-b: close quickfix list (n)
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

-- bind leader-db: set diagnostics to quickfix and jump to current line (n)
vim.keymap.set('n', '<leader>db', function()
  local current_line = vim.fn.line('.')
  -- read before setqflist(): it opens the quickfix window, and the current
  -- buffer from in there is the list itself
  local current_buf = vim.api.nvim_get_current_buf()
  vim.diagnostic.setqflist()

  --vim.defer_fn(function()
  local qf_items = vim.fn.getqflist()
  for i, item in ipairs(qf_items) do
    -- the list holds every buffer's diagnostics, so the line number alone
    -- would jump into whichever file happens to have one on the same line
    if item.lnum == current_line and item.bufnr == current_buf then
      vim.cmd(tostring(i) .. 'cc')
      vim.cmd('copen')
      return
    end
  end

  vim.cmd('copen')
  --end, 100)

end, { noremap = true, silent = true })

-- Diagnostics
-- bind leader-df: open diagnostic float (n)
vim.keymap.set('n', '<leader>df', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })

-- bind leader-dc: copy diagnostic message to clipboard (n)
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

