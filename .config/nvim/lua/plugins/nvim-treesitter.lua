return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  --event = "VeryLazy",
  config = function()
    require("config.treesitter")
  end,
}
