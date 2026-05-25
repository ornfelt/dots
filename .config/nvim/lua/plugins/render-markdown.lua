require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",

    -- Pick ONE icon provider.
    --"nvim-mini/mini.nvim", -- mini.nvim suite
    --"nvim-mini/mini.icons", -- if using standalone mini plugins
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    -- custom options
  },
}
