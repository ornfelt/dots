-- Highlight the whole #if / #ifdef / #elif / #else / #endif group the cursor is
-- sitting on, the way matchparen does for brackets, plus jumps between them.
--
-- Drop this in lua/autocmds/preproc_match.lua and add to your autocmds file:
--   require("autocmds.preproc_match")
-- It self-initialises on require. To override the defaults instead, use:
--   require("autocmds.preproc_match").setup({ toggle_key = '<leader>p' })
--
-- Jumping between the directives is left to matchit's `%`.

local M = {}

local ns = vim.api.nvim_create_namespace('preproc_match')

M.config = {
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'glsl' },
  hl_group = 'PreprocParen', -- links to MatchParen by default, see setup()
  whole_line = false,        -- true = highlight the entire directive line
  toggle_key = '<leader>#',  -- toggles the highlighting on/off
}

M.enabled = true

local OPEN  = { ['if'] = true, ifdef = true, ifndef = true }
local MID   = { elif = true, elifdef = true, elifndef = true, ['else'] = true }
local CLOSE = { endif = true }

-- "  # ifdef FOO" -> { kw = "ifdef", scol = 2, ecol = 9 } (0-based, end exclusive)
local function parse(line)
  local _, last, hash, kw = line:find('^%s*()#%s*(%a+)')
  if not kw then return nil end

  return { kw = kw:lower(), scol = hash - 1, ecol = last }
end

-- buf -> { tick, groups, lookup }; rescanning only happens after an edit
local cache = {}

local function scan(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local stack, groups, lookup = {}, {}, {}

  for lnum, line in ipairs(lines) do
    local d = parse(line)
    if d then
      d.lnum = lnum

      if OPEN[d.kw] then
        table.insert(stack, { d })
      elseif MID[d.kw] then
        local top = stack[#stack]
        if top then table.insert(top, d) end
      elseif CLOSE[d.kw] then
        local top = table.remove(stack)
        if top then
          table.insert(top, d)
          table.insert(groups, top)
        end
      end
    end
  end

  -- keep unterminated groups too, so a half-written block still highlights
  for i = #stack, 1, -1 do
    table.insert(groups, stack[i])
  end

  for _, g in ipairs(groups) do
    for _, d in ipairs(g) do
      lookup[d.lnum] = g
    end
  end

  return { groups = groups, lookup = lookup }
end

local function get_data(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local c = cache[buf]

  if not c or c.tick ~= tick then
    c = scan(buf)
    c.tick = tick
    cache[buf] = c
  end

  return c
end

function M.refresh()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  if not M.enabled then return end
  if not vim.tbl_contains(M.config.filetypes, vim.bo[buf].filetype) then return end

  -- cheap bail-out: nothing to do unless the cursor line is a directive
  if not parse(vim.api.nvim_get_current_line()) then return end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local group = get_data(buf).lookup[lnum]
  if not group or #group < 2 then return end

  for _, d in ipairs(group) do
    local opts
    if M.config.whole_line then
      opts = { line_hl_group = M.config.hl_group }
    else
      opts = { end_row = d.lnum - 1, end_col = d.ecol, hl_group = M.config.hl_group }
    end

    pcall(vim.api.nvim_buf_set_extmark, buf, ns, d.lnum - 1,
      M.config.whole_line and 0 or d.scol, opts)
  end
end

function M.toggle()
  M.enabled = not M.enabled

  if M.enabled then
    M.refresh()
  else
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      end
    end
  end

  vim.notify('preproc match: ' .. (M.enabled and 'on' or 'off'))
end

-- Not mapped by default, since matchit's `%` already jumps between the
-- directives. Kept around in case you want your own bind:
--   vim.keymap.set('n', ']#', function() require("autocmds.preproc_match").jump(1) end)
-- dir = 1 (next) / -1 (prev), cycles within the group. From inside a block it
-- jumps to the directives of the innermost enclosing group.
function M.jump(dir)
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local data = get_data(buf)
  local group, target = data.lookup[lnum], nil

  if group then
    local idx = 1
    for i, d in ipairs(group) do
      if d.lnum == lnum then
        idx = i
        break
      end
    end

    target = group[((idx - 1 + dir) % #group) + 1]
  else
    local best
    for _, g in ipairs(data.groups) do
      if g[1].lnum < lnum and g[#g].lnum > lnum then
        if not best or g[1].lnum > best[1].lnum then best = g end
      end
    end

    if not best then return end

    if dir > 0 then
      for _, d in ipairs(best) do
        if d.lnum > lnum then
          target = d
          break
        end
      end
      target = target or best[1]
    else
      for i = #best, 1, -1 do
        if best[i].lnum < lnum then
          target = best[i]
          break
        end
      end
      target = target or best[#best]
    end
  end

  if not target then return end

  vim.cmd("normal! m'") -- keep the jumplist usable
  vim.api.nvim_win_set_cursor(0, { target.lnum, target.scol })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  local function set_hl()
    vim.api.nvim_set_hl(0, 'PreprocParen', { link = 'MatchParen', default = true })
  end
  set_hl()

  local grp = vim.api.nvim_create_augroup('PreprocMatch', { clear = true })

  vim.api.nvim_create_autocmd('ColorScheme', { group = grp, callback = set_hl })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufWinEnter', 'WinEnter' }, {
    group = grp,
    callback = M.refresh,
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = grp,
    callback = function(ev) cache[ev.buf] = nil end,
  })

  vim.keymap.set('n', M.config.toggle_key, M.toggle,
    { desc = 'Toggle preprocessor directive match highlight' })

  return M
end

M.setup()

return M
