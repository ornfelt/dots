local myconfig = require("myconfig")

-- Unified picker using fzf, fzf-lua, telescope or vim.ui.select
local function choose(prompt, options, callback)
  local picker    = myconfig.get_file_picker()
  local use_fzf   = picker == myconfig.FilePicker.FZF
  local use_fzf_lua = picker == myconfig.FilePicker.FZF_LUA
  --local use_file_picker = picker ~= myconfig.FilePicker.NONE
  local use_file_picker = myconfig.use_file_picker_for_commands()

  if use_file_picker then
    if use_fzf then
      vim.fn["fzf#run"]({
        source  = options,
        sink    = callback,
        options = "--prompt '" .. prompt .. "> ' --reverse",
      })

    elseif use_fzf_lua then
      require('fzf-lua').fzf_exec(options, {
        prompt  = prompt .. "> ",
        actions = {
          ["default"] = function(selected)
            callback(selected[1])
          end,
        },
      })

    else
      local pickers      = require('telescope.pickers')
      local finders      = require('telescope.finders')
      local actions      = require('telescope.actions')
      local action_state = require('telescope.actions.state')
      local sorters = require("telescope.sorters")
      --local conf         = require('telescope.config').values

      pickers.new({}, {
        prompt_title = prompt,
        finder = finders.new_table({ results = options }),
        --sorter = conf.generic_sorter({}),
        sorter = sorters.get_fzy_sorter(),
        sorting_strategy = "ascending",
        attach_mappings = function(prompt_bufnr, map)
          local function on_select()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            -- sel.value for telescope, sel[1] for fzf-lua
            callback(sel.value or sel[1])
          end
          map('i', '<CR>', on_select)
          map('n', '<CR>', on_select)
          return true
        end,
      }):find()
    end

  else
    vim.ui.select(options, { prompt = prompt .. ':' }, function(choice)
      if choice then callback(choice) end
    end)
  end
end

-- Keymap: hierarchical pick from headers and subsequent lines -> copy to clipboard on select
vim.keymap.set('n', '<leader>?', function()
  --local file_path = myconfig.my_notes_path .. "/scripts/files/nvim_keys.txt"
  local file_path = myconfig.my_notes_path .. ".vim/binds.txt"
  local lines = myconfig.read_lines_from_file(file_path)

  -- Parse categories and their items
  local categories = {}
  local items      = {}
  local current

  --for _, line in ipairs(lines) do
  --  local header = line:match("^#%s*(.+)")
  --  if header then
  --    current = header
  --    table.insert(categories, header)
  --    items[header] = {}
  --  elseif current then
  --    local is_content = not(line:match("^%s*$") or line:match("^%-%-") or line:match("^%*%*") or line:match("^[-]+$"))
  --    local is_mapcmd = line:match("^%s*map:%s+") or line:match("^%s*cmd:%s+") or line:match("^%s*autocmd:%s+")
  --    if is_content and is_mapcmd then
  --      table.insert(items[current], line)
  --    end
  --  end
  --end

  local i = 1
  while i <= #lines do
    local line = lines[i]

    -- new category header
    local header = line:match("^#%s*(.+)")
    if header then
      current = header
      categories[#categories+1] = header
      items[header] = {}
      i = i + 1

    -- if inside a category...
    elseif current then
      -- get map/cmd/autocmd key
      local key = line:match("^%s*map:%s*(.+)")
               or line:match("^%s*cmd:%s*(.+)")
               --or line:match("^%s*autocmd:%s*(.+)")

      if key then
        -- look ahead one line for desc:
        local desc_line = lines[i+1] or ""
        local desc = desc_line:match("^%s*desc:%s*(.+)") or ""

        -- merge "key -> desc"
        local merged = key .. " -> " .. desc
        items[current][#items[current]+1] = merged

        -- skip lines
        i = i + 2
      else
        -- not a key+desc pair, just skip
        i = i + 1
      end

    else
      -- outside of any category, just skip
      i = i + 1
    end
  end

  -- Pick a category
  choose('Category', categories, function(cat)
    -- Pick a line in that category
    choose(cat, items[cat] or {}, function(line)
      -- Copy to clipboard and notify
      vim.fn.setreg('+', line)
      print('Copied to clipboard: ' .. line)
    end)
  end)
end, { noremap = true, silent = true })

