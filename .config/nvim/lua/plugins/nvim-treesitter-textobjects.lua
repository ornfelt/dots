require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  lazy = false,
  --event = "VeryLazy",
}
