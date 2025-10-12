return {
  cmd = { 'jdtls' },
  filetypes = { 'java' },
  -- jdtls typically wants a per-workspace data dir; if you have one, add:
  -- cmd = { 'jdtls', '-data', vim.fn.stdpath('cache') .. '/jdtls/' .. vim.fn.fnamemodify(vim.loop.cwd(), ':p:h:t') },
  root_markers = { 'pom.xml', 'gradle.build', '.git' },
}

