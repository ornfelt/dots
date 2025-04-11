local last_closed_tab = nil

local function save_and_close_tab()
  local tab_count = vim.fn.tabpagenr('$')
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
      vim.cmd("edit " .. buf_data.name)
      vim.api.nvim_win_set_cursor(0, buf_data.position)
    end
  end

  last_closed_tab = nil
end

vim.keymap.set("n", "<M-q>", save_and_close_tab, { noremap = true, silent = true })
vim.keymap.set("n", "<M-S-T>", restore_tab, { noremap = true, silent = true })

