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
  use 'tpope/vim-commentary'
  -- use 'junegunn/goyo.vim'
  -- use 'junegunn/limelight.vim'
  use 'junegunn/vim-emoji'
  -- use 'jreybert/vimagit'

  -- Syntax Highlighting and Colors --
  use 'vim-python/python-syntax'
  use 'ap/vim-css-color'
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
  use {
      "catppuccin/nvim",
      as = "catppuccin",
      config = function()
          require("catppuccin").setup {
              --flavour = "macchiato" -- mocha, macchiato, frappe, latte
              flavour = "mocha"
          }
          -- vim.api.nvim_command "colorscheme catppuccin"
      end
  }
  -- use 'RRethy/nvim-base16'

  -- Other stuff
  -- use 'frazrepo/vim-rainbow'
end)
