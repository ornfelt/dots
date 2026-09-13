require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- { index = tab number it had, buffers = { { name, position } } }
local last_closed_tab = nil

local function buf_is_modified(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  -- Only the buffers :q itself would stop for: a nofile, nowrite, terminal or
  -- prompt buffer cannot be written, so there is nothing to "save first".
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
  if buftype == "nofile" or buftype == "nowrite" or buftype == "terminal" or buftype == "prompt" then
    return false
  end

  return vim.api.nvim_get_option_value("modified", { buf = buf })
end

local function any_buffer_is_modified()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf_is_modified(buf) then
      return true, buf
    end
  end

  return false, nil
end

local function save_and_close_tab()
  local tab_count = vim.fn.tabpagenr('$')
  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)

  local has_modified, modified_buf = any_buffer_is_modified()

  if has_modified and modified_buf ~= nil and tab_count <= 1 and #windows == 1 then
    local name = vim.api.nvim_buf_get_name(modified_buf)
    if name == "" then
      name = "[No Name]"
    end

    vim.notify(
      "There are unsaved changes in: " .. name .. ". Save first or use :q! manually.",
      vim.log.levels.WARN
    )
    return
  end

  if tab_count <= 1 then
    --print("Cannot save tab state: only one tab open.")
    vim.cmd("q")
    return
  end

  if #windows > 1 then
    vim.cmd("q")
    return
  end

  local buffers = {}

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    -- A [No Name] buffer has nothing to reopen
    if name ~= "" then
      table.insert(buffers, {
        name = name,
        position = vim.api.nvim_win_get_cursor(win),
      })
    end
  end

  -- A tab with nothing worth reopening leaves the one remembered before alone
  if #buffers > 0 then
    last_closed_tab = { index = vim.fn.tabpagenr(), buffers = buffers }
  end
  vim.cmd("tabclose")
end

local function restore_tab()
  if not last_closed_tab or #last_closed_tab.buffers == 0 then
    print("No closed tab to restore.")
    return
  end

  -- Back where it was closed, whichever tab is current now: [N]tabnew opens
  -- the tab after tab N, and 0tabnew before the first
  local after = math.min(last_closed_tab.index - 1, vim.fn.tabpagenr("$"))
  vim.cmd(after .. "tabnew")

  for _, buf_data in ipairs(last_closed_tab.buffers) do
    vim.cmd.edit(vim.fn.fnameescape(buf_data.name))
    -- The file may have got shorter since the tab was closed
    local line = math.min(buf_data.position[1], vim.api.nvim_buf_line_count(0))
    vim.api.nvim_win_set_cursor(0, { line, buf_data.position[2] })
  end

  last_closed_tab = nil
end

-- bind m-q: save_and_close_tab (n)
vim.keymap.set("n", "<M-q>", save_and_close_tab, { noremap = true, silent = true })
-- bind m-s-t: restore_tab (n)
vim.keymap.set("n", "<M-S-T>", restore_tab, { noremap = true, silent = true })

if vim.fn.has("win32") == 1 then
  -- bind ctrl-z: detach current UI (n)
  vim.keymap.set("n", "<C-z>", "<Cmd>detach<CR>", { noremap = true, silent = true })
end

local function is_remote_ui()
  for _, ui in ipairs(vim.api.nvim_list_uis()) do
    local info = vim.api.nvim_get_chan_info(ui.chan)

    if info.stream == "socket" then
      return true
    end
  end

  return false
end

local function is_headless_server()
  return vim.tbl_contains(vim.v.argv, "--headless")
end

vim.api.nvim_create_user_command("NvimServerInfo", function()
  print("Remote UI:       " .. tostring(is_remote_ui()))
  print("Headless server: " .. tostring(is_headless_server()))
end, {})
