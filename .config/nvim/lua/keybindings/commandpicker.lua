local commands = {
  -- Packer
  { label = "PackerUpdate", cmd = "PackerUpdate" },
  { label = "PackerLoad", cmd = "PackerLoad" },
  { label = "PackerSync", cmd = "PackerSync" },
  -- Lazy
  { label = "Lazy", cmd = "Lazy" },
  -- Markview
  { label = "Markview", cmd = "Markview" },
  -- Custom
  { label = "Diffi", cmd = "Diffi" },
  { label = "Diffg", cmd = "Diffg" },
  { label = "Diffgf", cmd = "Diffgf" },
  { label = "DiffCp", cmd = "DiffCp" },
  { label = "MakefileTargets", cmd = "MakefileTargets" },
  { label = "GoLangTestFiles", cmd = "GoLangTestFiles" },
  { label = "Config - CyclePythonExecCommand", cmd = "CyclePythonExecCommand" },
  { label = "Config - CycleFilePicker", cmd = "CycleFilePicker" },
  { label = "Config - CycleSqlExecLang", cmd = "CycleSqlExecLang" },
  { label = "Config - TogglePrioritizeBuildScript", cmd = "TogglePrioritizeBuildScript" },
  { label = "Config - ToggleDebugPrint", cmd = "ToggleDebugPrint" },
  { label = "Config - ToggleUseFilePickerForCommands", cmd = "ToggleUseFilePickerForCommands" },
  { label = "Config - ToggleUseCustomLspForSql", cmd = "ToggleUseCustomLspForSql" },
  { label = "Config - PrintConfig", cmd = "PrintConfig" },
  { label = "Llama", cmd = "Llm" },
  { label = "SkeletonCopy", cmd = "SkeletonCopy" },
  { label = "SkeletonCopy with comments", cmd = "SkeletonCopy!" },
  { label = "RemoveSession", cmd = "RemoveSession" },
  { label = "ToSnake", cmd = "ToSnake" },
  { label = "ToKebab", cmd = "ToKebab" },
  { label = "ToCamel", cmd = "ToCamel" },
  { label = "ToPascal", cmd = "ToPascal" },
  { label = "FileInfo", cmd = "FileInfo" },
  { label = "CopyHist x type", cmd = "CopyHist" },
  { label = "PrintAiModels", cmd = "PrintAiModels" },
  { label = "PrintAiModelsByRequest openai/anthropic/googleai", cmd = "PrintAiModelsByRequest" },
  -- Custom SQL LSP
  { label = "SqlMiniDump", cmd = "SqlMiniDump" },
  { label = "SqlMiniSwitch idx", cmd = "SqlMiniSwitch 2" },
  -- SQL
  { label = "SqlsExecuteQuery", cmd = "SqlsExecuteQuery" },
  { label = "SqlsShowSchemas", cmd = "SqlsShowSchemas" },
  { label = "SqlsShowTables", cmd = "SqlsShowTables" },
  { label = "SqlsShowDatabases", cmd = "SqlsShowDatabases" },
  { label = "SqlsSwitchDatabase", cmd = "SqlsSwitchDatabase" },
  { label = "SqlsShowConnections", cmd = "SqlsShowDatabases" },
  { label = "SqlsSwitchConnection", cmd = "SqlsSwitchConnection" },
  -- GP
  { label = "GpChatNew - New chat", cmd = "GpChatNew" },
  { label = "GpChatPaste - Visual chat paste", cmd = "GpChatPaste" },
  { label = "GpChatToggle - Toggle chat", cmd = "GpChatToggle" },
  { label = "GpChatFinder - Find chat history", cmd = "GpChatFinder" },
  { label = "GpChatRespond - Request a GPT response for current chat", cmd = "GpChatRespond" },
  { label = "GpChatDelete - Delete the current chat", cmd = "GpChatDelete" },
  { label = "GpRewrite - Rewrite using a prompt", cmd = "GpRewrite" },
  { label = "GpAppend - Add GPT response after current content", cmd = "GpAppend" },
  { label = "GpPrepend - Add GPT response before current content", cmd = "GpPrepend" },
  { label = "GpEnew - Add GPT response into a new buffer", cmd = "GpEnew" },
  { label = "GpNew - Add GPT response into a new horizontal split", cmd = "GpNew" },
  { label = "GpVnew - Add GPT response into a new vertical split", cmd = "GpVnew" },
  { label = "GpTabnew - Add GPT response into a new tab", cmd = "GpTabnew" },
  { label = "GpPopup - Add GPT response into a pop-up window", cmd = "GpPopup" },
  { label = "GpImplement - Use comments to develop code", cmd = "GpImplement" },
  { label = "GpContext - Provide custom context per repository", cmd = "GpContext" },
  { label = "GpWhisper - Transcribe and replace content", cmd = "GpWhisper" },
  { label = "GpWhisperRewrite - Transcribe and rewrite content", cmd = "GpWhisperRewrite" },
  { label = "GpWhisperAppend - Transcribe and append content", cmd = "GpWhisperAppend" },
  { label = "GpWhisperPrepend - Transcribe and prepend content", cmd = "GpWhisperPrepend" },
  { label = "GpWhisperEnew - Transcribe into a new buffer", cmd = "GpWhisperEnew" },
  { label = "GpWhisperPopup - Transcribe into a pop-up window", cmd = "GpWhisperPopup" },
  { label = "GpNextAgent - Switch to the next agent", cmd = "GpNextAgent" },
  { label = "GpStop - Stop all ongoing responses", cmd = "GpStop" },
  { label = "GpInspectPlugin - Inspect the GPT plugin object", cmd = "GpInspectPlugin" },
  { label = "GpChatNew - Visual new chat for selected content", cmd = "GpChatNew" },
  { label = "GpChatPaste - Visual chat paste for selection", cmd = "GpChatPaste" },
  { label = "GpChatToggle - Visual toggle chat for selection", cmd = "GpChatToggle" },
  { label = "GpRewrite - Rewrite content inline", cmd = "GpRewrite" },
  { label = "GpAppend - Append content inline", cmd = "GpAppend" },
  { label = "GpPrepend - Prepend content inline", cmd = "GpPrepend" },
  { label = "GpRewrite - Rewrite selected content", cmd = "GpRewrite" },
  { label = "GpAppend - Append after selected content", cmd = "GpAppend" },
  { label = "GpPrepend - Prepend before selected content", cmd = "GpPrepend" },
  { label = "GpPopup - Add GPT response to a visual pop-up window", cmd = "GpPopup" },
  { label = "GpEnew - Add GPT response to a visual new buffer", cmd = "GpEnew" },
  { label = "GpNew - Add GPT response to a visual horizontal split", cmd = "GpNew" },
  { label = "GpVnew - Add GPT response to a visual vertical split", cmd = "GpVnew" },
  { label = "GpTabnew - Add GPT response to a visual new tab", cmd = "GpTabnew" },
  -- ChatGPT
  { label = "ChatGPTRun Translate - Translate content", cmd = "ChatGPTRun translate" },
  { label = "ChatGPTRun Keywords - Generate keywords", cmd = "ChatGPTRun keywords" },
  { label = "ChatGPTRun Fix Bugs - Fix bugs in code", cmd = "ChatGPTRun fix_bugs" },
  { label = "ChatGPTRun Roxygen Edit - Edit Roxygen comments", cmd = "ChatGPTRun roxygen_edit" },
  { label = "ChatGPTEditWithInstructions - Edit with instructions", cmd = "ChatGPTEditWithInstructions" },
  { label = "ChatGPTRun Explain Code - Explain the code", cmd = "ChatGPTRun explain_code" },
  { label = "ChatGPTRun Complete Code - Complete selected code", cmd = "ChatGPTRun complete_code" },
  { label = "ChatGPTRun Summarize - Summarize selected content", cmd = "ChatGPTRun summarize" },
  { label = "ChatGPTRun Grammar Correction - Correct grammar", cmd = "ChatGPTRun grammar_correction" },
  { label = "ChatGPTRun Docstring - Generate docstring", cmd = "ChatGPTRun docstring" },
  { label = "ChatGPTRun Add Tests - Add tests for code", cmd = "ChatGPTRun add_tests" },
  { label = "ChatGPTRun Optimize Code - Optimize the code", cmd = "ChatGPTRun optimize_code" },
  { label = "ChatGPTRun Code Readability Analysis - Analyze code readability", cmd = "ChatGPTRun code_readability_analysis" },
  { label = "ChatGPT - Run ChatGPT for selection", cmd = "ChatGPT" },
  -- LSP
  { label = "LSP Info", cmd = "LspInfo" },
  { label = "LSP Log", cmd = "LspLog" },
  { label = "LSP Document Symbols", cmd = "lua vim.lsp.buf.document_symbol()" },
  { label = "LSP Client Attached", cmd = "lua print(vim.lsp.buf.server_ready())" },
  { label = "LSP Client Capabilities", cmd = "lua print(vim.inspect(vim.lsp.get_active_clients()[1].server_capabilities))" },
  { label = "LSP Client Name", cmd = "lua print(vim.lsp.get_active_clients()[1].name)" },
  { label = "LSP Active Clients", cmd = "lua print(vim.inspect(vim.lsp.get_active_clients()))" },
  { label = "LSP Start Client", cmd = "lua vim.lsp.start_client({ name = 'example', cmd = {'path/to/server'} })" },
  { label = "LSP Stop Client", cmd = "lua vim.lsp.stop_client(vim.lsp.get_active_clients())" },
  -- Telescope file pickers
  { label = "Telescope Find files", cmd = "lua require('telescope.builtin').find_files()" },
  { label = "Telescope Git files", cmd = "lua require('telescope.builtin').git_files()" },
  { label = "Telescope Grep string", cmd = "lua require('telescope.builtin').grep_string()" },
  { label = "Telescope Live grep", cmd = "lua require('telescope.builtin').live_grep()" },
  -- Telescope vim pickers
  { label = "Telescope Buffers", cmd = "lua require('telescope.builtin').buffers()" },
  { label = "Telescope Old files", cmd = "lua require('telescope.builtin').oldfiles()" },
  { label = "Telescope Commands", cmd = "lua require('telescope.builtin').commands()" },
  { label = "Telescope Tags", cmd = "lua require('telescope.builtin').tags()" },
  { label = "Telescope Command history", cmd = "lua require('telescope.builtin').command_history()" },
  { label = "Telescope Search history", cmd = "lua require('telescope.builtin').search_history()" },
  { label = "Telescope Help tags", cmd = "lua require('telescope.builtin').help_tags()" },
  { label = "Telescope Man pages", cmd = "lua require('telescope.builtin').man_pages()" },
  { label = "Telescope Marks", cmd = "lua require('telescope.builtin').marks()" },
  { label = "Telescope Colorscheme", cmd = "lua require('telescope.builtin').colorscheme()" },
  { label = "Telescope Quickfix", cmd = "lua require('telescope.builtin').quickfix()" },
  { label = "Telescope Loclist", cmd = "lua require('telescope.builtin').loclist()" },
  { label = "Telescope Jumplist", cmd = "lua require('telescope.builtin').jumplist()" },
  { label = "Telescope Vim options", cmd = "lua require('telescope.builtin').vim_options()" },
  { label = "Telescope Registers", cmd = "lua require('telescope.builtin').registers()" },
  { label = "Telescope Keymaps", cmd = "lua require('telescope.builtin').keymaps()" },
  { label = "Telescope Filetypes", cmd = "lua require('telescope.builtin').filetypes()" },
  { label = "Telescope Highlights", cmd = "lua require('telescope.builtin').highlights()" },
  { label = "Telescope Resume last picker", cmd = "lua require('telescope.builtin').resume()" }, -- Inception?
  { label = "Telescope Pickers", cmd = "lua require('telescope.builtin').pickers()" },
  -- Telescope LSP pickers
  { label = "Telescope LSP references", cmd = "lua require('telescope.builtin').lsp_references()" },
  { label = "Telescope LSP incoming calls", cmd = "lua require('telescope.builtin').lsp_incoming_calls()" },
  { label = "Telescope LSP outgoing calls", cmd = "lua require('telescope.builtin').lsp_outgoing_calls()" },
  { label = "Telescope LSP document symbols", cmd = "lua require('telescope.builtin').lsp_document_symbols()" },
  { label = "Telescope LSP workspace symbols", cmd = "lua require('telescope.builtin').lsp_workspace_symbols()" },
  { label = "Telescope LSP dynamic workspace symbols", cmd = "lua require('telescope.builtin').lsp_dynamic_workspace_symbols()" },
  { label = "Telescope Diagnostics", cmd = "lua require('telescope.builtin').diagnostics()" },
  { label = "Telescope LSP implementations", cmd = "lua require('telescope.builtin').lsp_implementations()" },
  { label = "Telescope LSP definitions", cmd = "lua require('telescope.builtin').lsp_definitions()" },
  { label = "Telescope LSP type definitions", cmd = "lua require('telescope.builtin').lsp_type_definitions()" },
  -- Telescope git pickers
  { label = "Telescope Git commits", cmd = "lua require('telescope.builtin').git_commits()" },
  { label = "Telescope Git branches", cmd = "lua require('telescope.builtin').git_branches()" },
  { label = "Telescope Git status", cmd = "lua require('telescope.builtin').git_status()" },
  { label = "Telescope Git stash", cmd = "lua require('telescope.builtin').git_stash()" },
  -- Telescope Treesitter pickers
  { label = "Telescope Treesitter", cmd = "lua require('telescope.builtin').treesitter()" },
  -- Telescope list pickers
  { label = "Telescope Planets", cmd = "lua require('telescope.builtin').planets()" },
  { label = "Telescope Built-in pickers", cmd = "lua require('telescope.builtin').builtin()" },
  { label = "Telescope Lua reloader", cmd = "lua require('telescope.builtin').reloader()" },
  { label = "Telescope Symbols", cmd = "lua require('telescope.builtin').symbols()" },
  -- Treesitter
  { label = "Treesitter Toggle Highlighting", cmd = "lua vim.cmd('TSBufToggle highlight')" },
  { label = "Treesitter Inspect Tree", cmd = "InspectTree" },
  { label = "Treesitter Install info", cmd = "TSInstallInfo" },
  { label = "Treesitter check health", cmd = "checkhealth nvim-treesitter" },
  -- Diagnostics
  { label = "Diagnostics Buffer ", cmd = "lua print(vim.inspect(vim.diagnostic.get(0)))" },
  { label = "Diagnostics Workspace ", cmd = "lua print(vim.inspect(vim.diagnostic.get()))" },
  { label = "Diagnostics Cursor ", cmd = "lua print(vim.inspect(vim.diagnostic.get_cursor()))" },
  -- Trouble
  { label = "Trouble diagnostics", cmd = "Trouble diagnostics" },
  { label = "Trouble fzf", cmd = "Trouble fzf" },
  { label = "Trouble fzf_files", cmd = "Trouble fzf" },
  { label = "Trouble loclist", cmd = "Trouble loclist" },
  { label = "Trouble lsp", cmd = "Trouble lsp" },
  { label = "Trouble lsp_command", cmd = "Trouble lsp_command" },
  { label = "Trouble lsp_declarations", cmd = "Trouble lsp_declarations" },
  { label = "Trouble lsp_definitions", cmd = "Trouble lsp_definitions" },
  { label = "Trouble lsp_document_symbols", cmd = "Trouble lsp_document_symbols" },
  { label = "Trouble lsp_implementations", cmd = "Trouble lsp_implementations" },
  { label = "Trouble lsp_incoming_calls", cmd = "Trouble lsp_incoming_calls" },
  { label = "Trouble lsp_outgoing_calls", cmd = "Trouble lsp_outgoing_calls" },
  { label = "Trouble lsp_references", cmd = "Trouble lsp_references" },
  { label = "Trouble lsp_type_definitions", cmd = "Trouble lsp_type_definitions" },
  { label = "Trouble qflist", cmd = "Trouble qflist" },
  { label = "Trouble quickfix", cmd = "Trouble quickfix" },
  { label = "Trouble symbols", cmd = "Trouble symbols" },
  { label = "Trouble telescope", cmd = "Trouble telescope" },
  { label = "Trouble telescope_files", cmd = "Trouble telescope_files" },
  -- General
  { label = "messages", cmd = "messages" },
  { label = "Reload Configuration", cmd = "lua vim.cmd('source ' .. vim.env.MYVIMRC)" },
  { label = "List Buffers", cmd = "lua print(vim.inspect(vim.api.nvim_list_bufs()))" },
  { label = "Buffers", cmd = "buffers" },
  { label = "undolist", cmd = "undolist" },
  { label = "Toggle Relative Numbers", cmd = "lua vim.o.relativenumber = not vim.o.relativenumber" },
  { label = "Neovim Log", cmd = "lua vim.cmd('tabedit ' .. vim.fn.stdpath('state') .. '/log')" },
  { label = "Check Health", cmd = "lua vim.cmd('checkhealth')" },
  { label = "diffthis", cmd = "windo diffthis" },
  { label = "diffoff", cmd = "windo diffoff" },
  { label = "diffget", cmd = "windo diffget" },
  { label = "diffput", cmd = "windo diffput" },
  { label = "diffpatch", cmd = "windo diffpatch" },
  { label = "diffsplit", cmd = "windo diffsplit" },
  { label = "diffdiffupdate", cmd = "windo diffdiffupdate" },
}

