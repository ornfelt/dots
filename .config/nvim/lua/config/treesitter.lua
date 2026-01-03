local check_file_size = function(_, bufnr)
  return vim.api.nvim_buf_line_count(bufnr) > 100000
end

--local USE_TS_MAIN = false
local USE_TS_MAIN = true

-- master branch config
if not USE_TS_MAIN then
  require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = {
      'bash',
      'c',
      'c_sharp',
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
    auto_install = false,

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

  -- Register a new testing parser (templ)
  --local treesitter_parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  --treesitter_parser_config.templ = {
  --  install_info = {
  --    url = "https://github.com/vrischmann/tree-sitter-templ.git",
  --    files = {"src/parser.c", "src/scanner.c"},
  --    branch = "master",
  --  },
  --}
  --vim.treesitter.language.register("templ", "templ")

else
  -- main branch config
  local parsers = {
    "bash",
    "c",
    "c_sharp",
    "cpp",
    "css",
    "go",
    "graphql",
    "html",
    "java",
    "javascript",
    "jsdoc",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "php",
    "python",
    "query",
    "regex",
    "rust",
    "scss",
    "sql",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "vue",
    "yaml",
  }

  require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
  })

  -- main-branch replacement for ensure_installed/auto_install.
  -- It will no-op for already-installed parsers.
  require("nvim-treesitter").install(parsers)

  vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
      local bufnr = args.buf

      -- Skip TS entirely for big buffers
      if check_file_size(nil, bufnr) then
        return
      end

      -- Start highlighting (Neovim built-in)
      pcall(vim.treesitter.start, bufnr)

      -- Folding (Neovim built-in TS folding)
      --vim.wo.foldmethod = "expr"
      --vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

      -- Indentation
      --vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

      if vim.bo[bufnr].filetype == "markdown" then
        vim.bo[bufnr].syntax = "markdown"
      end
    end,
  })

  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = true,
      selection_modes = {
        ["@parameter.outer"] = "v",
        ["@function.outer"] = "V",
        ["@class.outer"] = "<c-v>",
      },
      include_surrounding_whitespace = true,
    },
  })

  vim.keymap.set({ "x", "o" }, "af", function()
    require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
  end)

  vim.keymap.set({ "x", "o" }, "if", function()
    require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
  end)

  vim.keymap.set({ "x", "o" }, "ac", function()
    require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
  end)

  vim.keymap.set({ "x", "o" }, "ic", function()
    require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
  end)

  vim.keymap.set({ "x", "o" }, "as", function()
    require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
  end)
end

--
-- Custom functions
--

--Test treesitter textobjects
function select_function_node_col_based(inner)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2] -- Convert to zero-indexed

  -- Get the current node at the cursor position
  local node = vim.treesitter.get_node({ buf = bufnr, pos = { row, col } })
  if not node then
    print("No node found under the cursor.")
    return
  end

  -- Find the ancestor node that is a function
  while node do
    if vim.tbl_contains({
      "function",              -- Generic function
      "function_definition",   -- Python/JavaScript
      "method_definition",     -- JavaScript/TypeScript
      "arrow_function",        -- JavaScript/TypeScript
      "function_declaration",  -- C, C++
      "class_method"           -- Ruby/Python
    }, node:type()) then
      break
    end
    node = node:parent()
  end

  if not node then
    print("No function node found.")
    return
  end

  -- Determine range to select
  local start_row, start_col, end_row, end_col
  if inner then
    -- Select inside function body
    local body = node:field("body")[1]
    if not body then
      print("No function body found.")
      return
    end
    start_row, start_col, end_row, end_col = body:range()
  else
    -- Select entire function (including its declaration)
    start_row, start_col, end_row, end_col = node:range()
  end

  -- Enter visual mode and select the range
  vim.api.nvim_buf_set_mark(bufnr, "<", start_row + 1, start_col, {})
  vim.api.nvim_buf_set_mark(bufnr, ">", end_row + 1, end_col, {})
  vim.cmd("normal! gv")
end

