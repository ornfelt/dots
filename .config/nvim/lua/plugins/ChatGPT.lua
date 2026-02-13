require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "ornfelt/ChatGPT.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "folke/trouble.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  event = "VeryLazy",
}
