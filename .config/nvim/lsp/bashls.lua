require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  cmd = { 'bash-language-server', 'start' },
  filetypes = { 'sh', 'bash' },
  root_markers = { '.git' },
}

