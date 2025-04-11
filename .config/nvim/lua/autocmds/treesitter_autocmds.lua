local treesitter_utils = require("treesitter_utils")

-- Add async to function if using await inside function
local function add_async()
  -- Feed the "t" key back as part of the operation
  vim.api.nvim_feedkeys("t", "n", true)

  -- Get the current buffer and text before the cursor
  local buffer = vim.fn.bufnr()
  local text_before_cursor = vim.fn.getline("."):sub(vim.fn.col(".") - 4, vim.fn.col(".") - 1)

  -- Only proceed if the text before the cursor matches "awai"
  if text_before_cursor ~= "awai" then
    return
  end

  -- Get current Tree-sitter node, ignoring injections for embedded JS
  local current_node = vim.treesitter.get_node { ignore_injections = false }
  local function_node = treesitter_utils.find_node_ancestor(
    { "arrow_function", "function_declaration", "function" },
    current_node
  )
  if not function_node then
    return
  end

  -- Check if function is already "async"
  local function_text = vim.treesitter.get_node_text(function_node, 0)
  if vim.startswith(function_text, "async") then
    return
  end

  -- Add async at the start of the function
  local start_row, start_col = function_node:start()
  vim.api.nvim_buf_set_text(buffer, start_row, start_col, start_row, start_col, { "async " })
end

-- Set keybinding for JavaScript and TypeScript
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript" },
  callback = function()
    vim.keymap.set("i", "t", add_async, { buffer = true })
  end,
})