function select_function_node(inner)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local node = vim.treesitter.get_node({ buf = bufnr, pos = { row, col } })
  if not node then
    print("No node found under the cursor.")
    return
  end

  -- climb until we hit a function-like node
  while node do
    if vim.tbl_contains({
      "function",                       -- generic
      "function_definition",            -- python
      "function_declaration",           -- c, cpp, js, ts
      "method_declaration",             -- java, rust
      "function_expression",            -- js, ts
      "generator_function_declaration", -- js, ts
      "method_definition",              -- js, ts, java
      "function_item",                  -- rust
      "arrow_function",                 -- js, ts
      "class_method",                   -- ruby, python
    }, node:type()) then
      break
    end
    node = node:parent()
  end
  if not node then
    print("No function node found.")
    return
  end

  -- grab the raw start/end of either the body or the whole function
  local start_row, start_col, end_row, end_col
  if inner then
    local body = node:field("body")[1]
    if not body then
      print("No function body found.")
      return
    end
    start_row, start_col, end_row, end_col = body:range()

    -- Make sure we also select comments which might come before the function body
    local bc = body:range()  -- we already have body start in start_row
    local body_row = bc
    local earliest = start_row
    for i = 0, node:child_count() - 1 do
      local child = node:child(i)
      if child:type() == "comment" then
        local cr = child:range()  -- returns (row, col, row2, col2)
        if cr < earliest then
          earliest = cr
        end
      end
    end
    start_row = earliest

    -- special-case for C-style brace bodies
    local ft = vim.bo.filetype
    local brace_langs = {
      cpp         = true,
      cs          = true,
      java        = true,
      javascript  = true,
      jsx         = true,
      typescript  = true,
      tsx         = true,
      go          = true,
      rust        = true,
    }

    if brace_langs[ft] then
      -- fetch the very first line of the body (0-based start_row)
      local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
      -- trim trailing whitespace
      local trimmed = line:match("^(.-)%s*$")
      -- if it truly ends with '{', skip that entire line
      if trimmed:sub(-1) == "{" then
        start_row = start_row + 1
        end_row   = end_row   - 1
      end
    end

  else
    start_row, start_col, end_row, end_col = node:range()
  end

  -- linewise select from start_row to end_row
  local line_count = end_row - start_row
  vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
  vim.cmd("normal! V" .. line_count .. "j")
end

