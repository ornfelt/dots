local plugins = require("plugins")

require("lazy").setup(plugins, {
  install = {
    missing = true,
    colorscheme = { "gruvbox", "default" },
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
})

-- if on main branch...
--require("config.treesitter")

