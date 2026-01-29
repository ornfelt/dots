-- TODO: these binds are not realistically sane... But they work for testing purposes :)

-- movement
-- bind leader-twk: Treewalker Up (n, v)
vim.keymap.set({ 'n', 'v' }, '<leader>twk', '<cmd>Treewalker Up<cr>',    { silent = true })
-- bind leader-twj: Treewalker Down (n, v)
vim.keymap.set({ 'n', 'v' }, '<leader>twj', '<cmd>Treewalker Down<cr>',  { silent = true })
-- bind leader-twh: Treewalker Left (n, v)
vim.keymap.set({ 'n', 'v' }, '<leader)twh', '<cmd>Treewalker Left<cr>',  { silent = true })
-- bind leader-twl: Treewalker Right (n, v)
vim.keymap.set({ 'n', 'v' }, '<leader>twl', '<cmd>Treewalker Right<cr>', { silent = true })

-- swapping
-- bind leader-twK: Treewalker SwapUp (n)
vim.keymap.set('n', '<leader>twK', '<cmd>Treewalker SwapUp<cr>',     { silent = true })
-- bind leader-twJ: Treewalker SwapDown (n)
vim.keymap.set('n', '<leader>twJ', '<cmd>Treewalker SwapDown<cr>',   { silent = true })
-- bind leader-twH: Treewalker SwapLeft (n)
vim.keymap.set('n', '<leader>twH', '<cmd>Treewalker SwapLeft<cr>',   { silent = true })
-- bind leader-twL: Treewalker SwapRight (n)
vim.keymap.set('n', '<leader>twL', '<cmd>Treewalker SwapRight<cr>',  { silent = true })

