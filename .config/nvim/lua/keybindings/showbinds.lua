local myconfig = require("myconfig")

vim.keymap.set('n', '<leader>?', function()
  local file_path = myconfig.my_notes_path .. "/scripts/files/nvim_keys.txt"
  local lines = myconfig.read_lines_from_file(file_path)

  -- Use Telescope picker to display lines
  require('telescope.pickers').new({}, {
    prompt_title = "Choose Line",
    finder = require('telescope.finders').new_table({
      results = lines,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),

    attach_mappings = function(prompt_bufnr, _)
      require('telescope.actions').select_default:replace(function()
        local selection = require('telescope.actions.state').get_selected_entry()
        require('telescope.actions').close(prompt_bufnr)
        print(selection.value)
      end)
      return true
    end

  }):find()
end, { noremap = true, silent = true })

