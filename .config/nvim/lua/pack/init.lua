require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require('myconfig')

return {
  -- General
  require("pack.gruvbox"),
  myconfig.should_use_custom_statusline() and {} or require("pack.lualine"),
  require("pack.fzf"),
  require("pack.fzf-lua"),
  require("pack.telescope"),
  require("pack.oil"),

  -- LSP
  require("pack.nvim-lspconfig"),
  require("pack.nvim-cmp"),
  require("pack.cmp-buffer"),
  require("pack.cmp-cmdline"),
  require("pack.cmp-nvim-lsp"),
  require("pack.cmp-path"),

  --require("pack.blink"),

  -- Treesitter
  require("pack.nvim-treesitter"),
  require("pack.nvim-treesitter-textobjects"),
  require("pack.treewalker"),
  require("pack.treesj"),

  -- Nice to have
  require("pack.nvim-colorizer"),
  require("pack.diffview"),
  require("pack.gitgraph"),
  require("pack.trouble"),
  require("pack.actions-preview"),
  require("pack.Comment"),
  require("pack.vim-emoji"),
  require("pack.undotree"),
  --require("pack.markview"),
  require("pack.sqls"),
  require("pack.roslyn"),
  --require("pack.python-syntax"),
  --require("pack.vim-commentary"),
  --require("pack.vim-fugitive"),
  --require("pack.image_preview"),

  -- AI
  require("pack.ChatGPT"),
  require("pack.gen"),
  require("pack.gp"),
  require("pack.model"),
  --require("pack.copilot"),
  --require("pack.avante"),
}
