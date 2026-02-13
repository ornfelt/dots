require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  --event = "VeryLazy",
  config = function()
    require("config.treesitter")
  end,
}
