local use_lazy = true

-- If switching from packer -> lazy, do this:
-- Move-Item -Path "$Env:LOCALAPPDATA\nvim-data\site" -Destination "$Env:LOCALAPPDATA\nvim-data\site_old" -Force
-- Switching back
-- Move-Item -Path "$Env:LOCALAPPDATA\nvim-data\site_old" -Destination "$Env:LOCALAPPDATA\nvim-data\site" -Force
-- Or:
-- mv -f "$XDG_DATA_HOME/nvim/site" "$XDG_DATA_HOME/nvim/site_old"
-- i.e.
-- mv -f "$HOME/.local/share/nvim/site" "$HOME/.local/share/nvim/site_old"
-- Switching back
-- mv -f "$XDG_DATA_HOME/nvim/site_old" "$XDG_DATA_HOME/nvim/site"
-- i.e.
-- mv -f "$HOME/.local/share/nvim/site_old" "$HOME/.local/share/nvim/site"
if use_lazy then
  require("config.lazy")
  require("plugins")
else
  require("plugins_packer")
end

require('options')
require('statusline')
require('lsp')
require('keybindings')
require('autocmds')
require('telescope_conf')
require('treesitter_conf')
require('trouble_conf')
require('ai')

