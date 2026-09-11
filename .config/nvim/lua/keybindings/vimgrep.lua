require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

-- Vimgrep
-- myconfig.map('n', '<M-f>', ':vimgrep //g **/*.txt<C-f><Esc>0f/li')
-- myconfig.map('n', '<M-g>', ':vimgrep //g **/*.*<C-f><Esc>0f/li') -- Search all
-- myconfig.map('n', '<M-G>', ':vimgrep //g **/.*<C-f><Esc>0f/li') -- Search dotfiles

-- Prefill the prompt with the word under the cursor (or the visual selection).
-- Set to false to always start from an empty prompt.
local USE_WORD_UNDER_CURSOR = true

-- What a git bind searches when the directory is not a repository: the cwd,
-- limited to these extensions
local code_extensions = {
  'c', 'cpp', 'cs', 'css', 'go', 'h', 'hpp', 'html', 'java', 'js', 'jsx',
  'json', 'lua', 'php', 'py', 'rs', 'sql', 'ts', 'tsx', 'xml', 'zig'
}

-- Never worth searching, and huge
local GIT_DIR = '.git'

-- The word under the cursor, or the visual selection when there is one
local function current_word()
  if not USE_WORD_UNDER_CURSOR then
    return ""
  end

  -- Support visual selection
  if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
    --return vim.fn.getreg('"') -- Last yanked text
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
      start_pos, end_pos = end_pos, start_pos
    end

    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    if #lines == 1 then
      -- Single line selection
      return lines[1]:sub(start_pos[3], end_pos[3])
    end

    -- Multi-line selection, just take current word to simplify this
    return vim.fn.expand("<cword>")
  end

  return vim.fn.expand("<cword>")
end

local function get_current_buffer_extension()
  if vim.bo.filetype == '' and vim.fn.expand('%') == '' then
    --vim.notify("Current buffer is not associated with a file.", vim.log.levels.WARN)
    return nil
  end

  local extension = vim.fn.fnamemodify(vim.fn.expand('%'), ':e')
  if extension == '' then
    return nil
  end
  return extension
end

-- The normalization the vimgrep command line has always had, plus dropping the
-- trailing slash so a pattern can be glued straight onto it
local function normalize_dir(dir)
  dir = dir:gsub('\\', '/')
  dir = dir:gsub('/+', '/')
  if #dir > 1 then
    dir = dir:gsub('/$', '')
  end
  return dir
end

-- A scope is one bind: { git, recursive, hidden, everything, ext }. Where it
-- searches from, and whether git can be asked about that directory at all.
local function search_root(scope)
  if scope.git then
    local directory, is_git_repo = myconfig.get_git_root()
    return normalize_dir(directory), is_git_repo
  end
  return normalize_dir(vim.fn.getcwd()), false
end

-- The extensions a scope is limited to, and how the prompt spells that
local function scope_extensions(scope, is_git_repo)
  if scope.ext == 'current' then
    local extension = get_current_buffer_extension() or 'txt'
    return { extension }, '*.' .. extension
  end
  if scope.git and not is_git_repo then
    return code_extensions, 'code files'
  end
  return nil, nil
end

-- 'wildignore' is a list of vim file patterns, where '*' crosses directories.
-- :vimgrep drops them on its own; the other three backends are told below.
local function wildignore_patterns()
  local ok, patterns = pcall(function() return vim.opt.wildignore:get() end)
  if not ok or type(patterns) ~= 'table' then
    return {}
  end
  return patterns
end

-- 'ignorecase' and 'smartcase', in the one form every external tool understands
local function ignore_case(pattern)
  if not vim.o.ignorecase then
    return false
  end
  if vim.o.smartcase and pattern:match('%u') then
    return false
  end
  return true
end

-- ripgrep globs use '**' for what a wildignore pattern uses '*' for; one
-- without a separator already matches at any depth
local function ripgrep_ignore_globs()
  local globs = {}
  for _, pattern in ipairs(wildignore_patterns()) do
    table.insert(globs, '!' .. (pattern:find('/') and pattern:gsub('%*+', '**') or pattern))
  end
  return globs
end

-- A git pathspec matches '*' across directories like vim does, but a leading
-- '*/' still wants a directory in front of it, so the top-level form goes too
local function gitgrep_exclude_pathspecs()
  local specs = {}
  for _, pattern in ipairs(wildignore_patterns()) do
    table.insert(specs, ':(exclude)' .. pattern)
    local without_leading_dir = pattern:match('^%*/(.+)$')
    if without_leading_dir then
      table.insert(specs, ':(exclude)' .. without_leading_dir)
    end
  end
  return specs