vim.api.nvim_set_keymap("n", "vif", ":lua select_function_node(true)<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "vaf", ":lua select_function_node(false)<CR>", { noremap = true, silent = true })

-- WIP: select inside or around a class-like treesitter node
function select_class_node(inner)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft   = vim.bo.filetype

  -- only for these filetypes
  local supported = { cpp=true, cs=true, java=true, python=true, go=true, rust=true, lua=true }
  if not supported[ft] then
    vim.notify("vic/vac: unsupported filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  -- get cursor in zero-based coords
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  -- find the smallest ancestor that is class-like
  local node = vim.treesitter.get_node({ buf = bufnr, pos = { row, col } })
  while node do
    if vim.tbl_contains({
        -- TS node types for class/struct/etc in various langs
        "class_declaration",               -- java, csharp, js, ts
        "class_expression",                -- js, ts inline
        "export_default_class_declaration",-- js, ts default exports
        "class_specifier",                 -- cpp
        "struct_specifier",                -- cpp
        "class_definition",                -- python
        "type_declaration",                -- go
        "struct_item",                     -- rust
        "impl_item",                       -- rust impl blocks
      }, node:type())
    then
      break
    end
    node = node:parent()
  end

  if not node then
    vim.notify("No class-like node found under the cursor.", vim.log.levels.INFO)
    return
  end

  -- determine the range
  local start_row, _, end_row, _

  if inner then
    -- try to grab the body (curly block or indent block)
    local bodies = node:field("body")
    if #bodies == 0 then
      vim.notify("Class node has no body to select.", vim.log.levels.INFO)
      return
    end
    local body = bodies[1]
    start_row, _, end_row, _ = body:range()
  else
    start_row, _, end_row, _ = node:range()
  end

  -- do a simple line-wise select
  local line_count = end_row - start_row
  vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
  vim.cmd("normal! V" .. line_count .. "j")
end

vim.api.nvim_set_keymap("n", "vic", ":lua select_class_node(true)<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "vac", ":lua select_class_node(false)<CR>", { noremap = true, silent = true })

-- WIP: copy current buffer but replace every function body with "..."
vim.api.nvim_create_user_command("SkeletonCopy", function(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft   = vim.bo.filetype
  local remove_comments = not opts.bang

  -- filetype -> treesitter language name
  local lang_map = {
    c           = "c",
    cpp         = "cpp",
    h           = "c",
    cs          = "c_sharp",
    python      = "python",
    go          = "go",
    rust        = "rust",
    lua         = "lua",
    java        = "java",
    js          = "javascript",
    javascript  = "javascript",
    jsx         = "javascript",
    ts          = "typescript",
    typescript  = "typescript",
    tsx         = "tsx",
  }
  local ts_lang = lang_map[ft]
  if not ts_lang then
    vim.notify(
      ":SkeletonCopy only supported on C/C++/C#/Python/Go/Rust/Lua/Java/JS/TS (got '" .. ft .. "')",
      vim.log.levels.WARN
    )
    return
  end

  -- per-language queries to capture function/method nodes
  local queries = {
    c         = [[ (function_definition) @func ]],
    cpp       = [[ (function_definition) @func ]],
    h         = [[ (function_definition) @func ]],
    c_sharp   = [[
      (method_declaration)      @func
      (constructor_declaration) @func
    ]],
    python    = [[ (function_definition) @func ]],
    go = [[
      (method_declaration)   @func
      (function_declaration) @func
    ]],
    rust      = [[ (function_item) @func ]],
    lua       = [[ 
      (function_declaration) @func 
    ]],
    java = [[
      (method_declaration)      @func
      (constructor_declaration) @func
    ]],
    javascript = [[
      (function_declaration) @func
      (method_definition)    @func
      (arrow_function)       @func
    ]],
    typescript = [[
      (function_declaration) @func
      (method_definition)    @func
      (arrow_function)       @func
    ]],
    tsx       = [[
      (function_declaration) @func
      (method_definition)    @func
      (arrow_function)       @func
    ]],
  }
  local qstr = queries[ts_lang]
  if not qstr then
    vim.notify("No query defined for TS language: " .. ts_lang, vim.log.levels.ERROR)
    return
  end

  -- grab all original lines
  local orig = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- treesitter setup
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, ts_lang)
  if not ok or not parser then
    vim.notify("Could not create TS parser for “" .. ts_lang .. "”", vim.log.levels.ERROR)
    return
  end
  local tree = parser:parse()[1]
  local root = tree:root()
  local tsq = vim.treesitter.query or vim.treesitter
  local parse = tsq.parse_query or tsq.parse
  if not parse then
    vim.notify("Treesitter query parser not available", vim.log.levels.ERROR)
    return
  end
  local query = parse(ts_lang, qstr)

  -- collect all function-body ranges
  local ranges = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "func" then
      local body = node:field("body")[1]
      if body then
        -- body:range() returns (start_row, start_col, end_row, end_col), ALL zero-based
        local sr, sc, er, ec = body:range()
        table.insert(ranges, { sr = sr, sc = sc, er = er, ec = ec })
      end
    end
  end

  -- sort descending by start_row so that earlier edits don't shift later ranges
  table.sort(ranges, function(a, b)
    if a.sr ~= b.sr then
      return a.sr > b.sr
    else
      -- if two bodies start on same line, put the one that ends later first
      return a.ec > b.ec
    end
  end)

  -- Apply skeleton replacement
  local out = vim.deepcopy(orig)

  for _, r in ipairs(ranges) do
    local sr, sc, er, ec = r.sr, r.sc, r.er, r.ec
    local first_line = out[sr + 1] -- Lua list is 1-based, sr is 0-based
    if sr == er then
      -- single-line function body (everything from col sc to ec on the same line)
      -- prefix = chars before the opening brace/indent
      local prefix = first_line:sub(1, sc)
      -- suffix = chars after the closing brace on that same line
      -- (ec is zero-based, so ec+1 is the last char in the body; the next char is ec+2 in 1-based)
      local suffix = first_line:sub(ec + 2)
      out[sr + 1] = prefix .. "..." .. suffix

    else
      -- multi-line function body
      -- First line: keep up to sc, then append "..."
      local prefix = first_line:sub(1, sc)

      -- Last line: keep from ec+1 onward
      local last_line = out[er + 1]
      local suffix = last_line:sub(ec + 2)

      -- Remove all the “middle” lines (and the original last line),
      --    i.e. lines (sr+2) .. (er+1) in 1-based indexing. We do this in reverse:
      for i = (er + 1), (sr + 2), -1 do
        table.remove(out, i)
      end

      out[sr + 1] = prefix .. "..."

      -- If there's a non-empty suffix on the last line, insert it right after
      if suffix ~= "" then
        table.insert(out, sr + 2, suffix)
      end
    end
  end

  if remove_comments then
    local filtered = {}
    for _, line in ipairs(out) do
      local trimmed = line:match("^%s*(.-)%s*$")
      local skip = false

      -- language-specific single‐line comment prefixes
      local single = {
        c           = "//",
        cpp         = "//",
        h           = "//",
        c_sharp     = "//",
        java        = "//",
        go          = "//",
        rust        = "//",
        javascript  = "//",
        typescript  = "//",
        tsx         = "//",
        python      = "#",
        lua         = "--",
      }

      -- skip if only a single-line comment
      local prefix = single[ts_lang]
      if prefix and trimmed:match("^" .. vim.pesc(prefix)) then
        skip = true
      end

      -- also skip block‐comment lines for JS/TS
      if not skip and (ts_lang == "javascript" or ts_lang == "typescript" or ts_lang == "tsx") then
        if trimmed:match("^/%*") or trimmed:match("^%*") or trimmed:match("%*/$") then
          skip = true
        end
      end

      if not skip then
        table.insert(filtered, line)
      end
    end
    out = filtered
  end

  -- yank to system clipboard
  vim.fn.setreg("+", table.concat(out, "\n"))
  vim.notify(
    ("Buffer skeleton %scopied to clipboard"):format(remove_comments and "(no comments) " or ""),
    vim.log.levels.INFO
  )
end, {
  bang = true,
  desc = "Copy buffer skeleton (replace bodies with '...'); use ! to drop comment‐only lines",
})

