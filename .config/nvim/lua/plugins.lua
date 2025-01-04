local is_raspbian = vim.loop.os_uname().sysname == "Linux" and vim.fn.system("lsb_release -is"):gsub("\n", "") == "Raspbian"

local my_plugins = {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "kyazdani42/nvim-web-devicons" }
  },
  {
    "stevearc/oil.nvim",
    lazy = true,
  },
  -- "echasnovski/mini.files",
  -- "vimwiki/vimwiki",
  -- "tpope/vim-surround",
  {
    "junegunn/fzf",
    lazy = false,
  },
  {
    "ibhagwan/fzf-lua",
    lazy = true,
  },
  {
    "tpope/vim-commentary",
    lazy = true,
  },
  {
    "junegunn/vim-emoji",
    lazy = true,
  },
  {
    "vim-python/python-syntax",
    lazy = true,
  },
  {
    "norcalli/nvim-colorizer.lua",
    lazy = true,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = false,
  },
  {
    "hrsh7th/cmp-buffer",
    lazy = false,
  },
  {
    "hrsh7th/cmp-path",
    lazy = false,
  },
  {
    "hrsh7th/cmp-cmdline",
    lazy = false,
  },
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
  },
  {
    "gruvbox-community/gruvbox",
    lazy = true,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    --event = "VeryLazy",
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    --event = "VeryLazy",
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
  },
  {
    "ornfelt/ChatGPT.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "folke/trouble.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    event = "VeryLazy",
  },
  {
    "robitx/gp.nvim",
    lazy = true,
  },
  --{
  --  "github/copilot.vim",
  --  lazy = true,
  --},
  --
  --{
  --  "David-Kunz/gen.nvim",
  --  lazy = true,
  --},
  {
    "gsuuon/model.nvim",
    lazy = true,
  },
  -- avante (cursor-like)
  --{
  --  "stevearc/dressing.nvim",
  --  lazy = true,
  --},
  --
  ---- Nui.nvim, for various UI plugins
  --{
  --  "MunifTanjim/nui.nvim",
  --  lazy = true,
  --},
  ---- Optional dependencies
  ---- {
  ----   "nvim-tree/nvim-web-devicons",
  ----   lazy = true,
  ---- },
  ---- {
  ----   "echasnovski/mini.icons", -- Alternative to nvim-web-devicons
  ----   lazy = true,
  ---- },
  ---- {
  ----   "HakonHarnes/img-clip.nvim", -- Clipboard image plugin
  ----   lazy = true,
  ---- },
  ---- {
  ----   "zbirenbaum/copilot.lua",
  ----   lazy = true,
  ----   config = function()
  ----     require("copilot").setup() -- Setup for Copilot
  ----   end,
  ---- },
  --
  --{
  --  "yetone/avante.nvim",
  --  branch = "main",
  --  build = "make",
  --  lazy = false, -- Load eagerly
  --  config = function()
  --  end,
  --},
  -- end avante
  {
    "aznhe21/actions-preview.nvim",
    config = function()
      require("actions-preview").setup()
    end,
    lazy = true,
  },
  {
    "nanotee/sqls.nvim",
    lazy = true,
  },
  {
    "numToStr/Comment.nvim",
    lazy = false,
    opts = {
      ---Add a space b/w comment and the line
      padding = false,
      ---Whether the cursor should stay at its position
      sticky = true,
      ---Lines to be ignored while (un)comment
      ignore = nil,
      ---LHS of toggle mappings in NORMAL mode
      toggler = {
        --line = 'gc',
        line = '<C-k>',
        block = 'gb',
      },
      ---LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
        --line = 'gc',
        line = '<C-k>',
        block = 'gb',
      },
      ---LHS of extra mappings
      extra = {
        ---Add comment on the line above
        above = 'gcO',
        ---Add comment on the line below
        below = 'gco',
        ---Add comment at the end of line
        eol = 'gcA',
      },
      ---Enable keybindings
      ---NOTE: If given `false` then the plugin won't create any mappings
      mappings = {
        ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
        basic = true,
        ---Extra mapping; `gco`, `gcO`, `gcA`
        extra = true,
      },
      ---Function to call before (un)comment
      pre_hook = nil,
      ---Function to call after (un)comment
      post_hook = nil,
    },
  },
  {
    "tpope/vim-fugitive",
    lazy = true,
  },
  {
    "ornfelt/gitgraph.nvim",
    dependencies = {
      "sindrets/diffview.nvim",
    },
    config = function()
      require("gitgraph").setup({
        symbols = {
          merge_commit = "M",
          commit = "*",
        },
        format = {
          timestamp = "%H:%M:%S %d-%m-%Y",
          fields = { "hash", "timestamp", "author", "branch_name", "tag" },
        },
        hooks = {
          on_select_commit = function(commit)
            vim.notify("DiffviewOpen " .. commit.hash .. "^!")
            vim.cmd(":DiffviewOpen " .. commit.hash .. "^!")
          end,
          on_select_range_commit = function(from, to)
            vim.notify("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
            vim.cmd(":DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
          end,
        },
      })
    end,
    lazy = true,
  },
  {
    "OXY2DEV/markview.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = is_raspbian,
  },
  {
    'adelarsq/image_preview.nvim',
    event = 'VeryLazy',
    config = function()
      require("image_preview").setup()
    end
  },
  -- "alexghergh/nvim-tmux-navigation"
  -- "mhinz/vim-startify"
  -- "mistweaverco/kulala.nvim"
  -- "3rd/diagram.nvim"
  -- "lewis6991/gitsigns.nvim"
  -- "mechatroner/rainbow_csv"
  -- "simrat39/rust-tools.nvim"
  -- "vim-syntastic/syntastic"
  -- "neoclide/coc.nvim"
  -- "fladson/vim-kitty"
  -- "kkharji/sqlite.lua"
  -- "folke/persistence.nvim"
  -- "denisenkom/go-mssqldb"
  -- "folke/which-key.nvim"
}

if is_raspbian then
  my_plugins = vim.tbl_filter(function(plugin)
    return plugin[1] ~= "OXY2DEV/markview.nvim"
  end, my_plugins)
end

require("lazy").setup(my_plugins , {
    install = {
      missing = true,
      colorscheme = { "gruvbox", "default" }, -- Fallback to default
    },
    checker = {
      enabled = true,
      notify = false,
    },
    change_detection = {
      enabled = true,
      notify = false,
    },
    ui = {
      -- border = "rounded"
    },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  }
)

