require("config.lazy")
require("lazy_plugins")
require('options')

-- lazy load these
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      --require('lsp_new')
      --require('custom_statusline')
      require('lsp')
      require('keybindings')
      require('autocmds')
    end)
  end,
})

