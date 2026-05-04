require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/OXY2DEV/markview.nvim",
  dependencies = {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/nvim-tree/nvim-web-devicons",
  },
  --lazy = is_raspbian
}
