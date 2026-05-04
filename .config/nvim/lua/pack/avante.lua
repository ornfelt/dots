require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/stevearc/dressing.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    --"https://github.com/echasnovski/mini.pick", -- for file_selector provider mini.pick
    --"https://github.com/nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    --"https://github.com/hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    --"https://github.com/ibhagwan/fzf-lua", -- for file_selector provider fzf
    --"https://github.com/nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --"https://github.com/zbirenbaum/copilot.lua", -- for providers='copilot'
    --"https://github.com/HakonHarnes/img-clip.nvim", -- support for image pasting
    --"https://github.com/MeanderingProgrammer/render-markdown.nvim",
  },
  config = function()
    -- Original opts (config.avante does the actual setup, same as the lazy version):
    --   provider = "openai"
    --   openai = {
    --     endpoint = "https://api.openai.com/v1",
    --     model = "gpt-4o",
    --     timeout = 30000,
    --     temperature = 0,
    --     max_tokens = 8192,
    --     -- reasoning_effort = "medium",
    --   }
    require("config.avante")
  end,
}
