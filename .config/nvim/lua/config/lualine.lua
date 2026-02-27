require('dbg_log').log_file(debug.getinfo(1, 'S').source)

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

local function getWords()
  if vim.bo.filetype == "md" or vim.bo.filetype == "text" or vim.bo.filetype == "txt" or vim.bo.filetype == "vtxt" or vim.bo.filetype == "markdown" then
    return tostring(vim.fn.wordcount().words)
  else
    return ""
  end
end

local function lsp_clients()
  -- Neovim ≥0.10: pass { bufnr = 0 } for "current buffer"
  -- For 0.9-: use vim.lsp.get_active_clients() and filter manually
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  if #clients == 0 then
    return '' -- no LSP for this buffer
  end

  local names = {}
  for _, c in pairs(clients) do
    -- Skip pseudo-clients such as null-ls
    if c.name ~= 'null-ls' then
      table.insert(names, c.name)
    end
  end
  if vim.tbl_isempty(names) then
    return ''
  end

  --return '  ' .. table.concat(names, ', ')
  --return 'lsp: ' .. table.concat(names, ', ')
  return table.concat(names, ', ')
end

local options = {
  --icons_enabled = true,
  icons_enabled = false,
  theme = 'gruvbox',
  -- globalstatus = true,
  refresh = {
    statusline = 1000,
    tabline = 1000,
    winbar = 1000,
  }
}

if vim.fn.has('win32') == 1 then
  options.component_separators = { left = '', right = '|' }
end

require('lualine').setup {
  options = options,
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {
      lsp_clients,
      getWords,
      getTabBufferInfo,
      'encoding',
      {
        'fileformat',
        symbols = {
          unix = 'unix',
          dos = 'win',
          mac = 'mac'
        }
      },
      'filetype'
    },
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}

