require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  'adelarsq/image_preview.nvim',
  event = 'VeryLazy',
  config = function()
    require("image_preview").setup()
  end,
}
