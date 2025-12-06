local myconfig = require('myconfig')

----local autocomplete = require("autocomplete")
--
--vim.api.nvim_create_autocmd('LspAttach', {
--  desc = 'LSP actions',
--  callback = function(event)
--
--    --autocomplete.setup(event)
--
--    local opts = { buffer = event.buf, noremap = true, silent = true }
--
--    vim.keymap.set('n', '<M-r>', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
--    vim.keymap.set('n', '<M-d>', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
--    vim.keymap.set('n', '<M-s-D>', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
--    --vim.keymap.set('n', '<M-s-d>', '', { noremap = true, silent = true, callback = go_to_definition_twice })
--    vim.keymap.set('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
--    vim.keymap.set('n', '<leader>lr', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
--    vim.keymap.set('n', '<leader>lh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
--    vim.keymap.set('n', '<leader>lo', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
--    vim.keymap.set('n', '<leader>ld', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
--    vim.keymap.set('n', '<leader>lc', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
--
--    --vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
--    --vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
--  end,
--})
--
---- blink.cmp
--local capabilities = {
--  textDocument = {
--    foldingRange = {
--      dynamicRegistration = false,
--      lineFoldingOnly = true,
--    },
--  },
--}
--
--capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
--
--vim.lsp.config('*', {
--  capabilities = capabilities,
--  root_markers = { '.git' },
--})
--
---- Enable servers
----vim.lsp.enable({'clangd', 'gopls', 'rust-analyzer'})
--
---- Automatically enable LSP for all lsp files found in my runtimepath
--local configs = {}
--
--for _, v in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do
--  local name = vim.fn.fnamemodify(v, ':t:r')
--  configs[name] = true
--end
--
--vim.lsp.enable(vim.tbl_keys(configs))
--
---- Completion (see autocomplete instead)
----vim.api.nvim_create_autocmd('LspAttach', {
----  callback = function(ev)
----    local client = vim.lsp.get_client_by_id(ev.data.client_id)
----    if client:supports_method('textDocument/completion') then
----      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
----    end
----  end,
----})
--
---- toggle LSP for the current buffer
----vim.keymap.set('n', '<F10>', function()
----  -- clients active for the current buffer
----  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
----
----  if vim.tbl_isempty(clients) then
----    vim.cmd("LspStart")
----  else
----    vim.cmd("LspStop")
----  end
----end)

-- NEW (above is deprecated)

-- for testing custom lsp
if not myconfig.should_use_custom_lsp_for_sql() then
  vim.filetype.add({
    extension = { csql = "csql" },
  })
end

-- Keymaps on LSP attach (replaces on_attach)
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local buf = event.buf
    local opts = { buffer = buf, noremap = true, silent = true }

    local function go_to_definition_twice()
      vim.lsp.buf.definition()
      vim.defer_fn(function() vim.lsp.buf.definition() end, 100)
    end

    vim.keymap.set('n', '<M-r>', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<M-d>', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<M-s-D>', vim.lsp.buf.implementation, opts)
    -- vim.keymap.set('n', '<M-s-d>', go_to_definition_twice, opts)
    vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>lh', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>lo', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>ld', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>lc', vim.lsp.buf.declaration, opts)
  end,
})

-- Hover-on-CursorHold toggle (keeps your previous behavior)
local enabled_filetypes = {
  bash=true, c=true, cpp=true, css=true, go=true, graphql=true, html=true,
  java=true, javascript=true, jsdoc=true, json=true, lua=true,
  markdown=true, markdown_inline=true, php=true, python=true, query=true,
  regex=true, rust=true, scss=true, sql=true, tsx=true, typescript=true,
  vim=true, vimdoc=true, vue=true, yaml=true,
}

local hover_enabled = false
function _G.toggle_hover()
  hover_enabled = not hover_enabled
  print(hover_enabled and "Hover enabled" or "Hover disabled")
end

vim.api.nvim_set_keymap("n", "<leader>lot", "<cmd>lua toggle_hover()<CR>", { noremap=true, silent=true })
vim.api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  desc = "Show LSP hover on CursorHold for specific filetypes",
  callback = function()
    if hover_enabled and enabled_filetypes[vim.bo.filetype] then
      vim.lsp.buf.hover()
    end
  end,
})

-- Capabilities (blink.cmp)
--local capabilities = {
--  textDocument = {
--    foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
--  },
--}
--capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)

-- nvim-cmp:
vim.o.completeopt = "menu,menuone,noselect"

local cmp = require('cmp')

cmp.setup({
  -- If you actually use snippets (recommended), keep this enabled:
  snippet = {
    expand = function(args)
      -- Preferred snippet engine:
      --vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>']     = cmp.mapping.scroll_docs(-4),
    ['<C-f>']     = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.abort(),
    ['<CR>']      = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item() else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item() else fallback() end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- switch to 'luasnip' / 'ultisnips' / 'snippy' if you prefer
  }, {
    { name = 'buffer' },
  }),
})

-- Optional: filetype-specific sources
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({ { name = 'cmp_git' } }, { { name = 'buffer' } })
})

