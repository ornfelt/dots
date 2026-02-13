require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    use_default_keymaps = false, -- disable <space>m/j/s
    -- everything else stays default
  },
  keys = {
    -- bind leader-tsm: toggle split/join (n)
    {
      "<leader>tsm",
      function() require("treesj").toggle() end,
      desc = "Treesj: Toggle split/join",
    },
    -- bind leader-tsj: join (n)
    {
      "<leader>tsj",
      function() require("treesj").join() end,
      desc = "Treesj: Join",
    },
    -- bind leader-tss: split (n)
    {
      "<leader>tss",
      function() require("treesj").split() end,
      desc = "Treesj: Split",
    },
  },
}
