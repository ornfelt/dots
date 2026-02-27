require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "stevearc/oil.nvim",
  --dependencies = { "nvim-mini/mini.icons" },
  dependencies = { "kyazdani42/nvim-web-devicons" },
  lazy = true,
  config = function()
    require("oil").setup({})
  end,
}
