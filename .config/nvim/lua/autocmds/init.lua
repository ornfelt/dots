require("autocmds.hellow")
require("autocmds.code_autocmds")
require("autocmds.sql_autocmds")
require("autocmds.treesitter_autocmds")

-- Automatic command to adjust format options
vim.cmd [[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
]]

-- vim.api.nvim_command('autocmd BufEnter *.tex :set wrap linebreak nolist spell')

-- Automatically load main session when entering vim
-- vim.api.nvim_create_autocmd("VimEnter", {
--   pattern = "*",
--   command = "source ~/.vim/sessions/s.vim"
-- })

-- Autocommand to run pdflatex on write for .tex files
local function run_pdflatex()
  local file = vim.fn.expand('%:p')
  vim.fn.jobstart({'pdflatex', file})
end

if vim.fn.executable('pdflatex') == 1 then
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.tex',
    callback = run_pdflatex,
  })
end

-- This autocmd ensures that whenever you open a .txt or .sql file, vim will convert its line 
-- endings to DOS style (CRLF) by re-editing it as such.
vim.api.nvim_create_autocmd("BufRead", {
  -- pattern = "*",
  pattern = {"*.txt", "*.sql"},
  callback = function()
    vim.cmd('edit ++ff=dos %')
  end
})

local function update_wildignore(filetype)
  local wildignore = vim.opt.wildignore:get()

  if filetype == "rust" then
    if not vim.tbl_contains(wildignore, "*/target/*") then
      table.insert(wildignore, "*/target/*")
    end
  elseif filetype == "cs" then
    if not vim.tbl_contains(wildignore, "*/bin/*") then
      table.insert(wildignore, "*/bin/*")
    end
    if not vim.tbl_contains(wildignore, "*/obj/*") then
      table.insert(wildignore, "*/obj/*")
    end
  elseif filetype == "cpp" or filetype == "c" then
    if not vim.tbl_contains(wildignore, "*/build/*") then
      table.insert(wildignore, "*/build/*")
    end
  end

  vim.opt.wildignore = wildignore
end

-- use leader-, on line below
-- :lua print(vim.inspect(vim.opt.wildignore:get()))
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = { "*.rs", "*.cs", "*.cpp", "*.c" },
  callback = function()
    local filetype = vim.bo.filetype
    update_wildignore(filetype)
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- 2 spaces for tabs in specified files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  --pattern = {"lua", "javascript"},
  callback = function()
    vim.bo.shiftwidth = 2  -- Number of spaces to use for each step of (auto)indent
    vim.bo.tabstop = 2     -- Number of spaces that a <Tab> counts for
    vim.bo.softtabstop = 2 -- Number of spaces that a <Tab> inserts
    vim.bo.expandtab = true -- Use spaces instead of tabs
  end,
})

-- Enable line numbers in all windows, even new tabs
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  callback = function()
    vim.wo.number = true
  end,
})

