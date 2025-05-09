return {
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  config = true,
  keys = { -- load the plugin only when using it's keybinding:
    -- map: <leader>u -> undotree toggle
    { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
  },
}
