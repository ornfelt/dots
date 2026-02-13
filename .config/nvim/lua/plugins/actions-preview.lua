require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "aznhe21/actions-preview.nvim",
  lazy = true,
  config = function()
    require("actions-preview").setup()
  end,
}
