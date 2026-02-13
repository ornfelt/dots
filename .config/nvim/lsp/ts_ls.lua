require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  -- lspconfig renamed tsserver -> ts_ls; cmd is still the Typescript LSP
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = {
    'javascript', 'javascriptreact', 'javascript.jsx',
    'typescript', 'typescriptreact', 'typescript.tsx',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  settings = {
    -- TODO: Place per-language settings here
  },
}

