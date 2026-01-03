return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  --event = "VeryLazy",
  config = function()
    require("config.treesitter")
  end,
}
