require('telescope').setup({})
--require('telescope').setup({
--  defaults = {
--    -- Enable the preview window
--    previewer = true,
--    preview = {
--      hide_on_startup = false, -- Show preview by default
--    },
--    -- Customize layout
--    layout_config = {
--      horizontal = {
--        preview_width = 0.6,
--      },
--      vertical = {
--        preview_height = 0.5,
--      },
--    },
--  },
--})

--local builtin = require('telescope.builtin')
--vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
--vim.keymap.set('n', '<C-p>', builtin.git_files, {})
--vim.keymap.set('n', '<leader>pws', function()
--    local word = vim.fn.expand("<cword>")
--    builtin.grep_string({ search = word })
--end)
--vim.keymap.set('n', '<leader>pWs', function()
--    local word = vim.fn.expand("<cWORD>")
--    builtin.grep_string({ search = word })
--end)
--vim.keymap.set('n', '<leader>ps', function()
--    builtin.grep_string({ search = vim.fn.input("Grep > ") })
--end)
--vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})

local utils = require('telescope.utils')
local builtin = require('telescope.builtin')

function project_files()
  local _, ret, _ = utils.get_os_command_output({ 'git', 'rev-parse', '--is-inside-work-tree' })
  if ret == 0 then
    --builtin.git_files()
    builtin.git_files({
      previewer = true,
    })
  else
    --builtin.find_files()
    builtin.find_files({
      previewer = true,
    })
  end
end
vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua project_files()<CR>', { noremap = true, silent = true })

function project_files_opts(opts)
  opts = opts or {}
  local _, ret, _ = utils.get_os_command_output({ 'git', 'rev-parse', '--is-inside-work-tree' })
  if ret == 0 then
    builtin.git_files(opts)
  else
    builtin.find_files(opts)
  end
end
-- vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua project_files_opts({ hidden = true })<CR>', { noremap = true, silent = true })

--vim.api.nvim_set_keymap('n', '<leader>tf', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>Telescope git_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-A>', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>tg', '<cmd>Telescope live_grep<CR>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', '<leader>tb', '<cmd>Telescope buffers<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>t', '<cmd>Telescope buffers<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>th', '<cmd>Telescope help_tags<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>td', '<cmd>Telescope lsp_definitions<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>tr', '<cmd>Telescope lsp_references<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>gs', ':lua require("telescope.builtin").git_status()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gb', ':lua builtin.git_branches()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gt', ':lua builtin.git_stash()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gs', ':lua builtin.git_status()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gc', ':lua builtin.git_commits()<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>gc', ':lua builtin.git_bcommits()<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>gc', ':lua builtin.git_bcommits_range()<CR>', { noremap = true, silent = true })

--
-- MakefileTargets
--
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function extract_makefile_targets(makefile_path)
  local targets = {}
  for line in io.lines(makefile_path) do
    local target = line:match("^([%w-]+):")
    if target then
      table.insert(targets, target)
    end
  end
  return targets
end

local function run_make_command(target)
  local command = "make " .. target
  local output = vim.fn.system(command)

  -- Open a new split window and show the output
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_name(buf, "Make Output: " .. target)
end

