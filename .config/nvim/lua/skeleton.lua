require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- Shared skeletonization module.
local M = {}

-- filetype -> treesitter language name
M.lang_map = {
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

-- ts_lang -> vim filetype (for temp buffer creation)
M.ft_for_ts_lang = {
  c           = "c",
  cpp         = "cpp",
  c_sharp     = "cs",
  python      = "python",
  go          = "go",
  rust        = "rust",
  lua         = "lua",
  java        = "java",
  javascript  = "javascript",
  typescript  = "typescript",
  tsx         = "typescriptreact",
}

-- per-language treesitter queries to capture function/method nodes
M.queries = {
  c         = [[ (function_definition) @func ]],
  cpp       = [[ (function_definition) @func ]],
  c_sharp   = [[
    (method_declaration)                @func
    (constructor_declaration)           @func
    (destructor_declaration)            @func
    (operator_declaration)              @func
    (conversion_operator_declaration)   @func
    (local_function_statement)          @func
    (property_declaration)              @func
    (indexer_declaration)               @func
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

-- single-line comment prefixes per ts language
M.comment_prefixes = {
  c           = "//",
  cpp         = "//",
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

-- languages that use /* */ block comments
M.block_comment_langs = {
  c           = true,
  cpp         = true,
  c_sharp     = true,
  java        = true,
  go          = true,
  rust        = true,
  javascript  = true,
  typescript  = true,
  tsx         = true,
}

--- Get the body node for a function/method/property node.
--- Handles normal bodies, block children, and C# expression-bodied members.
function M.get_node_body(node)
  -- Normal function body field
  local body = node:field("body")[1]
  if body then
    return body
  end

  -- Fallback: find a direct block child
  for child in node:iter_children() do
    if child:named() and child:type() == "block" then
      return child
    end
  end

  -- Expression-bodied members (C#): public int X() => 123;
  for child in node:iter_children() do
    if child:named() and child:type() == "arrow_expression_clause" then
      return child
    end
  end

  return nil
end

--- Check if range `a` fully contains range `b`.
local function range_contains(a, b)
  local a_starts_before_or_same =
    a.sr < b.sr or (a.sr == b.sr and a.sc <= b.sc)
  local a_ends_after_or_same =
    a.er > b.er or (a.er == b.er and a.ec >= b.ec)
  return a_starts_before_or_same and a_ends_after_or_same
end

--- Separate ranges into outer (to process) and nested (metadata-only).
--- Returns outer_ranges, nested_ranges.
local function separate_ranges(ranges)
  -- Sort ascending by start, widest first for ties
  table.sort(ranges, function(a, b)
    if a.sr ~= b.sr then return a.sr < b.sr end
    if a.sc ~= b.sc then return a.sc < b.sc end
    if a.er ~= b.er then return a.er > b.er end
    return a.ec > b.ec
  end)

  local outer = {}
  local nested_list = {}

  for _, r in ipairs(ranges) do
    local is_nested = false
    for _, existing in ipairs(outer) do
      if range_contains(existing, r) then
        is_nested = true
        break
      end
    end
    if is_nested then
      table.insert(nested_list, r)
    else
      table.insert(outer, r)
    end
  end

  return outer, nested_list
end

--- Remove comment-only lines for a given ts language.
local function remove_comment_lines(lines, ts_lang)
  local filtered = {}
  local prefix = M.comment_prefixes[ts_lang]
  local has_block = M.block_comment_langs[ts_lang]

  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    local skip = false

    if prefix and trimmed:match("^" .. vim.pesc(prefix)) then
      skip = true
    end

    if not skip and has_block then
      if trimmed:match("^/%*") or trimmed:match("^%*") or trimmed:match("%*/$") then
        skip = true
      end
    end

    if not skip then
      table.insert(filtered, line)
    end
  end

  return filtered
end

--- Core skeletonization.
---@param lines string[] source lines
---@param ts_lang string treesitter language name (e.g. "c_sharp", "lua")
---@param opts? table { remove_comments=bool, include_meta=bool, source_path=string }
---@return table { lines=string[], meta=table|nil }
function M.skeletonize(lines, ts_lang, opts)
  opts = opts or {}
  local do_remove_comments = opts.remove_comments ~= false
  local include_meta = opts.include_meta or false
  local source_path = opts.source_path or "[buffer]"

  local qstr = M.queries[ts_lang]
  if not qstr then
    error("No skeleton query defined for TS language: " .. ts_lang)
  end

  -- Create a temporary buffer for treesitter parsing
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local ft = M.ft_for_ts_lang[ts_lang]
  if ft then
    vim.bo[bufnr].filetype = ft
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, ts_lang)
  if not ok or not parser then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    error("Could not create TS parser for \"" .. ts_lang .. "\": " .. source_path)
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local tsq = vim.treesitter.query or vim.treesitter
  local parse_fn = tsq.parse_query or tsq.parse
  if not parse_fn then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    error("Treesitter query parser not available")
  end

  local query = parse_fn(ts_lang, qstr)

  -- Collect all function-body ranges
  local all_ranges = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "func" then
      local body = M.get_node_body(node)
      if body then
        local sr, sc, er, ec = body:range()
        table.insert(all_ranges, { sr = sr, sc = sc, er = er, ec = ec })
      end
    end
  end

  vim.api.nvim_buf_delete(bufnr, { force = true })

  -- Separate outer vs nested ranges
  local outer_ranges, nested_ranges = separate_ranges(all_ranges)

  -- Sort outer ranges descending so edits don't shift earlier ranges
  table.sort(outer_ranges, function(a, b)
    if a.sr ~= b.sr then return a.sr > b.sr end
    return a.sc > b.sc
  end)

  -- Apply skeleton replacement
  local out = vim.deepcopy(lines)
  local meta_entries = {}
  local meta_idx = 0

  -- Record nested ranges as metadata-only (null skeleton_line)
  for _, r in ipairs(nested_ranges) do
    table.insert(meta_entries, {
      original_start = r.sr + 1,
      original_end = r.er + 1,
      marker = nil,
    })
  end

  for _, r in ipairs(outer_ranges) do
    local sr, sc, er, ec = r.sr, r.sc, r.er, r.ec
    local first_line = out[sr + 1]
    if not first_line then goto continue end

    meta_idx = meta_idx + 1
    local placeholder = include_meta and ("...##SKEL:" .. meta_idx .. "##") or "..."

    if sr == er then
      local prefix = first_line:sub(1, sc)
      local suffix = first_line:sub(ec + 2)
      out[sr + 1] = prefix .. placeholder .. suffix
    else
      local last_line = out[er + 1]
      if not last_line then goto continue end

      local prefix = first_line:sub(1, sc)
      local suffix = last_line:sub(ec + 2)

      for i = er + 1, sr + 2, -1 do
        table.remove(out, i)
      end

      out[sr + 1] = prefix .. placeholder

      if suffix ~= "" then
        table.insert(out, sr + 2, suffix)
      end
    end

    table.insert(meta_entries, {
      original_start = r.sr + 1,
      original_end = r.er + 1,
      marker = meta_idx,
    })

    ::continue::
  end

  -- Remove comment-only lines
  if do_remove_comments then
    out = remove_comment_lines(out, ts_lang)
  end

  -- Build metadata
  local meta = nil
  if include_meta then
    -- Resolve markers to skeleton line numbers, then strip them
    local marker_to_line = {}
    for i, line in ipairs(out) do
      local id = line:match("%.%.%.##SKEL:(%d+)##")
      if id then
        marker_to_line[tonumber(id)] = i
        out[i] = line:gsub("##SKEL:%d+##", "")
      end
    end

    -- Sort ascending by original line
    table.sort(meta_entries, function(a, b) return a.original_start < b.original_start end)

    local replacements = {}
    for _, entry in ipairs(meta_entries) do
      table.insert(replacements, {
        original_start = entry.original_start,
        original_end = entry.original_end,
        skeleton_line = entry.marker and marker_to_line[entry.marker] or vim.NIL,
      })
    end

    meta = {
      file = source_path,
      language = ts_lang,
      original_line_count = #lines,
      skeleton_line_count = #out,
      comments_removed = do_remove_comments,
      replacements = replacements,
    }
  end

  return { lines = out, meta = meta }
end

--- Format metadata as pretty-printed JSON lines.
---@param meta table metadata table from skeletonize()
---@return string[] JSON lines
function M.format_meta_json_lines(meta)
  local json_lines = {
    "{",
    ('  "file": %s,'):format(vim.fn.json_encode(meta.file or vim.NIL)),
    ('  "language": "%s",'):format(meta.language),
    ('  "original_line_count": %d,'):format(meta.original_line_count),
    ('  "skeleton_line_count": %d,'):format(meta.skeleton_line_count),
    ('  "comments_removed": %s,'):format(meta.comments_removed and "true" or "false"),
    '  "replacements": [',
  }
  for i, r in ipairs(meta.replacements) do
    local comma = i < #meta.replacements and "," or ""
    local skel = (r.skeleton_line == vim.NIL or r.skeleton_line == nil)
      and "null"
      or tostring(r.skeleton_line)
    table.insert(json_lines,
      ('    {"original_start": %d, "original_end": %d, "skeleton_line": %s}%s'):format(
        r.original_start, r.original_end, skel, comma
      ))
  end
  table.insert(json_lines, "  ]")
  table.insert(json_lines, "}")
  return json_lines
end

--- Format skeleton result as combined text with optional metadata header.
--- Used by SkeletonCopy for clipboard output.
---@param result table from M.skeletonize()
---@return string
function M.format_combined_text(result)
  local parts = {}

  if result.meta then
    table.insert(parts, "--- SKELETON METADATA ---")
    for _, jl in ipairs(M.format_meta_json_lines(result.meta)) do
      table.insert(parts, jl)
    end
    table.insert(parts, "--- SKELETON ---")
  end

  for _, line in ipairs(result.lines) do
    table.insert(parts, line)
  end

  return table.concat(parts, "\n")
end

return M