end

-- grep takes a directory name or a file pattern, never a path pattern
local function grep_exclude_args()
  local args = {}
  for _, pattern in ipairs(wildignore_patterns()) do
    local directory = pattern:match('^%*/(.+)/%*$')
    table.insert(args, directory and ('--exclude-dir=' .. directory) or ('--exclude=' .. pattern))
  end
  return args
end

-- The files directly in one directory: grep has no depth limit of its own, so
-- the non-recursive search hands it the names. vim.fn.glob applies 'wildignore'.
local function toplevel_files(root, extensions, hidden)
  local suffixes = { '*' }
  if extensions then
    suffixes = {}
    for _, extension in ipairs(extensions) do
      table.insert(suffixes, '*.' .. extension)
    end
  end

  local files = {}
  for _, suffix in ipairs(suffixes) do
    local globs = { root .. '/' .. suffix }
    if hidden then
      table.insert(globs, root .. '/.' .. suffix)
    end
    for _, glob in ipairs(globs) do
      for _, file in ipairs(vim.fn.glob(glob, false, true)) do
        if vim.fn.isdirectory(file) == 0 then
          table.insert(files, file)
        end
      end
    end
  end
  return files
end

-- ripgrep: '--vimgrep' already prints "file:line:col:text"
local function ripgrep_argv(pattern, scope, root, is_git_repo, extensions)
  local argv = { 'rg', '--vimgrep', '--no-heading', '--color=never', '--no-messages' }
  table.insert(argv, ignore_case(pattern) and '--ignore-case' or '--case-sensitive')
  if not scope.recursive then
    table.insert(argv, '--max-depth=1')
  end
  -- only a git bind inside a repository lets .gitignore drop anything, and even
  -- that one stops once the search is asked for everything
  if scope.everything or not (scope.git and is_git_repo) then
    table.insert(argv, '--no-ignore')
  end
  if scope.hidden or scope.everything then
    table.insert(argv, '--hidden')
  end
  table.insert(argv, '--glob=!' .. GIT_DIR .. '/')
  for _, extension in ipairs(extensions or {}) do
    table.insert(argv, '--glob=*.' .. extension)
  end
  if not (scope.hidden or scope.everything) then
    -- an explicit --glob overrides ripgrep's own hidden-file filter, so the dot
    -- files it would have skipped on its own are spelled out here
    table.insert(argv, '--glob=!.*')
  end
  for _, glob in ipairs(ripgrep_ignore_globs()) do
    table.insert(argv, '--glob=' .. glob)
  end
  table.insert(argv, '-e')
  table.insert(argv, pattern)
  table.insert(argv, root)
  return argv
end

-- git grep: the pathspecs after '--' are the scope. '--no-index' is what lets
-- it search a plain directory - a cwd bind, or a git bind with no repository.
local function gitgrep_argv(pattern, scope, root, is_git_repo, extensions)
  local argv = {
    'git', '-C', root, '--no-pager', 'grep',
    '--line-number', '--column', '--no-color', '-I', '-E'
  }
  if ignore_case(pattern) then
    table.insert(argv, '--ignore-case')
  end

  if not (scope.git and is_git_repo) then
    table.insert(argv, '--no-index')
  elseif scope.everything then
    table.insert(argv, '--untracked')
    table.insert(argv, '--no-exclude-standard')
  end

  table.insert(argv, '-e')
  table.insert(argv, pattern)
  table.insert(argv, '--')

  if extensions then
    for _, extension in ipairs(extensions) do
      table.insert(argv, (scope.recursive and '*.' or ':(glob)*.') .. extension)
    end
  elseif not scope.recursive then
    table.insert(argv, ':(glob)*')
  end
  if not (scope.hidden or scope.everything) then
    table.insert(argv, ':(exclude).*')
    table.insert(argv, ':(exclude)*/.*')
  end
  vim.list_extend(argv, gitgrep_exclude_pathspecs())
  return argv
end

