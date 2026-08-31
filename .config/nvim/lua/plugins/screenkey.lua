require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- screenkey derives its default row/col once, when its config module is first
-- loaded - if that happens before the UI is sized, the window ends up floating
-- near the middle. Re-pin it against the real UI size.
local function pin_to_bottom_right()
  local win_opts = require("screenkey.config").options.win_opts
  win_opts.row = vim.o.lines - vim.o.cmdheight - 1
  win_opts.col = vim.o.columns - 1
end

return {
  "NStefan002/screenkey.nvim",
  version = "*",
  cmd = "Screenkey",
  opts = {
    win_opts = {
      width = 30,
      height = 1,
    },
  },
  keys = {
    -- bind leader-tk: toggle screenkey (n)
    {
      "<leader>tk",
      function()
        pin_to_bottom_right()
        vim.cmd("Screenkey toggle")
      end,
      desc = "Screenkey: Toggle",
    },
  },
}