local makefile_targets = function(opts)
  opts = opts or {}
  local makefile_path = vim.fn.findfile("Makefile", ".;")

  if makefile_path == "" then
    print("No Makefile found in the current directory or its parents")
    return
  end

  local targets = extract_makefile_targets(makefile_path)

  pickers.new(opts, {
    prompt_title = "Makefile Targets",
    finder = finders.new_table {
      results = targets
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        run_make_command(selection[1])
      end)
      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command("MakefileTargets", makefile_targets, {})
-- return require("telescope").register_extension({
require("telescope").register_extension({
  exports = {
    makefile_targets = makefile_targets
  },
})

local scan = require("plenary.scandir")
local path = require("plenary.path")

-- Store test results
local test_results = {}

local function run_go_test(file_path, callback)
  local cmd = string.format("go test -v %s", file_path)
  local output = ""
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          output = output .. line .. "\n"
          print(line)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          output = output .. line .. "\n"
          print(line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      local passed = exit_code == 0
      test_results[file_path] = passed
      if passed then
        print("Tests passed successfully!")
      else
        print("Tests failed with exit code: " .. exit_code)
      end
      if callback then
        callback(passed, output)
      end
    end,
  })
end

function golang_test_files(opts)
  opts = opts or {}

  -- Get current buffer's file path
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.expand("%:p:h")
  local current_file_name = vim.fn.expand("%:t:r")
  local corresponding_test_file = path:new(current_dir, current_file_name .. "_test.go").filename

  -- Find project root
  local project_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if not project_root then
    print("Not in a git repository")
    return
  end

  -- Find all Golang test files
  local find_command = scan.scan_dir(project_root, {
    search_pattern = ".*_test%.go$",
    respect_gitignore = true
  })

  -- Prepare results table
  local results = {}

  -- Add corresponding test file first if it exists
  if vim.fn.filereadable(corresponding_test_file) == 1 then
    table.insert(results, corresponding_test_file)
  end

  -- Add all other test files
  for _, file in ipairs(find_command) do
    if file ~= corresponding_test_file then
      table.insert(results, file)
    end
  end

  local function make_display(entry)
    local display = vim.fn.fnamemodify(entry, ":.:") -- relative path
    if entry == corresponding_test_file then
      display = display .. " (Current)"
    end
    if test_results[entry] == true then
      display = display .. " ✅"
    elseif test_results[entry] == false then
      display = display .. " ❌"
    end
    return display
  end

  local function make_entry(entry)
    return {
      value = entry,
      display = make_display(entry),
      ordinal = entry,
      path = entry,
    }
  end

  local custom_sorter = function(opts)
    opts = opts or {}
    return require("telescope.sorters").Sorter:new {
      scoring_function = function() return 0 end,
      -- This sorter does nothing, preserving the original order
    }
  end

  local run_test_action = function(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local selected_index = current_picker:get_index(current_picker:get_selection_row())

    if vim.fn.filereadable(selection.value) == 1 then
      run_go_test(selection.value, function()
        current_picker:refresh(finders.new_table {
          results = results,
          entry_maker = make_entry,
        }, {
            reset_prompt = false,
          })
        vim.schedule(function()
          current_picker:set_selection(selected_index)
        end)
      end)
    else
      print("Cannot run tests: File does not exist.")
    end
  end

  local picker = pickers.new(opts, {
    prompt_title = "Golang Test Files",
    finder = finders.new_table {
      results = results,
      entry_maker = make_entry,
    },
    sorter = custom_sorter(),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. selection.value)
      end)

      map("n", "<leader>T", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd("edit " .. selection.value)
      end)

      map("n", "<C-e>", run_test_action)
      map("i", "<C-e>", run_test_action)

      return true
    end,
  })

  picker:find()
end

vim.api.nvim_create_user_command("GoLangTestFiles", golang_test_files, {})

--
-- Custom function for document symbols
--
--function document_symbols_for_selected(prompt_bufnr)
--  local entry = action_state.get_selected_entry()
--
--  if entry == nil then
--    print("No file selected")
--    return
--  end
--
--  actions.close(prompt_bufnr)
--
--  vim.schedule(function()
--    local bufnr = vim.fn.bufadd(entry.path)
--    vim.fn.bufload(bufnr)
--
--    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
--
--    vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
--      if err then
--        print("Error getting document symbols: " .. vim.inspect(err))
--        return
--      end
--
--      if not result or vim.tbl_isempty(result) then
--        print("No symbols found")
--        return
--      end
--
--      local function flatten_symbols(symbols, parent_name)
--        local flattened = {}
--        for _, symbol in ipairs(symbols) do
--          local name = symbol.name
--          if parent_name then
--            name = parent_name .. "." .. name
--          end
--          table.insert(flattened, {
--            name = name,
--            kind = symbol.kind,
--            range = symbol.range,
--            selectionRange = symbol.selectionRange,
--          })
--          if symbol.children then
--            local children = flatten_symbols(symbol.children, name)
--            for _, child in ipairs(children) do
--              table.insert(flattened, child)
--            end
--          end
--        end
--        return flattened
--      end
--
--      local flat_symbols = flatten_symbols(result)
--
--      -- Define highlight group for symbol kind
--      vim.cmd([[highlight TelescopeSymbolKind guifg=#61AFEF]])
--
--      require("telescope.pickers").new({}, {
--        prompt_title = "Document Symbols: " .. vim.fn.fnamemodify(entry.path, ":t"),
--        finder = require("telescope.finders").new_table({
--          results = flat_symbols,
--          entry_maker = function(symbol)
--            local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or "Other"
--            return {
--              value = symbol,
--              display = function(entry)
--                local display_text = string.format("%-50s %s", entry.value.name, kind)
--                return display_text, { { { #entry.value.name + 1, #display_text }, "TelescopeSymbolKind" } }
--              end,
--              ordinal = symbol.name,
--              filename = entry.path,
--              lnum = symbol.selectionRange.start.line + 1,
--              col = symbol.selectionRange.start.character + 1,
--            }
--          end,
--        }),
--        sorter = require("telescope.config").values.generic_sorter({}),
--        previewer = require("telescope.config").values.qflist_previewer({}),
--        attach_mappings = function(_, map)
--          map("i", "<CR>", function(prompt_bufnr)
--            local selection = action_state.get_selected_entry()
--            actions.close(prompt_bufnr)
--            vim.cmd("edit " .. selection.filename)
--            vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col - 1 })
--          end)
--          return true
--        end,
--      }):find()
--    end)
--  end)
--end
--
--require('telescope').setup({
--  defaults = {
--    mappings = {
--      i = {
--        ["<esc>"] = actions.close,
--        ["<C-t>"] = require("trouble").open_with_trouble,
--        ["<C-s>"] = document_symbols_for_selected, -- Bind <C-s> in insert mode
--      },
--      n = {
--        ["<C-t>"] = require("trouble").open_with_trouble,
--        ["<C-s>"] = document_symbols_for_selected, -- Bind <C-s> in normal mode
--      },
--    },
--  },
--  pickers = {
--    -- Custom pickers
--  },
--  extensions = {
--    -- Extensions
--  },
--})

