require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/aaronik/treewalker.nvim",
  config = function()
    -- The following options are the defaults.
    -- (Not applied here because the original lazy spec's `config` function
    --  also bypasses opts and just defers to the user's config.treewalker.)
    --   highlight = true,
    --   highlight_duration = 250,
    --   highlight_group = 'CursorLine',
    require("config.treewalker")
  end,
}

