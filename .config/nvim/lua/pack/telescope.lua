require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/nvim-telescope/telescope.nvim",
  dependencies = {
    "https://github.com/nvim-lua/plenary.nvim",
  },
  config = function()
    require("config.telescope")
  end,
}
