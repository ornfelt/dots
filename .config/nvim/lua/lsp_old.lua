require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local lspconfig = require'lspconfig'

local function go_to_definition_twice()
  vim.lsp.buf.definition()
  vim.defer_fn(function() vim.lsp.buf.definition() end, 100)
end

local on_attach = function(client, bufnr)
  -- Create a buffer-local keymap function
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  buf_set_keymap('n', '<M-r>', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<M-d>', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<M-s-D>', '<cmd>lua vim.lsp.buf.implementation()<CR>', { noremap = true, silent = true })
  --buf_set_keymap('n', '<M-s-d>', '', { noremap = true, silent = true, callback = go_to_definition_twice })
  buf_set_keymap('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<leader>lr', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<leader>lh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<leader>lo', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<leader>ld', '<cmd>lua vim.lsp.buf.type_definition()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<leader>lc', '<cmd>lua vim.lsp.buf.declaration()<CR>', { noremap = true, silent = true })
  buf_set_keymap('n', '<leader>ls', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', { noremap = true, silent = true })
end

vim.keymap.set('n', '<M-r>', '<cmd>lua vim.lsp.buf.references()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-d>', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-s-D>', '<cmd>lua vim.lsp.buf.implementation()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lr', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lo', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>ld', '<cmd>lua vim.lsp.buf.type_definition()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lc', '<cmd>lua vim.lsp.buf.declaration()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>ls', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', { noremap = true, silent = true })

-- Python language server
--require'lspconfig'.pyright.setup {
--    on_attach = on_attach,
--}

-- C/C++ language server
--require'lspconfig'.clangd.setup {
--    on_attach = on_attach,
--    -- Clangd-specific settings
--    -- cmd = { "clangd", "--background-index" },
--    -- Configure flags, headers, or other clangd-specific options...
--}

-- Java language server
--require'lspconfig'.jdtls.setup {
--    on_attach = on_attach,
--    -- Note: jdtls might require more complex configuration especially for workspace handling
--    -- and Java project management compared to other simpler LSP setups.
--    -- root_dir = function() return vim.fn.getcwd() end,
--}

-- Setup language server if its binary is available
local function setup_lsp_if_available(server_name, config, binary_name)
  binary_name = binary_name or server_name

  if vim.fn.executable(binary_name) == 1 then
    require'lspconfig'[server_name].setup(config)
    --else
    --    print(binary_name .. " is not installed or not found in PATH")
  end
end

local lsp_attach_config = {
  on_attach = on_attach,
}

local lua_ls_config = {
  on_attach = on_attach,
  root_dir = function(fname)
    local util = require("lspconfig.util")

    local git = util.find_git_ancestor(fname)
    if git then
      return git
    end

    --local root_pattern = require("lspconfig.util").root_pattern(
    --  ".luarc.json",
    --  ".luarc.jsonc",
    --  ".luacheckrc",
    --  ".stylua.toml",
    --  "stylua.toml",
    --  "selene.toml",
    --  "selene.yml",
    --  ".git"
    --)
    ----return root_pattern(fname) or vim.fn.getcwd()
    --return root_pattern(fname) or util.path.dirname(fname)

    -- Debug:
    --:lua print(vim.inspect(require("lspconfig").lua_ls.document_config.default_config.root_dir(vim.fn.expand("%:p"))))

    -- fallback to just the file's directory
    -- return vim.fn.fnamemodify(fname, ":p:h")
    -- This should be the same:
    return util.path.dirname(fname)
  end,
  single_file_support = true,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim', 'use' }
      },
      workspace = {
        -- Make the server aware of Neovim runtime files and plugins
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
        ignoreDir = {
          "build",
          "node_modules",
          "third_party",
          ".git",
          "AppData",
          "Application Data",
          "scoop",
          ".vim"
        },
      },
    },
  }
}

setup_lsp_if_available('pyright', lsp_attach_config)
setup_lsp_if_available('clangd', lsp_attach_config)
setup_lsp_if_available('gopls', lsp_attach_config)
setup_lsp_if_available('ts_ls', lsp_attach_config, 'tsserver')
setup_lsp_if_available('fsautocomplete', lsp_attach_config)
setup_lsp_if_available('jdtls', lsp_attach_config)
-- lua_ls isn't the executable, lua-language-server is
setup_lsp_if_available('lua_ls', lua_ls_config, 'lua-language-server')
-- rust_analyzer isn't the executable, rust-analyzer is
setup_lsp_if_available('rust_analyzer', lsp_attach_config, 'rust-analyzer')
-- bashls isn't the executable, bash-language-server is
setup_lsp_if_available('bashls', lsp_attach_config, 'bash-language-server')

if vim.fn.has('win32') == 1 then
  if vim.fn.executable('wsl') == 1 then
    lspconfig.phpactor.setup{
      --cmd = { "ssh", "user@remotehost", "phpactor", "language-server" },
      --cmd = { "wsl", "-d", "arch", "alias C:='/mnt/c'", "phpactor", "language-server" },
      cmd = { "wsl", "-d", "arch", "phpactor", "language-server" },
      on_attach = on_attach
    }
  end
else
  setup_lsp_if_available('phpactor', lsp_attach_config)
end

if vim.fn.executable("sqls") == 1 then
  lspconfig.sqls.setup{
    on_attach = function(client, bufnr)
      require('sqls').on_attach(client, bufnr)
      on_attach(client, bufnr)
    end
  }
