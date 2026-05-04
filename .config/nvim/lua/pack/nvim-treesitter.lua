require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/nvim-treesitter/nvim-treesitter",
  version = "main", -- branch = "main" in lazy
  -- lazy had `build = ":TSUpdate"`. On the main branch parsers are managed
  -- via :TSInstall and friends, so a global build hook isn't needed here.
  -- If you want it, add a User PackChanged autocmd in pack_plugins.lua.
  --event = "VeryLazy",
  config = function()
    require("config.treesitter")
  end,
}
