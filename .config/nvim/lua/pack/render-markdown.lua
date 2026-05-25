require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "https://github.com/nvim-treesitter/nvim-treesitter",

    -- Pick ONE icon provider.
    --"https://github.com/nvim-mini/mini.nvim", -- mini.nvim suite
    -- "https://github.com/nvim-mini/mini.icons", -- if using standalone mini plugins
     "https://github.com/nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("render-markdown").setup({
      -- custom options
    })
  end,
}
