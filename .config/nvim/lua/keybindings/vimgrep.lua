local myconfig = require("myconfig")

-- Vimgrep 
-- myconfig.map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>0f/li')
-- myconfig.map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>0f/li') -- Search all
-- myconfig.map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>0f/li') -- Search dotfiles

function enter_vimgrep_command(pattern, use_current_word)
  --local current_word = use_current_word and vim.fn.expand("<cword>") or ""

  -- Support visual selection
  local current_word = ""
  if use_current_word then
    if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
      --current_word = vim.fn.getreg('"') -- Last yanked text
      local start_pos = vim.fn.getpos("v")
      local end_pos = vim.fn.getpos(".")
      if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
        start_pos, end_pos = end_pos, start_pos
      end

      local lines = vim.fn.getline(start_pos[2], end_pos[2])

      if #lines == 1 then
        -- Single line selection
        current_word = lines[1]:sub(start_pos[3], end_pos[3])
      else
        -- Multi-line selection, use only the last line
        --current_word = lines[#lines]:sub(1, end_pos[3])
        -- Just take current word to simplify this
        current_word = vim.fn.expand("<cword>")
      end
    else
      current_word = vim.fn.expand("<cword>")
    end
  end

  --vim.ui.input({ prompt = 'vimgrep ' .. pattern .. ': ' }, function(input)
  vim.ui.input({ prompt = 'vimgrep ' .. pattern .. ': ', default = current_word }, function(input)
    if not input or input == '' then
      --vim.notify('No search keyword provided.', vim.log.levels.WARN)
      return
    end

    local directory, is_git_repo = myconfig.get_git_root()
    directory = directory:gsub('\\', '/')
    directory = directory:gsub('/+', '/')

    local cmd
    if is_git_repo then
      vim.cmd("lcd " .. directory)
      cmd = string.format(':vimgrep /%s/g `git ls-files`', input)
      -- This won't jump to first match due to 'j'
      --cmd = string.format(':vimgrep /%s/gj `git ls-files`', input)
    else
      cmd = string.format(':vimgrep /%s/g %s/%s', input, directory, pattern)
    end

    if myconfig.should_debug_print() then
      print(cmd)
    end

    vim.cmd(cmd)
    --vim.cmd('copen') -- Open quickfix window
    --vim.notify(string.format('vimgrep search executed for keyword: "%s"', input), vim.log.levels.INFO)
  end)
end

local function get_current_buffer_extension()
  if vim.bo.filetype == '' and vim.fn.expand('%') == '' then
    --vim.notify("Current buffer is not associated with a file.", vim.log.levels.WARN)
    return nil
  end

  local extension = vim.fn.fnamemodify(vim.fn.expand('%'), ':e')
  return extension
end

-- vim.keymap.set( 'n', '<M-f>', function() enter_vimgrep_command('**/*.txt') end, { noremap = true, silent = true })
--vim.keymap.set('n', '<M-f>', function()
--    local extension = get_current_buffer_extension()
--    if not extension then
--        extension = '.txt'
--    end
--    local pattern = '**/*.' .. extension
--    enter_vimgrep_command(pattern)
--end, { noremap = true, silent = true })

-- Helper function to set up vimgrep command
local function setup_vimgrep_command(use_current_word)
  local extension = get_current_buffer_extension() or 'txt'
  local pattern = '**/*.' .. extension
  enter_vimgrep_command(pattern, use_current_word)
end

-- bind m-f: vimgrep with word/selection in current extension (n,v)
vim.keymap.set({ 'n', 'v' }, '<M-f>', function()
  setup_vimgrep_command(true) -- Use word under cursor or selection
end, { noremap = true, silent = true })

-- bind m-c-f: vimgrep in current extension (n)
vim.keymap.set('n', '<M-C-f>', function()
  setup_vimgrep_command(false) -- Do not use word under cursor or selection
end, { noremap = true, silent = true })

-- bind m-g: vimgrep with word in all files (n)
vim.keymap.set( 'n', '<M-g>', function() enter_vimgrep_command('**/*.*', true) end, { noremap = true, silent = true })
-- bind m-s-g: vimgrep with word in dotfiles (n)
vim.keymap.set( 'n', '<M-G>', function() enter_vimgrep_command('**/.*', true) end, { noremap = true, silent = true })

-- :vimgrep /mypattern/j *.xml *.js
-- :vimgrep /mypattern/g **/*.{c,cpp,cs}
-- The 'g' option specifies that all matches for a search will be returned instead of just one per
-- line, and the 'j' option specifies that Vim will not jump to the first match automatically.
local function construct_glob_pattern(extensions)
  return '**/*.{' .. table.concat(extensions, ',') .. '}'
end

-- bind m-s-f: vimgrep with word in code files (n)
vim.keymap.set('n', '<M-F>', function()
  local extensions = { 'c', 'cpp', 'cs', 'css', 'go', 'h', 'hpp', 'html', 'java', 'js', 'jsx', 'json', 'lua', 'php', 'py', 'rs', 'sql', 'ts', 'tsx', 'xml', 'zig' }
  local pattern = construct_glob_pattern(extensions)
  enter_vimgrep_command(pattern, true)
end, { noremap = true, silent = true })

