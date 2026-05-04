require('dbg_log').log_file(debug.getinfo(1, 'S').source)

return {
  src = "https://github.com/saghen/blink.cmp",
  -- "1.*" in lazy → semver range >=1.0.0 <2.0.0 for vim.pack
  version = vim.version.range("1"),
  dependencies = {
    "https://github.com/rafamadriz/friendly-snippets",
  },
  config = function()
    require('blink.cmp').setup({
      keymap = {
        preset = 'default',
        ['<Tab>']   = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Up>']    = { 'select_next', 'fallback' },
        ['<Down>']  = { 'select_prev', 'fallback' },
        ['<CR>']    = { 'accept', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    })
  end,
}
