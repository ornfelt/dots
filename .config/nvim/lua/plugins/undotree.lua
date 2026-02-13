require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  config = true,
  keys = { -- load the plugin only when using it's keybinding:
    -- bind leader-u: undotree toggle (n)
    { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
  },
}
