require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        --features = { "async", "cimgui", "with_performance" },
        allFeatures = true,
        --noDefaultFeatures = true,
      },

      --check = {
      --  features = { "async", "cimgui", "with_performance" },
      --  --command = "clippy",
      --},
      --checkOnSave = { command = 'clippy' },
      diagnostics = { disabled = { 'inactive-code' } }, -- optional
    },
  },
}

