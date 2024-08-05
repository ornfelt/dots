-- useINS
--
-- Only required if you have packer configured as `opt`
-- vim.cmd [[packadd packer.nvim]]
return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- A better status line
  use {
     'nvim-lualine/lualine.nvim',
     requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  -- File management --
  -- use 'scrooloose/nerdtree'
  use 'preservim/nerdtree'
  use 'tiagofumo/vim-nerdtree-syntax-highlight'
  -- use 'vifm/vifm.vim'
  -- use 'ryanoasis/vim-devicons'

  -- Productivity --
  use 'vimwiki/vimwiki'
  use 'tpope/vim-surround'

  use 'junegunn/fzf'
  --use { "ibhagwan/fzf-lua"
  -- optional for icon support
  --requires = { "nvim-tree/nvim-web-devicons" }
  -- or if using mini.icons/mini.nvim
  -- requires = { "echasnovski/mini.icons" }
  --}

  use 'tpope/vim-commentary'
  -- use 'junegunn/goyo.vim'
  -- use 'junegunn/limelight.vim'
  use 'junegunn/vim-emoji'
  -- use 'jreybert/vimagit'

  -- Syntax Highlighting and Colors --
  use 'vim-python/python-syntax'
  use 'norcalli/nvim-colorizer.lua'
  -- use 'vim-syntastic/syntastic'
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  -- use 'mechatroner/rainbow_csv'
  -- use 'PotatoesMaster/i3-vim-syntax'
  -- use 'kovetskiy/sxhkd-vim'

  -- Colorschemes
  use("gruvbox-community/gruvbox")

  -- Other stuff
  -- use 'frazrepo/vim-rainbow'

  -- use("simrat39/rust-tools.nvim")

  use {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate'
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

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

  --use("robitx/gp.nvim")
  --use({
  --    "robitx/gp.nvim",
  --    config = function()
  --        require("gp").setup()
  --        or setup with your own config (see Install > Configuration in Readme)
  --        require("gp").setup(config)
  --        shortcuts might be setup here (see Usage > Shortcuts in Readme)
  --    end,
  --})

  use 'nanotee/sqls.nvim'

end)
