require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  "seblyng/roslyn.nvim",
  ft = "cs",
  ---@module 'roslyn.config'
  ---@type RoslynNvimConfig
  opts = {
    -- your configuration comes here; leave empty for default settings
  },
}
