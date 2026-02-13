require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "OXY2DEV/markview.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  --lazy = is_raspbian
}
