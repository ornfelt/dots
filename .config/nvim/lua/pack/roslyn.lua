require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- lazy: ft = "cs". roslyn.nvim's setup() registers a FileType cs autocmd
-- internally, so eager setup here is functionally equivalent.
return {
  src = "https://github.com/seblyng/roslyn.nvim",
  config = function()
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    require("roslyn").setup({
      -- your configuration comes here; leave empty for default settings
    })
  end,
}
