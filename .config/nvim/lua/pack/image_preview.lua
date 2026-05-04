require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/adelarsq/image_preview.nvim",
  config = function()
    require("image_preview").setup()
  end,
}
