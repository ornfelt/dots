require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  version = "main", -- branch = "main" in lazy
  dependencies = {
    "https://github.com/nvim-treesitter/nvim-treesitter",
  },
  --event = "VeryLazy",
}
