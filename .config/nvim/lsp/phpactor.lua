require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local is_win = vim.fn.has('win32') == 1
if is_win and vim.fn.executable('wsl') == 1 then
  return {
    cmd = { 'wsl', '-d', 'arch', 'phpactor', 'language-server' },
    filetypes = { 'php' },
    root_markers = { 'composer.json', '.git' },
  }
else
  return {
    cmd = { 'phpactor', 'language-server' },
    filetypes = { 'php' },
    root_markers = { 'composer.json', '.git' },
  }
end

