local myconfig = require("myconfig")

myconfig.map('n', '<leader>ws', "/\\s\\+$/<CR>") -- Show extra whitespace
myconfig.map('n', '<leader>wr', ':%s/\\s\\+$<CR>') -- Remove all extra whitespace
myconfig.map('n', '<leader>wu', ':%s/\\%u200b//g<CR>') -- Remove all extra unicode chars
myconfig.map('n', '<leader>wb', ':%s/[[:cntrl:]]//g<CR>') -- Remove all hidden characters
--myconfig.map('n', '<leader>wf', 'gqG<C-o>zz') -- Format rest of the text with vim formatting, go back and center screen

myconfig.map('v', '<leader>gu', ':s/\\<./\\u&/g<CR>:noh<CR>:noh<CR>') -- Capitalize first letter of each word on visually selected line

function ReplaceQuotes()
  vim.cmd([[
    silent! %s/[’‘’]/'/g
    silent! %s/[“”]/"/g
    ]])
end

vim.api.nvim_set_keymap('n', '<leader>wq', ':lua ReplaceQuotes()<CR>', { noremap = true, silent = true })

-- replace unicode typographic chars with ASCII equivalents
vim.keymap.set('n', '<leader>wa', function()
  local pos = vim.api.nvim_win_get_cursor(0)

  local cmds = {
    [[%s,→,->,ge]], -- unicode rightward arrow -> ascii arrow
    [[%s,←,<-,ge]], -- unicode left arrow -> ascii arrow
    [[%s,“,",ge]], -- unicode left double quotation mark -> ascii straight quote 
    [[%s,”,",ge]], -- unicode right double quotation mark -> ascii straight quote 
    [[%s,’,',ge]], -- unicode right single quotation mark/apostrophe -> ascii straight apostrophe
    [[%s,‘,',ge]], -- unicode left single quotation mark/apostrophe -> ascii straight apostrophe
    [[%s,…,...,ge]], -- unicode ellipsis char -> ascii three dots
    [[%s,–,-,ge]], -- unicode en dash -> ascii hyphen
    [[%s,—,-,ge]], -- unicode em dash -> ascii hyphen
    [[%s,≈,~,ge]], -- unicode approximately equal -> ascii tilde
    [[%s,·,*,ge]], -- unicode middle dot/interpunct -> ascii asterix
  }

  local show_stats = true
  local show_detailed_stats = myconfig.should_debug_print()

  local per_char_counts = {}
  local total_chars = 0

  -- Count how many character types *will* be replaced
  if show_stats then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for _, cmd in ipairs(cmds) do
      -- Extract the character to search for
      -- Format is: %s,<from>,<to>,ge
      local from = cmd:match("%%s,(.-),")
      if from then
        local count = 0

        -- Count occurrences in the whole buffer
        for _, line in ipairs(lines) do
          -- plain = true so Lua does not treat Unicode as patterns
          local _, n = line:gsub(from, from)
          count = count + n
        end

        if count > 0 then
          total_chars = total_chars + 1
          per_char_counts[from] = count
        end
      end
    end
  end

  -- do the actual replacements
  for _, cmd in ipairs(cmds) do
    vim.cmd(cmd)
  end

  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, pos)

  if show_stats then
    if total_chars > 0 then
      print(string.format("Total characters expected to be replaced: %d", total_chars))

      if show_detailed_stats then
        print(string.format("Total characters expected to be replaced (tbl_count): %d", vim.tbl_count(per_char_counts)))
        for ch, cnt in pairs(per_char_counts) do
          print(string.format("  '%s' -> %d occurrence(s)", ch, cnt))
        end
      end
    else
      print("No typographic characters found")
    end
  end
end, { desc = 'Replace Unicode typography with ASCII' })

-- Replace some math-related unicode chars to ascii equivalents
vim.keymap.set('n', '<leader>wm', function()
  local pos = vim.api.nvim_win_get_cursor(0)

  local cmds = {
    [[%s,²,^2,ge]],
    [[%s,³,^3,ge]],
    [[%s,ⁿ,^n,ge]],
    [[%s,√,sqrt,ge]],
  }

  local show_stats = true
  local show_detailed_stats = myconfig.should_debug_print()

  local per_char_counts = {}
  local total_chars = 0

  -- Count how many character types *will* be replaced
  if show_stats then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for _, cmd in ipairs(cmds) do
      -- Extract the character to search for
      -- Format is: %s,<from>,<to>,ge
      local from = cmd:match("%%s,(.-),")
      if from then
        local count = 0

        -- Count occurrences in the whole buffer
        for _, line in ipairs(lines) do
          -- plain = true so Lua does not treat Unicode as patterns
          local _, n = line:gsub(from, from)
          count = count + n
        end

        if count > 0 then
          total_chars = total_chars + 1
          per_char_counts[from] = count
        end
      end
    end
  end

  -- do the actual replacements
  for _, cmd in ipairs(cmds) do
    vim.cmd(cmd)
  end

  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, pos)

  if show_stats then
    if total_chars > 0 then
      print(string.format("Total characters expected to be replaced: %d", total_chars))

      if show_detailed_stats then
        print(string.format("Total characters expected to be replaced (tbl_count): %d", vim.tbl_count(per_char_counts)))
        for ch, cnt in pairs(per_char_counts) do
          print(string.format("  '%s' -> %d occurrence(s)", ch, cnt))
        end
      end
    else
      print("No typographic characters found")
    end
  end
end, { desc = 'Replace Unicode typography with ASCII' })

-- Format file
function format_file()
  local filetype = vim.bo.filetype

  if filetype == "json" then
    if myconfig.is_callable("jq") then
      vim.cmd([[%!jq .]])
    elseif myconfig.is_callable("python") then
      vim.cmd([[%!python -m json.tool]])
    else
      vim.cmd('echo "No JSON formatter available!"')
    end

  elseif filetype == "xml" then
    if myconfig.is_callable("xmllint") then
      vim.cmd([[%!xmllint --format -]])
    elseif myconfig.is_callable("python") then
      vim.cmd([[%!python -c "import sys, xml.dom.minidom as m; print(m.parse(sys.stdin).toprettyxml())"]])
    else
      vim.cmd('echo "No XML formatter available!"')
    end

  else
    vim.cmd('echo "Unsupported file type!"')
  end
end

vim.api.nvim_set_keymap('n', '<leader>=', ':lua format_file()<CR>', { noremap = true, silent = true })

-- Commands to convert current word to another casing convention. 
-- If the word is UseTestingMode (Pascal),
-- :ToSnake makes it use_testing_mode,
-- :ToKebab -> use-testing-mode,
-- :ToCamel -> useTestingMod

--local function split_into_parts(word)
--  local parts = {}
--
--  -- Split PascalCase, camelCase, snake_case, kebab-case
--  for part in word:gmatch("[A-Z]?[a-z]+") do
--    table.insert(parts, part:lower())
--  end
--  if #parts == 0 then
--    for part in vim.split(word, "[_-]", { trimempty = true }) do
--      table.insert(parts, part:lower())
--    end
--  end
--  return parts
--end

local function split_into_parts(word)
  local parts = {}

  -- First try splitting camelCase/PascalCase with better acronym handling
  -- This pattern handles:
  -- - [A-Z]+(?=[A-Z][a-z]) : Multiple caps before a PascalCase word (HTTP in HTTPServer)
  -- - [A-Z]+(?=[^A-Za-z]|$) : Multiple caps at end or before delimiter (BB in DrawBB)
  -- - [A-Z][a-z]+ : Standard PascalCase word (Draw, Server)
  -- - [A-Z] : Single capital letter

  local i = 1
  while i <= #word do
    local char = word:sub(i, i)

    if char:match("[A-Z]") then
      -- Look ahead for consecutive capitals
      local j = i
      while j <= #word and word:sub(j, j):match("[A-Z]") do
        j = j + 1
      end

      if j > i + 1 then
        -- Multiple capitals found
        if j <= #word and word:sub(j, j):match("[a-z]") then
          -- Followed by lowercase (e.g., "HTTPS" in "HTTPServer")
          -- Keep all but the last capital together
          table.insert(parts, word:sub(i, j - 2):lower())
          i = j - 1
        else
          -- All capitals to end or delimiter (e.g., "BB", "BSA")
          table.insert(parts, word:sub(i, j - 1):lower())
          i = j
        end
      else
        -- Single capital, grab until next capital or delimiter
        local k = i + 1
        while k <= #word and word:sub(k, k):match("[a-z]") do
          k = k + 1
        end
        table.insert(parts, word:sub(i, k - 1):lower())
        i = k
      end
    elseif char:match("[a-z]") then
      -- Lowercase sequence (shouldn't happen in PascalCase but handle it)
      local j = i
      while j <= #word and word:sub(j, j):match("[a-z]") do
        j = j + 1
      end
      table.insert(parts, word:sub(i, j - 1):lower())
      i = j
    elseif char:match("[_-]") then
      -- Skip delimiters
      i = i + 1
    else
      i = i + 1
    end
  end

  -- Fallback to delimiter-based splitting if no parts found
  if #parts == 0 then
    for part in vim.split(word, "[_-]", { trimempty = true }) do
      if part ~= "" then
        table.insert(parts, part:lower())
      end
    end
  end

  return parts
end

local function get_word_under_cursor()
  --return vim.fn.expand("<cword>")
  -- Important to fix kebab case -> other case
  return vim.fn.expand("<cWORD>")
end

local function replace_word_under_cursor(new_word)
  local _ = get_word_under_cursor()
  --vim.cmd("normal! ciw" .. new_word)
  -- Important to fix kebab case -> other case
  vim.cmd("normal! ciW" .. new_word)
end

local function to_snake_case(word)
  local parts = split_into_parts(word)
  return table.concat(parts, "_")
end

local function to_kebab_case(word)
  local parts = split_into_parts(word)
  return table.concat(parts, "-")
end

local function to_camel_case(word)
  local parts = split_into_parts(word)
  if #parts == 0 then return word end
  local first = parts[1]
  for i = 2, #parts do
    parts[i] = parts[i]:gsub("^%l", string.upper)
  end
  return table.concat(parts, "")
end

local function to_pascal_case(word)
  local parts = split_into_parts(word)
  for i = 1, #parts do
    parts[i] = parts[i]:gsub("^%l", string.upper)
  end
  return table.concat(parts, "")
end

-- Core conversion command
local function convert_case(style)
  local word = get_word_under_cursor()
  if not word or word == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end

  local converted
  if style == "snake" then
    converted = to_snake_case(word)
  elseif style == "kebab" then
    converted = to_kebab_case(word)
  elseif style == "camel" then
    converted = to_camel_case(word)
  elseif style == "pascal" then
    converted = to_pascal_case(word)
  else
    vim.notify("Unknown style: " .. style, vim.log.levels.ERROR)
    return
  end

  if converted and converted ~= word then
    replace_word_under_cursor(converted)
  else
    vim.notify("Could not convert: already in target case?", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command("ToSnake", function() convert_case("snake") end, {})
vim.api.nvim_create_user_command("ToKebab", function() convert_case("kebab") end, {})
vim.api.nvim_create_user_command("ToCamel", function() convert_case("camel") end, {})
vim.api.nvim_create_user_command("ToPascal", function() convert_case("pascal") end, {})

