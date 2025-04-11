local myconfig = require("myconfig")

local has_oil = myconfig.is_plugin_installed('oil')
local has_mini_files = pcall(require, 'mini.files')

-- File tree
if has_oil then
  require('oil').setup({
    keymaps = {
      ["<C-s>"] = { "actions.select", opts = { vertical = true, close = true }, desc = "Open the entry in a vertical split" },
      ["<C-h>"] = { "actions.select", opts = { horizontal = true, close = true }, desc = "Open the entry in a horizontal split" },
      ["<C-t>"] = { "actions.select", opts = { tab = true, close = true }, desc = "Open the entry in new tab" },
    },
    view_options = {
      show_hidden = true,
    },
    -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
    skip_confirm_for_simple_edits = false,
    -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
    -- (:help prompt_save_on_select_new_entry)
    prompt_save_on_select_new_entry = true,
  })
  -- myconfig.map('n', '<M-w>', ':leftabove vsplit | vertical resize 40 | Oil ~/ <CR>')
  -- myconfig.map('n', '<M-w>', ':Oil ~/ <CR>')
  vim.keymap.set('n', '<M-w>', function()
    if vim.bo.filetype == 'oil' then
      -- vim.cmd('bd')
      vim.cmd('b#')
    else
      vim.cmd('Oil ~/')
    end
  end)
elseif has_mini_files then
  require('mini.files').setup()
  myconfig.map('n', '<M-w>', ':lua MiniFiles.open("~/")<CR>')
end

-- vim.api.nvim_create_user_command('OilToggle', function()
-- vim.cmd((vim.bo.filetype == 'oil') and 'bd' or 'Oil')
-- end, { nargs = 0 })

function toggle_filetree()
  local filepath = vim.fn.expand('%:p') == '' and '~/' or vim.fn.expand('%:p:h')

  -- Silly fix for making oil work with domain-based user dirs
  --if filepath:find("%.homedir") then
  if filepath:find("%.corp") then
    filepath = filepath:gsub(".*se%-jonornf%-01\\", "H:/")
    filepath = filepath:gsub(" ", "\\ ")
  else
    if not filepath:lower():find("h:") then
      filepath = "./"
    end
  end

  if myconfig.should_debug_print() then
    print(filepath)
  end

  if has_oil then
    -- vim.cmd('leftabove vsplit | vertical resize 40 | Oil ' .. filepath)
    -- vim.cmd('Oil ' .. filepath)
    vim.cmd((vim.bo.filetype == 'oil') and 'b#' or 'Oil ' .. filepath)
  elseif has_mini_files then
    require('mini.files').open(filepath)
  else
    print("No file tree plugin installed...")
  end
end

myconfig.map('n', '<M-e>', ':lua toggle_filetree()<CR>')

