require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- lazy used `version = "*"` (latest tag). vim.pack has no direct equivalent
-- for "any tag"; defaulting to the upstream default branch instead.
return {
  src = "https://github.com/dlyongemallo/diffview.nvim",
}
