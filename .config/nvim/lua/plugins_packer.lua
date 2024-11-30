-- useINS
--
-- Only required if you have packer configured as `opt`
-- vim.cmd [[packadd packer.nvim]]
return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
     'nvim-lualine/lualine.nvim',
     requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  -- use 'preservim/nerdtree'
  use 'stevearc/oil.nvim'
  -- use 'echasnovski/mini.files'

  -- use 'vimwiki/vimwiki'
  -- use 'tpope/vim-surround'

  -- use 'junegunn/fzf'
  use 'ibhagwan/fzf-lua'
  -- use { "ibhagwan/fzf-lua",
   -- --requires = { "nvim-tree/nvim-web-devicons" } -- icon support
   -- -- or if using mini.icons/mini.nvim
   -- requires = { "echasnovski/mini.icons" }
  -- }

  use 'tpope/vim-commentary'
  use 'junegunn/vim-emoji'
  use 'vim-python/python-syntax'
  use 'norcalli/nvim-colorizer.lua'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  use("gruvbox-community/gruvbox")

  use {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate'
  }

  --use({
  --    "nvim-treesitter/nvim-treesitter-textobjects",
  --    after = "nvim-treesitter",
  --    requires = "nvim-treesitter/nvim-treesitter",
  --})
  use({
      "nvim-treesitter/nvim-treesitter-textobjects",
      requires = "nvim-treesitter/nvim-treesitter",
  })

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  --use {
  --    'letieu/wezterm-move.nvim',
  --    config = function()
  --    local _ = require("wezterm-move")
  --    vim.api.nvim_set_keymap('n', '<m-h>', '<cmd>lua require("wezterm-move").move("h")<CR>', { noremap = true, silent = true })
  --    vim.api.nvim_set_keymap('n', '<m-j>', '<cmd>lua require("wezterm-move").move("j")<CR>', { noremap = true, silent = true })
  --    vim.api.nvim_set_keymap('n', '<m-k>', '<cmd>lua require("wezterm-move").move("k")<CR>', { noremap = true, silent = true })
  --    vim.api.nvim_set_keymap('n', '<m-l>', '<cmd>lua require("wezterm-move").move("l")<CR>', { noremap = true, silent = true })
  --    end
  --}

  -- AI
  use({
      "ornfelt/ChatGPT.nvim",
      --config = function()
      --    require("chatgpt").setup()
      --end,
      requires = {
          "MunifTanjim/nui.nvim",
          --"nvim-lua/plenary.nvim",
          "folke/trouble.nvim",
          --"nvim-telescope/telescope.nvim"
      }
  })

  use("robitx/gp.nvim")
  --use({
  --    "robitx/gp.nvim",
  --    config = function()
  --        require("gp").setup()
  --        or setup with your own config (see Install > Configuration in Readme)
  --        require("gp").setup(config)
  --        shortcuts might be setup here (see Usage > Shortcuts in Readme)
  --    end,
  --})

  -- use 'github/copilot.vim'
  -- use 'David-Kunz/gen.nvim'

  use 'gsuuon/model.nvim'

  -- avante (cursor-like)
  --use 'stevearc/dressing.nvim'
  ---- use 'nvim-lua/plenary.nvim'
  --use 'MunifTanjim/nui.nvim'
  ---- Optional dependencies
  ---- use 'nvim-tree/nvim-web-devicons' -- or 'echasnovski/mini.icons'
  ---- use 'HakonHarnes/img-clip.nvim'
  ---- use 'zbirenbaum/copilot.lua'
  --use {
  --  'yetone/avante.nvim',
  --  branch = 'main',
  --  run = 'make'
  --}
  -- end avante

  use {
    "aznhe21/actions-preview.nvim",
    config = function()
      require("actions-preview").setup()
    end,
  }
  use 'nanotee/sqls.nvim'
  use 'preservim/nerdcommenter'

  use 'tpope/vim-fugitive'
  use 'sindrets/diffview.nvim'
  use {
      'ornfelt/gitgraph.nvim',
      dependencies = { 'sindrets/diffview.nvim' },
      opts = {
          symbols = {
              merge_commit = 'M',
              commit = '*',
          },
          format = {
              timestamp = '%H:%M:%S %d-%m-%Y',
              fields = { 'hash', 'timestamp', 'author', 'branch_name', 'tag' },
          },
          hooks = {
              on_select_commit = function(commit)
                  vim.notify('DiffviewOpen ' .. commit.hash .. '^!')
                  vim.cmd(':DiffviewOpen ' .. commit.hash .. '^!')
              end,
              on_select_range_commit = function(from, to)
                  vim.notify('DiffviewOpen ' .. from.hash .. '~1..' .. to.hash)
                  vim.cmd(':DiffviewOpen ' .. from.hash .. '~1..' .. to.hash)
              end,
          },
      }
  }

  -- use({
      -- 'MeanderingProgrammer/render-markdown.nvim',
      -- after = { 'nvim-treesitter' },
      -- -- requires = { 'echasnovski/mini.nvim', opt = true }, -- if you use the mini.nvim suite
      -- -- requires = { 'echasnovski/mini.icons', opt = true }, -- if you use standalone mini plugins
      -- -- requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
      -- config = function()
          -- require('render-markdown').setup({})
      -- end,
  -- })
  use ({
      "OXY2DEV/markview.nvim",
      dependencies = {
          "nvim-treesitter/nvim-treesitter",
          "nvim-tree/nvim-web-devicons"
      }
  })

  -- use 'alexghergh/nvim-tmux-navigation',
  -- use 'mhinz/vim-startify',
  -- use 'mistweaverco/kulala.nvim',
  -- use '3rd/diagram.nvim',
  -- use 'lewis6991/gitsigns.nvim',
  -- use 'mechatroner/rainbow_csv',
  -- use("simrat39/rust-tools.nvim"),
  -- use 'vim-syntastic/syntastic',
  -- use 'neoclide/coc.nvim',

end)
