require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local last_closed_tab = nil

local function buf_is_modified(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_get_option_value("modified", { buf = buf })
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

  local tabpage = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  local buffers = {}

  if #windows > 1 then
    vim.cmd("q")
    return
  end

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    table.insert(buffers, {
      name = vim.api.nvim_buf_get_name(buf),
      position = vim.api.nvim_win_get_cursor(win),
    })
  end

  last_closed_tab = buffers
  vim.cmd("tabclose")
end

local function restore_tab()
  if not last_closed_tab or #last_closed_tab == 0 then
    print("No closed tab to restore.")
    return
  end

  vim.cmd("tabnew")

  local current_tab_index = vim.fn.tabpagenr()
  local total_tabs = vim.fn.tabpagenr("$")

  if current_tab_index < total_tabs then
    vim.cmd("tabmove -1")
  end

  for _, buf_data in ipairs(last_closed_tab) do
    if buf_data.name ~= "" then
      vim.cmd.edit(vim.fn.fnameescape(buf_data.name))
      vim.api.nvim_win_set_cursor(0, buf_data.position)
    end
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
