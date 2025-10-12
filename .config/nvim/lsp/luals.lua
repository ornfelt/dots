return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim', 'use' } },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
        ignoreDir = { "build","node_modules","third_party",".git","AppData","Application Data","scoop",".vim" },
      },
      telemetry = { enable = false },
    },
  },
}

