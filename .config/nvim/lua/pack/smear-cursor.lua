require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/sphamba/smear-cursor.nvim",
  config = function()
    require("smear_cursor").setup({})
  end,
}
