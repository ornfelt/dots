require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "stevearc/oil.nvim",
  lazy = true,
  config = function()
    require("oil").setup({})
  end,
}
