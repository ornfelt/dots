-- TODO: these binds are not realistically sane... But they work for testing purposes :)

-- movement
vim.keymap.set({ 'n', 'v' }, '<leader>twk', '<cmd>Treewalker Up<cr>',    { silent = true })
vim.keymap.set({ 'n', 'v' }, '<leader>twj', '<cmd>Treewalker Down<cr>',  { silent = true })
vim.keymap.set({ 'n', 'v' }, '<leader)twh', '<cmd>Treewalker Left<cr>',  { silent = true })
vim.keymap.set({ 'n', 'v' }, '<leader>twl', '<cmd>Treewalker Right<cr>', { silent = true })

-- swapping
vim.keymap.set('n', '<leader>twK', '<cmd>Treewalker SwapUp<cr>',     { silent = true })
vim.keymap.set('n', '<leader>twJ', '<cmd>Treewalker SwapDown<cr>',   { silent = true })
vim.keymap.set('n', '<leader>twH', '<cmd>Treewalker SwapLeft<cr>',   { silent = true })
vim.keymap.set('n', '<leader>twL', '<cmd>Treewalker SwapRight<cr>',  { silent = true })