end

if vim.fn.executable("yaml-language-server") == 1 then
  lspconfig.yamlls.setup {
    settings = {
      yaml = {
        schemas = {
          ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml",
          -- other schemas...
        },
      },
    }
  }
end

--local omnisharp_path = os.getenv('OMNISHARP_PATH')
--if omnisharp_path then
--  local cmd
--
--  if vim.fn.has('unix') == 1 then
--    cmd = { "dotnet", omnisharp_path .. "/OmniSharp.dll" }
--  else
--    cmd = { omnisharp_path .. "/OmniSharp.exe", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
--  end
--
--  require'lspconfig'.omnisharp.setup {
--    on_attach = on_attach,
--    cmd = cmd,
--    settings = {
--      FormattingOptions = {
--        -- Enables support for reading code style, naming convention and analyzer
--        -- settings from .editorconfig.
--        EnableEditorConfigSupport = true,
--        -- Specifies whether 'using' directives should be grouped and sorted during
--        -- document formatting.
--        OrganizeImports = nil,
--      },
--      MsBuild = {
--        -- If true, MSBuild project system will only load projects for files that
--        -- were opened in the editor. This setting is useful for big C# codebases
--        -- and allows for faster initialization of code navigation features only
--        -- for projects that are relevant to code that is being edited. With this
--        -- setting enabled OmniSharp may load fewer projects and may thus display
--        -- incomplete reference lists for symbols.
--        LoadProjectsOnDemand = nil,
--      },
--      RoslynExtensionsOptions = {
--        -- Enables support for roslyn analyzers, code fixes and rulesets.
--        EnableAnalyzersSupport = nil,
--        -- Enables support for showing unimported types and unimported extension
--        -- methods in completion lists. When committed, the appropriate using
--        -- directive will be added at the top of the current file. This option can
--        -- have a negative impact on initial completion responsiveness,
--        -- particularly for the first few completion sessions after opening a
--        -- solution.
--        EnableImportCompletion = nil,
--        -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
--        -- true
--        AnalyzeOpenDocumentsOnly = nil,
--      },
--      Sdk = {
--        -- Specifies whether to include preview versions of the .NET SDK when
--        -- determining which version to use for project loading.
--        IncludePrereleases = true,
--      },
--    },
--  }
--end
-- Use roslyn instead of omnisharp:
-- {conf_dir}/nvim/lua/plugins/roslyn.lua

if vim.fn.has('win32') == 1 then
  local binary_name = 'powershell.exe'
  local user_profile = vim.loop.os_getenv("USERPROFILE")
  local bundle_path = user_profile .. '/Downloads/PowerShellEditorServices'

  local ps_attach_config = {
    on_attach = on_attach,
    bundle_path = bundle_path,
    shell = binary_name,
  }

  if vim.fn.executable(binary_name) == 1 and vim.fn.isdirectory(bundle_path) == 1 then
    lspconfig.powershell_es.setup(ps_attach_config)
  end
end

-- Setup nvim-cmp.
local cmp = require'cmp'

cmp.setup({
  --snippet = {
  --  -- REQUIRED - you must specify a snippet engine
  --  expand = function(args)
  --    vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
  --    -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
  --    -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
  --    -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
  --  end,
  --},
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    -- Use Tab and Shift-Tab to browse through the suggestions.
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
        -- elseif vim.fn["vsnip#available"](1) == 1 then
        -- feedkey("<Plug>(vsnip-expand-or-jump)", "")
        -- elseif has_words_before() then
        -- cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
        -- elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        -- feedkey("<Plug>(vsnip-jump-prev)", "")
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
      { name = 'buffer' },
    })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'cmp_git' },
  }, {
      { name = 'buffer' },
    })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    -- { name = 'path' }
  }, {
      { name = 'cmdline' }
    })
})

-- Setup lspconfig (line below deprecated)
-- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
-- require('lspconfig')['<YOUR_LSP_SERVER>'].setup {
-- capabilities = capabilities
-- }

--
-- LSP hover keybind/autocmd
--
--vim.o.updatetime = 1000
local enabled_filetypes = {
    bash = true,
    c = true,
    cpp = true,
    css = true,
    go = true,
    graphql = true,
    html = true,
    java = true,
    javascript = true,
    jsdoc = true,
    json = true,
    lua = true,
    markdown = true,
    markdown_inline = true,
    php = true,
    python = true,
    query = true,
    regex = true,
    rust = true,
    scss = true,
    sql = true,
    tsx = true,
    typescript = true,
    vim = true,
    vimdoc = true,
    vue = true,
    yaml = true,
}

local hover_enabled = false
function toggle_hover()
    hover_enabled = not hover_enabled
    if hover_enabled then
        print("Hover enabled")
    else
        print("Hover disabled")
    end
end

vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*", -- Apply to all files initially
    callback = function()
        if hover_enabled and enabled_filetypes[vim.bo.filetype] then
            vim.lsp.buf.hover()
        end
    end,
    desc = "Show LSP hover information on CursorHold for specific filetypes",
})

-- leader-lo to enable manually. Press again or <C-w><C-w> to go into hover-window
vim.api.nvim_set_keymap( "n", "<leader>lot", "<cmd>lua toggle_hover()<CR>", { noremap = true, silent = true })

