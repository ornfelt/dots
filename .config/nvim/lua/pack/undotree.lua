require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/jiaoshijie/undotree",
  dependencies = {
    "https://github.com/nvim-lua/plenary.nvim",
  },
  config = function()
    require("undotree").setup()
    -- bind leader-u: undotree toggle (n)
    vim.keymap.set("n", "<leader>u", "<cmd>lua require('undotree').toggle()<cr>")
  end,
}
