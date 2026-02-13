require('dbg_log').log_file(debug.getinfo(1, 'S').source)

require("config.lazy")
require("lazy_plugins")
require('options')

-- Note: lazy loading below technically works but is 
-- a bit annoying since some autocmds aren't 
-- applied to the opened file unless reloaded...
local LAZY_LOAD = false

-- eager loading
if not LAZY_LOAD then
  --require('lsp_new')
  --require('custom_statusline')
  require('lsp')
  require('keybindings')
  require('autocmds')
end

-- Lazy loading on UIEnter
if LAZY_LOAD then
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      vim.schedule(function()
        -- lazy load these
        --require('lsp_new')
        --require('custom_statusline')
        require('lsp')
        require('keybindings')
        require('autocmds')
      end)
    end,
  })
end

