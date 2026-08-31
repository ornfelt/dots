require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- lazy used `version = "*"` (latest tag). vim.pack has no direct equivalent
-- for "any tag"; defaulting to the upstream default branch instead.
return {
  src = "https://github.com/NStefan002/screenkey.nvim",
  config = function()
    -- screenkey derives its default row/col once, when its config module is
    -- first loaded - at that point the UI is still 80x24, which leaves the
    -- window floating near the middle. Re-pin it against the real UI size.
    local function pin_to_bottom_right()
      local win_opts = require("screenkey.config").options.win_opts
      win_opts.row = vim.o.lines - vim.o.cmdheight - 1
      win_opts.col = vim.o.columns - 1
    end

    require("screenkey").setup({
      win_opts = {
        width = 30,
        height = 1,
      },
    })
    pin_to_bottom_right()

    -- bind leader-tk: toggle screenkey (n)
    vim.keymap.set("n", "<leader>tk", function()
      pin_to_bottom_right()
      vim.cmd("Screenkey toggle")
    end, { desc = "Screenkey: Toggle" })
  end,
}
