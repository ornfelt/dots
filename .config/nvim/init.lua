require('dbg_log').log_file(debug.getinfo(1, 'S').source)

--require("config.lazy")
--require("lazy_plugins")
--local USE_LAZY = true
local USE_LAZY = false

vim.g.my_use_lazy = USE_LAZY

if USE_LAZY then
  require("config.lazy")
  require("lazy_plugins")
else
  require("pack_plugins")
end

require('options')

local myconfig = require('myconfig')

-- Note: lazy loading below technically works but is 
-- a bit annoying since some autocmds aren't currently 
-- applied to the opened file unless it's reloaded...
local LAZY_LOAD = false

-- eager loading
if not LAZY_LOAD then
  --require('lsp_new')
  if myconfig.should_use_custom_statusline() then
    require('custom_statusline')
  end
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
        if myconfig.should_use_custom_statusline() then
          require('custom_statusline')
        end
        require('lsp')
        require('keybindings')
        require('autocmds')
      end)
    end,
  })
end

