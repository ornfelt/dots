local check_file_size = function(_, bufnr)
  return vim.api.nvim_buf_line_count(bufnr) > 100000
end

require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = {
        'bash',
        'c',
        'cpp',
        'css',
        'go',
        'graphql',
        'html',
        'java',
        'javascript',
        'jsdoc',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'php',
        'python',
        'query',
        'regex',
        'rust',
        'scss',
        'sql',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'vue',
        'yaml',
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    indent = {
        enable = true
    },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,
        disable = check_file_size,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = { "markdown" },
    },
    incremental_selection = {
        enable = true, -- Enable incremental selection
    },
    textobjects = {
        select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                -- You can optionally set descriptions to the mappings (used in the desc parameter of
                -- nvim_buf_set_keymap) which plugins like which-key display
                ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                -- You can also use captures from other query groups like `locals.scm`
                ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
                ['@parameter.outer'] = 'v', -- charwise
                ['@function.outer'] = 'V', -- linewise
                ['@class.outer'] = '<c-v>', -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true or false
            include_surrounding_whitespace = true,
        },
    },
})

--local treesitter_parser_config = require("nvim-treesitter.parsers").get_parser_configs()
--treesitter_parser_config.templ = {
--    install_info = {
--        url = "https://github.com/vrischmann/tree-sitter-templ.git",
--        files = {"src/parser.c", "src/scanner.c"},
--        branch = "master",
--    },
--}
--
--vim.treesitter.language.register("templ", "templ")

-- Test treesitter textobjects
--function select_function_node(inner)
--  local bufnr = vim.api.nvim_get_current_buf()
--  local cursor = vim.api.nvim_win_get_cursor(0)
--  local row, col = cursor[1] - 1, cursor[2] -- Convert to zero-indexed
--
--  -- Get the current node at the cursor position
--  local node = vim.treesitter.get_node({ buf = bufnr, pos = { row, col } })
--  if not node then
--    print("No node found under the cursor.")
--    return
--  end
--
--  -- Find the ancestor node that is a function
--  while node do
--    if vim.tbl_contains({
--      "function",              -- Generic function
--      "function_definition",   -- Python/JavaScript
--      "method_definition",     -- JavaScript/TypeScript
--      "arrow_function",        -- JavaScript/TypeScript
--      "function_declaration",  -- C, C++
--      "class_method"           -- Ruby/Python
--    }, node:type()) then
--      break
--    end
--    node = node:parent()
--  end
--
--  if not node then
--    print("No function node found.")
--    return
--  end
--
--  -- Determine range to select
--  local start_row, start_col, end_row, end_col
--  if inner then
--    -- Select inside function body
--    local body = node:field("body")[1]
--    if not body then
--      print("No function body found.")
--      return
--    end
--    start_row, start_col, end_row, end_col = body:range()
--  else
--    -- Select entire function (including its declaration)
--    start_row, start_col, end_row, end_col = node:range()
--  end
--
--  -- Enter visual mode and select the range
--  vim.api.nvim_buf_set_mark(bufnr, "<", start_row + 1, start_col, {})
--  vim.api.nvim_buf_set_mark(bufnr, ">", end_row + 1, end_col, {})
--  vim.cmd("normal! gv")
--end
--
--vim.api.nvim_set_keymap("n", "vif", ":lua select_function_node(true)<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap("n", "vaf", ":lua select_function_node(false)<CR>", { noremap = true, silent = true })

