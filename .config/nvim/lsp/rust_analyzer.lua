require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      cargo = { allFeatures = true },
      --checkOnSave = { command = 'clippy' },
      diagnostics = { disabled = { 'inactive-code' } }, -- optional
    },
  },
}