-- Optional: commandline completion
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = 'buffer' } }
})
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    -- { name = 'path' }
  }, { { name = 'cmdline' } })
})

-- === Capabilities from nvim-cmp (replaces Blink) ===
local capabilities = require('cmp_nvim_lsp')
  .default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Global defaults for all servers (you can add more defaults here)
vim.lsp.config('*', {
  capabilities = capabilities,
  root_markers = { '.git' },
  -- single_file_support = true, -- enable if you want single files attached by default
})

-- Auto-register EVERY config file under runtimepath/lsp/*.lua
--local found = {}
--for _, path in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do
--  local name = vim.fn.fnamemodify(path, ':t:r')
--  found[name] = true
--end
--
--local to_enable = {}
--for name in pairs(found) do
--  local cfg = vim.lsp.config(name) or {}
--  local cmd = cfg.cmd
--  local ok = true
--  if type(cmd) == 'table' and cmd[1] and cmd[1] ~= '' then
--    ok = (vim.fn.executable(cmd[1]) == 1)
--  end
--  if ok then table.insert(to_enable, name) end
--end

-- Discover lsp/* files, check executables, register + enable

-- Logging setup
local log_lines = {}
local function log(fmt, ...)
  local line = string.format(fmt, ...)
  table.insert(log_lines, line)
  -- also echo in :messages for quick feedback:
  --vim.schedule(function() vim.notify(line, vim.log.levels.INFO) end)
end

-- log target
local logfile = (vim.fn.has('win32') == 1) and [[C:\local\lsp_servers.txt]] or (vim.fn.expand('~/lsp_servers.txt'))

if vim.fn.has('win32') == 1 then
  vim.fn.mkdir(vim.fn.fnamemodify(logfile, ':h'), 'p')
end

-- Choose what to scan
local user_glob = vim.fn.stdpath('config') .. '/lsp/*.lua'
-- Debug path
--print(user_glob)

local paths = vim.split(vim.fn.glob(user_glob, true), '\n', { plain = true })
local enabled = {}
local use_custom_sql = myconfig.should_use_custom_lsp_for_sql()

for _, path in ipairs(paths) do
  if path ~= '' then
    if use_custom_sql and path:lower():match("sqls%.lua") then
      log("SKIPPED %-24s  (UseCustomLspForSql is enabled)   [%s]", "sqls", path)
      goto continue
    end

    local name = vim.fn.fnamemodify(path, ':t:r')

    local ok, cfg = pcall(dofile, path)
    if not ok or type(cfg) ~= 'table' then
      log("INVALID %-24s  (config file didn't return a table) [%s]", name, path)
    else
      local cmd = cfg.cmd
      local ok_exec = true
      if type(cmd) == 'table' and cmd[1] and cmd[1] ~= '' then
        ok_exec = (vim.fn.executable(cmd[1]) == 1)
      end
      if ok_exec then
        vim.lsp.config(name, cfg)      -- register
        table.insert(enabled, name)    -- mark for enable
        log("READY  %-24s  (will enable)                [%s]", name, path)
      else
        log("MISSING %-24s  (binary '%s' not found)      [%s]", name, tostring(cmd and cmd[1] or ""), path)
      end
    end

    ::continue::
  end
end

if #enabled > 0 then
  vim.lsp.enable(enabled)
  log("ENABLED: %s", table.concat(enabled, ", "))
else
  log("ENABLED: (none)")
end

vim.fn.writefile(log_lines, logfile)
log("Wrote LSP registration log to: %s", logfile)

