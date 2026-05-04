require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/stevearc/oil.nvim",
  --dependencies = { "https://github.com/nvim-mini/mini.icons" },
  dependencies = {
    "https://github.com/kyazdani42/nvim-web-devicons",
  },
  config = function()
    require("oil").setup({})
  end,
}