-- grep: no git awareness at all, so a git bind falls back to the walk a cwd
-- bind does, with 'wildignore' and the .git directory kept out of it
local function grep_argv(pattern, scope, root, extensions)
  local argv = {
    'grep', '--line-number', '--with-filename',
    '--binary-files=without-match', '--no-messages', '-E'
  }
  if ignore_case(pattern) then
    table.insert(argv, '--ignore-case')
  end

  if not scope.recursive then
    table.insert(argv, '-e')
    table.insert(argv, pattern)
    local files = toplevel_files(root, extensions, scope.hidden or scope.everything)
    if #files == 0 then
      return nil
    end
    vim.list_extend(argv, files)
    return argv
  end

  table.insert(argv, '--recursive')
  -- every --include comes before the --exclude options: grep reads the two as
  -- one ordered list, and an --include at the end of it lets everything through
  for _, extension in ipairs(extensions or {}) do
    table.insert(argv, '--include=*.' .. extension)
  end
  table.insert(argv, '--exclude-dir=' .. GIT_DIR)
  if not (scope.hidden or scope.everything) then
    table.insert(argv, '--exclude-dir=.*')
    table.insert(argv, '--exclude=.*')
  end
  vim.list_extend(argv, grep_exclude_args())
  table.insert(argv, '-e')
  table.insert(argv, pattern)
  table.insert(argv, root)
  return argv
end

-- "file:line:col:text" (ripgrep, git grep) or "file:line:text" (grep), with a
-- windows drive letter kept out of the ':' splitting
local function parse_location(line, with_column)
  -- the separator is what tells "C:/dir/x:1:2:hit" from a file named "a"
  local drive, rest = line:match('^(%a:[/\\])(.*)$')
  if not drive then
    drive, rest = '', line
  end

  if with_column then
    local file, lnum, col, text = rest:match('^(.-):(%d+):(%d+):(.*)$')
    if file then
      return drive .. file, tonumber(lnum), tonumber(col), text
    end
    return nil
  end

  local file, lnum, text = rest:match('^(.-):(%d+):(.*)$')
  if file then
    return drive .. file, tonumber(lnum), 1, text
  end
  return nil
end

-- Run one of the external backends and put its hits where :vimgrep puts them
local function run_external(argv, root, with_column, input)
  local command = table.concat(argv, ' ')

  if myconfig.should_debug_print() then
    print(command)
  end

  local output = vim.fn.systemlist(argv)
  -- all three exit 1 when nothing matched, and higher than that on a real error
  if vim.v.shell_error > 1 then
    vim.notify(table.concat(output, '\n'), vim.log.levels.ERROR)
    return
  end

  local items = {}
  for _, line in ipairs(output) do
    local file, lnum, col, text = parse_location(line, with_column)
    if file then
      -- git grep prints its paths relative to the directory it ran in
      if not file:match('^/') and not file:match('^%a:') then
        file = root .. '/' .. file
      end
      table.insert(items, { filename = file, lnum = lnum, col = col, text = text })
    end
  end

  if #items == 0 then
    vim.notify('No match: ' .. input, vim.log.levels.WARN)
    return
  end

  vim.fn.setqflist({}, ' ', { title = command, items = items })
  vim.cmd('cfirst') -- jump to the first match, like :vimgrep without 'j'
  --vim.cmd('copen') -- Open quickfix window
end

-- ':vimgrep' splits its file arguments on whitespace, and expands '%' and '#'
-- as the current and the alternate file
local function escape_file_arg(path)
  return (path:gsub('([ \t%%#])', '\\%1'))
end

-- What ':vimgrep' is handed: 'git ls-files' inside a repository (the way these
-- binds have always searched one), wildcards everywhere else - which is also
-- what makes 'wildignore' apply.
local function vimgrep_file_args(scope, root, is_git_repo, extensions)
  if scope.git and is_git_repo then
    -- the backtick command runs in the window's directory
    vim.cmd('lcd ' .. vim.fn.fnameescape(root))
    local ls = 'git ls-files'
    if scope.everything then
      ls = 'git ls-files --cached --others'
    elseif not scope.recursive then
      ls = 'git ls-files -- ' .. vim.fn.shellescape(':(glob)*')
    elseif not scope.hidden then
      ls = 'git ls-files -- ' .. vim.fn.shellescape(':(exclude).*')
        .. ' ' .. vim.fn.shellescape(':(exclude)*/.*')
    end
    return { '`' .. ls .. '`' }
  end

  local suffix = '*'
  if extensions then
    suffix = #extensions == 1 and ('*.' .. extensions[1])
      or ('*.{' .. table.concat(extensions, ',') .. '}')
  end

  local prefix = scope.recursive and '**/' or ''
  local args = { escape_file_arg(root .. '/' .. prefix .. suffix) }
  if scope.hidden or scope.everything then
    -- vim's '**' does not descend into a dot directory, so this reaches the dot
    -- files of the directories it did visit (ripgrep and grep go further)
    table.insert(args, escape_file_arg(root .. '/' .. prefix .. '.' .. suffix))
  end
  return args