local selections_to_print = {
  ["messages"] = true,
  ["CyclePythonExecCommand"] = true,
  ["CycleFilePicker"] = true,
  ["CycleSqlExecLang"] = true,
  ["TogglePrioritizeBuildScript"] = true,
  ["ToggleDebugPrint"] = true,
  ["ToggleUseFilePickerForCommands"] = true,
  ["ToggleUseCustomLspForSql"] = true,
  ["SkeletonCopy"] = true,
  ["SkeletonCopy!"] = true,
  ["PrintConfig"] = true,
  ["FileInfo"] = true,
}

local myconfig = require("myconfig")

local labels = {}
local label_to_cmd = {}
for _, e in ipairs(commands) do
  labels[#labels+1]    = e.label
  label_to_cmd[e.label] = e.cmd
end

local function run_command(label)
  local cmd = label_to_cmd[label]
  if selections_to_print[cmd] or cmd:match("^lua print") then
    local out = vim.fn.execute(cmd)
    vim.cmd("belowright 10split")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(out, "\n"))
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  else
    vim.cmd(cmd)
  end
end

vim.keymap.set('n', '<leader><leader>', function()
  local picker    = myconfig.get_file_picker()
  local use_fzf   = picker == myconfig.FilePicker.FZF
  local use_fzf_lua = picker == myconfig.FilePicker.FZF_LUA
  --local use_file_picker = (picker ~= myconfig.FilePicker.NONE)
  local use_file_picker = myconfig.use_file_picker_for_commands()

  if use_file_picker then
    if use_fzf then
      vim.fn["fzf#run"]({
        source  = labels,
        sink    = run_command,
        options = "--prompt 'Cmd> ' --reverse",
      })

    elseif use_fzf_lua then
      require("fzf-lua").fzf_exec(labels, {
        prompt  = "Cmd> ",
        actions = {
          ["default"] = function(selected)
            run_command(selected[1])
          end,
        },
      })

    else
      -- telescope
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values

      pickers.new({}, {
        prompt_title = "Choose Command",
        finder = finders.new_table({
          results   = commands,
          entry_maker = function(entry)
            return {
              value   = entry.cmd,
              display = entry.label,
              ordinal = entry.label,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            -- note: sel.display is the label
            run_command(sel.display)
          end)
          return true
        end,
      }):find()
    end

  else
    -- vim.ui.select fallback
    vim.ui.select(labels, { prompt = "Choose Command:" }, function(choice)
      if choice then
        run_command(choice)
      end
    end)
  end
end, { noremap = true, silent = true })

-- Alternative via inputlist
--vim.keymap.set('n', '<leader><leader>', function()
--  local menu = { "Choose Command:" }
--  for i, entry in ipairs(commands) do
--    menu[#menu + 1] = string.format("%d. %s", i, entry.label)
--  end
--
--  local choice = vim.fn.inputlist(menu)
--  -- inputlist returns 0 on <ESC> or invalid, or n for the line number chosen
--  if choice < 1 or choice > #commands then
--    return
--  end
--
--  local cmd = commands[choice].cmd
--
--  if selections_to_print[cmd] or cmd:match("^lua print") then
--    local out = vim.fn.execute(cmd)
--    vim.cmd("belowright 10split")
--    local buf = vim.api.nvim_create_buf(false, true)
--    vim.api.nvim_win_set_buf(0, buf)
--    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(out, "\n"))
--    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
--  else
--    vim.cmd(cmd)
--  end
--end, { noremap = true, silent = true })

