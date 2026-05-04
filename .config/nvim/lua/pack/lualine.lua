require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/nvim-lualine/lualine.nvim",
  dependencies = {
    "https://github.com/kyazdani42/nvim-web-devicons",
  },
  config = function()
    require("config.lualine")
  end,
}
