require("trouble").setup({})

-- https://github.com/folke/trouble.nvim

--local trouble_keybinds = {
--  { "<leader>txx", "<cmd>Trouble diagnostics<CR>", "Diagnostics (Trouble)" },
--  { "<leader>txs", "<cmd>Trouble symbols focus=false<CR>", "Symbols (Trouble)" },
--  { "<leader>txl", "<cmd>Trouble lsp focus=false win.position=right<CR>", "LSP Definitions/References (Trouble)" },
--  { "<leader>txo", "<cmd>Trouble loclist<CR>", "Location List (Trouble)" },
--  { "<leader>txq", "<cmd>Trouble qflist<CR>", "Quickfix List (Trouble)" },
--}
--
--for _, keybind in ipairs(trouble_keybinds) do
--  vim.keymap.set("n", keybind[1], keybind[2], { desc = keybind[3], noremap = true, silent = true })
--end
--
--Telescope
--local actions = require("telescope.actions")
--local open_with_trouble = require("trouble.sources.telescope").open
--local add_to_trouble = require("trouble.sources.telescope").add
--
--local telescope = require("telescope")
--
--telescope.setup({
--  -- defaults = {
--  -- mappings = {
--  -- i = { ["<c-t>"] = open_with_trouble },
--  -- n = { ["<c-t>"] = open_with_trouble },
--  -- },
--  -- },
--})
--
--fzf-lua
--local config = require("fzf-lua.config")
--local actions = require("trouble.sources.fzf").actions
--config.defaults.actions.files["ctrl-t"] = actions.open
--

