require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "kyazdani42/nvim-web-devicons" },
  config = function()
    require("config.lualine")
  end,
}
