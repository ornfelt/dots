require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  cmd = { 'fsautocomplete', '--adaptive-lsp-server-enabled' },
  filetypes = { 'fsharp' },
  root_markers = { 'paket.dependencies', 'Directory.Build.props', '.git' },
}

