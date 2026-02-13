require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  config = function()
    require("config.telescope")
  end,
}
