require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- Get word count if the file is a text or markdown type
local function getWords()
  if vim.bo.filetype == "md" or vim.bo.filetype == "text" or vim.bo.filetype == "txt" or vim.bo.filetype == "vtxt" or vim.bo.filetype == "markdown" then
    return tostring(vim.fn.wordcount().words)
  else
    return ""
  end
end

-- Get active LSP clients
local function lsp_clients()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ''
  end

  local names = {}
  for _, c in pairs(clients) do
    if c.name ~= 'null-ls' then
      table.insert(names, c.name)
    end
  end
  if vim.tbl_isempty(names) then
    return ''
  end

  return table.concat(names, ', ')
end

-- Get current Git branch
local function git_branch()
  local branch = vim.b.gitsigns_head -- for gitsigns.nvim
  if branch then
    return branch
  end
  local handle = io.popen('git branch --show-current 2>/dev/null')
  if handle then
    local result = handle:read("*a")
    handle:close()
    result = result:gsub("\n", "")
    return result ~= "" and result or ""
  end
  return ""
end

-- Cache expensive stuff
local last_cache_time = 0
local cached_branch = ''
local cached_lsp = ''
local cached_words = ''

-- Helper to update cached values every 2 seconds
local function update_cache()
  local now = vim.loop.hrtime() / 1e9
  if now - last_cache_time > 2 then
    cached_branch = git_branch()
    if cached_branch ~= "" then
      cached_branch = ' ' .. cached_branch .. ' '
    end
    cached_lsp = lsp_clients()
    if cached_lsp ~= "" then
      cached_lsp = ' ' .. cached_lsp .. ' '
    end
    cached_words = getWords()
    if cached_words ~= '' then
      cached_words = cached_words .. ' words '
    end
    last_cache_time = now
  end
end

function _G.statusline()
  update_cache()

  local mode_map = {
    ['n']  = 'NORMAL',
    ['i']  = 'INSERT',
    ['v']  = 'VISUAL',
    ['V']  = 'V-LINE',
    [''] = 'V-BLOCK',
    ['c']  = 'COMMAND',
    ['R']  = 'REPLACE',
    ['t']  = 'TERMINAL',
  }
  local mode = mode_map[vim.fn.mode()] or vim.fn.mode()

  local filename = vim.fn.expand('%:t')
  if filename == '' then
    filename = '[No Name]'
  end

  local modified = vim.bo.modified and '[+]' or ''

  local encoding = vim.bo.fenc ~= '' and vim.bo.fenc or vim.o.enc
  local fileformat = vim.bo.fileformat
  local linecol = '%l:%c'

  local left = string.format(' %s %s%s %s', mode, cached_branch, filename, modified)
  local right = string.format('%s%s|[%s|%s]| %s ', cached_lsp, cached_words, encoding, fileformat, linecol)

  return left .. '%=' .. right
end

vim.o.statusline = "%!v:lua.statusline()"

