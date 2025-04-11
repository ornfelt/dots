local myconfig = require("myconfig")

myconfig.map('n', '<leader>ws', "/\\s\\+$/<CR>") -- Show extra whitespace
myconfig.map('n', '<leader>wr', ':%s/\\s\\+$<CR>') -- Remove all extra whitespace
myconfig.map('n', '<leader>wu', ':%s/\\%u200b//g<CR>') -- Remove all extra unicode chars
myconfig.map('n', '<leader>wb', ':%s/[[:cntrl:]]//g<CR>') -- Remove all hidden characters
--myconfig.map('n', '<leader>wf', 'gqG<C-o>zz') -- Format rest of the text with vim formatting, go back and center screen

myconfig.map('v', '<leader>gu', ':s/\\<./\\u&/g<CR>:noh<CR>:noh<CR>') -- Capitalize first letter of each word on visually selected line

function ReplaceQuotes()
  vim.cmd([[
    silent! %s/[’‘’]/'/g
    silent! %s/[“”]/"/g
    ]])
end

vim.api.nvim_set_keymap('n', '<leader>wq', ':lua ReplaceQuotes()<CR>', { noremap = true, silent = true })

-- Format file
function format_file()
  local filetype = vim.bo.filetype

  if filetype == "json" then
    if myconfig.is_callable("jq") then
      vim.cmd([[%!jq .]])
    elseif myconfig.is_callable("python") then
      vim.cmd([[%!python -m json.tool]])
    else
      vim.cmd('echo "No JSON formatter available!"')
    end

  elseif filetype == "xml" then
    if myconfig.is_callable("xmllint") then
      vim.cmd([[%!xmllint --format -]])
    elseif myconfig.is_callable("python") then
      vim.cmd([[%!python -c "import sys, xml.dom.minidom as m; print(m.parse(sys.stdin).toprettyxml())"]])
    else
      vim.cmd('echo "No XML formatter available!"')
    end

  else
    vim.cmd('echo "Unsupported file type!"')
  end
end

vim.api.nvim_set_keymap('n', '<leader>=', ':lua format_file()<CR>', { noremap = true, silent = true })

