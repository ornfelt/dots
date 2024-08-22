require('telescope').setup({})

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
        builtin.git_files()
    else
        builtin.find_files()
    end
end
vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>lua project_files()<CR>', { noremap = true, silent = true })

--vim.api.nvim_set_keymap('n', '<leader>tf', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', '<M-a>', '<cmd>Telescope git_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-A>', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>tg', '<cmd>Telescope live_grep<CR>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', '<leader>tb', '<cmd>Telescope buffers<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-s>', '<cmd>Telescope buffers<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>th', '<cmd>Telescope help_tags<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>td', '<cmd>Telescope lsp_definitions<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>tr', '<cmd>Telescope lsp_references<CR>', { noremap = true, silent = true })

