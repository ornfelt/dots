local myconfig = require("myconfig")

local has_oil = myconfig.is_plugin_installed('oil')
local has_mini_files = pcall(require, 'mini.files')

-- File tree
if has_oil then
  require('oil').setup({
    keymaps = {
      ["<C-s>"] = { "actions.select", opts = { vertical = true, close = true }, desc = "Open the entry in a vertical split" },
      ["<C-h>"] = { "actions.select", opts = { horizontal = true, close = true }, desc = "Open the entry in a horizontal split" },
      ["<C-t>"] = { "actions.select", opts = { tab = true, close = true }, desc = "Open the entry in new tab" },
    },
    view_options = {
      show_hidden = true,
    },
    -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
    skip_confirm_for_simple_edits = false,
    -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
    -- (:help prompt_save_on_select_new_entry)
    prompt_save_on_select_new_entry = true,
  })
  -- myconfig.map('n', '<M-w>', ':leftabove vsplit | vertical resize 40 | Oil ~/ <CR>')
  -- myconfig.map('n', '<M-w>', ':Oil ~/ <CR>')
  vim.keymap.set('n', '<M-w>', function()
    if vim.bo.filetype == 'oil' then
      -- vim.cmd('bd')
      vim.cmd('b#')
    else
      vim.cmd('Oil ~/')
    end
  end)
elseif has_mini_files then
  require('mini.files').setup()
  myconfig.map('n', '<M-w>', ':lua MiniFiles.open("~/")<CR>')
end

-- vim.api.nvim_create_user_command('OilToggle', function()
-- vim.cmd((vim.bo.filetype == 'oil') and 'bd' or 'Oil')
-- end, { nargs = 0 })

local function has_listed_alt_buffer()
  local alt = vim.fn.bufnr("#")             -- alternate buffer number
  return alt > 0 and vim.fn.buflisted(alt) == 1
end

--function toggle_filetree()
--  local filepath = vim.fn.expand('%:p') == '' and '~/' or vim.fn.expand('%:p:h')
--
--  -- Silly fix for making oil work with domain-based user dirs
--  --if filepath:find("%.homedir") then
--  if filepath:find("%.corp") then
--    filepath = filepath:gsub(".*se%-[^\\]+%-01\\", "H:/")
--    filepath = filepath:gsub(" ", "\\ ")
--  else
--    if not filepath:lower():find("h:") then
--      filepath = "./"
--    end
--  end
--
--  filepath = vim.fn.fnameescape(filepath)
--
--  if myconfig.should_debug_print() then
--    print(filepath)
--  end
--
--  if has_oil then
--    -- vim.cmd('leftabove vsplit | vertical resize 40 | Oil ' .. filepath)
--    -- vim.cmd('Oil ' .. filepath)
--    --vim.cmd((vim.bo.filetype == 'oil') and 'b#' or 'Oil ' .. filepath)
--    -- Fix error when empty buffer
--    if vim.bo.filetype == "oil" then
--      if has_listed_alt_buffer() then
--        vim.cmd("buffer #")  -- same as :b#
--      else
--        vim.cmd("enew")      -- no alternate buffer; create a normal empty one
--      end
--    else
--      vim.cmd("Oil " .. filepath)
--    end
--  elseif has_mini_files then
--    require('mini.files').open(filepath)
--  else
--    print("No file tree plugin installed...")
--  end
--end

function toggle_filetree()
  local fullpath = vim.fn.expand("%:p")
  local target_name = (fullpath ~= "") and vim.fn.fnamemodify(fullpath, ":t") or nil
  local filepath = (fullpath == "") and "~/" or vim.fn.expand("%:p:h")

  -- Silly fix for making oil work with domain-based user dirs
  if filepath:find("%.corp") then
    filepath = filepath:gsub(".*se%-[^\\]+%-01\\", "H:/")
    filepath = filepath:gsub(" ", "\\ ")
  else
    if not filepath:lower():find("h:") then
      filepath = "./"
    end
  end

  filepath = vim.fn.fnameescape(filepath)

  if myconfig.should_debug_print() then
    print(filepath)
  end

  if has_oil then
    -- Toggle close if we're already in Oil
    if vim.bo.filetype == "oil" then
      if has_listed_alt_buffer() then
        vim.cmd("buffer #") -- same as :b#
      else
        vim.cmd("enew") -- no alternate buffer; create a normal empty one
      end
      return
    end

    -- Open Oil
    vim.cmd("Oil " .. filepath)

    -- Jump cursor to current file (by basename.ext) if possible
    if target_name then
      vim.schedule(function()
        -- small sleep so Oil has time to populate the buffer
        vim.defer_fn(function()
          local ok, oil = pcall(require, "oil")
          if not ok then return end

          local bufnr = vim.api.nvim_get_current_buf()
          if vim.bo[bufnr].filetype ~= "oil" then return end

          local target_lc = target_name:lower()
          local line_count = vim.api.nvim_buf_line_count(bufnr)

          local function find_lnum(match_fn)
            for lnum = 1, line_count do
              local entry = oil.get_entry_on_line(bufnr, lnum)
              if entry and entry.name and match_fn(entry.name) then
                return lnum
              end
            end
          end

          -- exact match first
          local lnum = find_lnum(function(name) return name == target_name end)

          -- fallback: case-insensitive match
          if not lnum then
            lnum = find_lnum(function(name) return name:lower() == target_lc end)
          end

          if lnum then
            vim.api.nvim_win_set_cursor(0, { lnum, 0 })
          end
        end, 60)
      end)
    end

  elseif has_mini_files then
    require("mini.files").open(filepath)
  else
    print("No file tree plugin installed...")
  end
end

myconfig.map('n', '<M-e>', ':lua toggle_filetree()<CR>')

