require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local use_icons = false
--local use_icons = true

--local show_tab_buffer_info = false
local show_tab_buffer_info = true

local show_buffer_info = false
--local show_buffer_info = true

local function getTabBufferInfo()
  if not show_tab_buffer_info then
    return ''
  end
  local tab_num = vim.fn.tabpagenr()
  local tab_count = vim.fn.tabpagenr('$')
  local result = string.format('%d/%d', tab_num, tab_count)
  if show_buffer_info then
    local buf_num = vim.api.nvim_get_current_buf()
    local buf_count = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.fn.buflisted(buf) == 1 then
        buf_count = buf_count + 1
      end
    end
    result = string.format('%s (%d/%d)', result, buf_num, buf_count)
  end
  return result
end

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
  local result = table.concat(names, ', ')
  return use_icons and (' ' .. result) or result
end

-- Get current Git branch
local function git_branch()
  local branch = vim.b.gitsigns_head
  if branch then
    return use_icons and (' ' .. branch) or branch
  end

  -- Windows-compatible error redirection
  local redirect = vim.fn.has('win32') == 1 and '2>nul' or '2>/dev/null'
  local handle = io.popen('git branch --show-current ' .. redirect)

  if handle then
    local result = handle:read("*a")
    handle:close()
    result = result:gsub("\n", ""):gsub("\r", "")
    if result ~= "" then
      result = result .. ' '
      return use_icons and (' ' .. result) or result
    end
  end
  return ""
end

-- Cache expensive stuff
local last_cache_time = 0
local cached_branch = ''
local cached_lsp = ''
local cached_words = ''
local cached_tab_buffer = ''

local function update_cache()
  local now = vim.loop.hrtime() / 1e9
  if now - last_cache_time > 2 then
    cached_branch = git_branch()
    cached_lsp = lsp_clients()
    cached_words = getWords()
    cached_tab_buffer = getTabBufferInfo()
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

  local left = string.format(' %s%s| %s %s', mode, cached_branch ~= '' and (' | ' .. cached_branch) or ' ', filename, modified)

  -- Build right side, only add separators between non-empty values
  local right_parts = {}
  if cached_lsp ~= '' then table.insert(right_parts, cached_lsp) end
  if cached_words ~= '' then table.insert(right_parts, cached_words) end
  if cached_tab_buffer ~= '' then table.insert(right_parts, cached_tab_buffer) end
  table.insert(right_parts, encoding)
  table.insert(right_parts, fileformat)
  table.insert(right_parts, linecol)

  local right = ' ' .. table.concat(right_parts, ' | ') .. ' '

  return left .. '%=' .. right
end

vim.o.statusline = "%!v:lua.statusline()"

