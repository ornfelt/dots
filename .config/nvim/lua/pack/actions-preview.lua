require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/aznhe21/actions-preview.nvim",
  config = function()
    require("actions-preview").setup()
  end,
}