end

-- The 'g' option specifies that all matches for a search will be returned instead of just one per
-- line, and the 'j' option specifies that Vim will not jump to the first match automatically.
local function run_vimgrep(input, scope, root, is_git_repo, extensions)
  local args = vimgrep_file_args(scope, root, is_git_repo, extensions)
  -- the pattern is delimited by '/', so one inside it has to be escaped
  local cmd = string.format(':vimgrep /%s/g %s', (input:gsub('/', '\\/')), table.concat(args, ' '))

  if myconfig.should_debug_print() then
    print(cmd)
  end

  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.notify(tostring(err):match('E%d+:[^\n]*') or tostring(err), vim.log.levels.WARN)
  end
  --vim.cmd('copen') -- Open quickfix window
end

-- The prompt says which backend is about to run, and over what
local function prompt_label(backend, scope, is_git_repo, extension_label)
  local parts = { backend, (scope.git and is_git_repo) and 'git' or 'cwd' }
  if extension_label then
    table.insert(parts, extension_label)
  end
  if not scope.recursive then
    table.insert(parts, 'top-level')
  end
  if scope.everything then
    table.insert(parts, '+ignored')
  elseif scope.hidden then
    table.insert(parts, '+hidden')
  end
  return table.concat(parts, ' ') .. ': '
end

-- Ask for the pattern, then let the configured backend fill the quickfix list.
-- Whatever is typed goes to the backend as it stands: spaces and all, and as a
-- regex in that backend's dialect (vim's for :vimgrep, ERE for the other three).
local function search(scope)
  local backend = myconfig.get_grep_backend()
  local root, is_git_repo = search_root(scope)
  local extensions, extension_label = scope_extensions(scope, is_git_repo)
  local default = current_word()

  vim.ui.input({
    prompt = prompt_label(backend, scope, is_git_repo, extension_label),
    default = default,
  }, function(input)
    if not input or input == '' then
      --vim.notify('No search keyword provided.', vim.log.levels.WARN)
      return
    end

    if backend == myconfig.GrepBackend.RIPGREP then
      run_external(ripgrep_argv(input, scope, root, is_git_repo, extensions), root, true, input)
    elseif backend == myconfig.GrepBackend.GITGREP then
      run_external(gitgrep_argv(input, scope, root, is_git_repo, extensions), root, true, input)
    elseif backend == myconfig.GrepBackend.GREP then
      local argv = grep_argv(input, scope, root, extensions)
      if argv then
        run_external(argv, root, false, input)
      else
        vim.notify('No match: ' .. input, vim.log.levels.WARN)
      end
    else
      run_vimgrep(input, scope, root, is_git_repo, extensions)
    end
  end)
end

-- bind m-f: grep every file below the cwd (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-f>', function()
  search({ recursive = true })
end, { noremap = true, silent = true })

-- bind m-s-f: the same, dot files included (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-F>', function()
  search({ recursive = true, hidden = true })
end, { noremap = true, silent = true })

-- bind m-c-f: the same, limited to the current file's extension (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-C-f>', function()
  search({ recursive = true, ext = 'current' })
end, { noremap = true, silent = true })

-- bind m-c-d: the cwd itself, dot files included, subdirectories left alone (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-C-d>', function()
  search({ hidden = true })
end, { noremap = true, silent = true })

-- bind m-g: grep the files of the repository around the cwd (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-g>', function()
  search({ git = true, recursive = true })
end, { noremap = true, silent = true })

-- bind m-s-g: the same, dot files included (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-G>', function()
  search({ git = true, recursive = true, hidden = true })
end, { noremap = true, silent = true })

-- bind m-c-g: the same, ignored and untracked files included (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-C-g>', function()
  search({ git = true, recursive = true, everything = true })
end, { noremap = true, silent = true })

-- bind m-c-r: the repository root itself, subdirectories left alone (n, v)
vim.keymap.set({ 'n', 'v' }, '<M-C-r>', function()
  search({ git = true, hidden = true })
end, { noremap = true, silent = true })
