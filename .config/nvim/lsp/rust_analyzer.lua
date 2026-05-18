require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        --features = { "use_async", "with_imgui", "with_performance" },
        --features = { "use_sound", "threadsafe" },
        --features = { "winit29" },
        --features = { "gfxs" },
        allFeatures = true,
        --noDefaultFeatures = true,
      },

      --check = {
      --  features = { "use_async", "with_imgui", "with_performance" },
      --  --command = "clippy",
      --},
      --checkOnSave = { command = 'clippy' },
      diagnostics = { disabled = { 'inactive-code' } }, -- optional
    },
  },
}

