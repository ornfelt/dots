require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  -- General
  require("plugins.gruvbox"),
  require("plugins.lualine"),
  require("plugins.fzf"),
  require("plugins.fzf-lua"),
  require("plugins.telescope"),
  require("plugins.oil"),

  -- LSP
  require("plugins.nvim-lspconfig"),
  require("plugins.nvim-cmp"),
  require("plugins.cmp-buffer"),
  require("plugins.cmp-cmdline"),
  require("plugins.cmp-nvim-lsp"),
  require("plugins.cmp-path"),

  --require("plugins.blink"),

  -- Treesitter
  require("plugins.nvim-treesitter"),
  require("plugins.nvim-treesitter-textobjects"),
  require("plugins.treewalker"),
  require("plugins.treesj"),

  -- Nice to have
  require("plugins.nvim-colorizer"),
  require("plugins.gitgraph"),
  require("plugins.trouble"),
  require("plugins.actions-preview"),
  require("plugins.Comment"),
  require("plugins.vim-emoji"),
  require("plugins.undotree"),
  --require("plugins.markview"),
  require("plugins.sqls"),
  require("plugins.roslyn"),
  --require("plugins.python-syntax"),
  --require("plugins.vim-commentary"),
  --require("plugins.vim-fugitive"),
  --require("plugins.image_preview"),

  -- AI
  require("plugins.ChatGPT"),
  require("plugins.gen"),
  require("plugins.gp"),
  require("plugins.model"),
  --require("plugins.copilot"),
  --require("plugins.avante"),
}

