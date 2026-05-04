require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/ornfelt/ChatGPT.nvim",
  dependencies = {
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/folke/trouble.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
  },
}
