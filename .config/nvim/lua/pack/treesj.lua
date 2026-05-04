require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/Wansmer/treesj",
  dependencies = {
    "https://github.com/nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require('treesj').setup({
      use_default_keymaps = false, -- disable <space>m/j/s
      -- everything else stays default
    })
    -- bind leader-tsm: toggle split/join (n)
    vim.keymap.set("n", "<leader>tsm",
      function() require("treesj").toggle() end,
      { desc = "Treesj: Toggle split/join" })
    -- bind leader-tsj: join (n)
    vim.keymap.set("n", "<leader>tsj",
      function() require("treesj").join() end,
      { desc = "Treesj: Join" })
    -- bind leader-tss: split (n)
    vim.keymap.set("n", "<leader>tss",
      function() require("treesj").split() end,
      { desc = "Treesj: Split" })
  end,
}

