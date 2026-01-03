return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    use_default_keymaps = false, -- disable <space>m/j/s
    -- everything else stays default
  },
  keys = {
    {
      "<leader>tsm",
      function() require("treesj").toggle() end,
      desc = "Treesj: Toggle split/join",
    },
    {
      "<leader>tsj",
      function() require("treesj").join() end,
      desc = "Treesj: Join",
    },
    {
      "<leader>tss",
      function() require("treesj").split() end,
      desc = "Treesj: Split",
    },
  },
}
