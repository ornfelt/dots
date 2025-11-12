local myconfig = require("myconfig")

-- lualine
local barhidden = false
--local function togglebar()
--    barhidden = not barhidden
--    require('lualine').hide({unhide = not barhidden})
--end
local function togglebar()
  barhidden = not barhidden
  if barhidden then
    vim.opt.laststatus = 0
  else
    vim.opt.laststatus = 2
  end
end

myconfig.map('n', '<leader>b', togglebar) -- Toggle lualine

-- lua calculator
vim.keymap.set("i", "<m-+>", function()
  vim.ui.input({ prompt = "Calc: " }, function(input)
    local calc = load("return " .. (input or ""))()
    if (calc) then
      vim.api.nvim_feedkeys(tostring(calc), "i", true)
    end
  end)
end)

vim.keymap.set("v", "<m-+>", function()
  -- local start_pos = vim.fn.getpos("'<")
  -- local end_pos = vim.fn.getpos("'>")
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  local selected_text = table.concat(lines, "\n")
  local calc = load("return " .. selected_text)()
  if calc then
    vim.fn.cursor(end_pos[2], end_pos[3])
    vim.api.nvim_put({tostring(calc)}, 'l', true, true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>k', true, false, true), 'n', true)
  end
end)

vim.keymap.set("n", "<m-+>", function()
  local current_line = vim.fn.getline('.')
  local calc = load("return " .. current_line)()
  if calc then
    local line_num = vim.fn.line('.')
    vim.fn.append(line_num, tostring(calc))
    -- All of these work
    -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('j', true, false, true), 'n', true)
    -- vim.fn.cursor(line_num + 1, 0)
    vim.cmd('normal! j')
    -- vim.api.nvim_exec('normal! j', false)
    -- vim.api.nvim_command('normal! j')
  end
end)

-- " Execute line under the cursor
-- nnoremap <leader>, yy:@"<CR>
--vim.api.nvim_set_keymap('n', '<leader>,', 'yy:@"<CR>', { noremap = true, silent = true })
--
-- Function to execute command under cursor or highlighted text
function execute_command()
  local mode = vim.fn.mode()
  local command

  if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is for visual block mode
    -- Yank selection to "v" register
    vim.cmd('normal! "vy')
    command = vim.fn.getreg("v")
  else
    command = vim.fn.getline('.')
  end

  -- Remove comment prefix and trim leading whitespace
  command = command:gsub("^%s*([#/]?/?%-?%-?)", "")
  command = command:gsub("^%s+", "")

  if myconfig.should_debug_print() then
    -- Copy to clipboard
    vim.fn.setreg('+', command)
    print("Copied to clipboard: " .. command)
  else
    -- Execute it
    vim.cmd(command)
  end
end

-- Try with these:
-- lua print(vim.fn.getenv("my_notes_path"))
-- lua print(vim.fn.getenv("code_root_dir"))
-- lua print(vim.fn.getenv("ps_profile_path"))
vim.api.nvim_set_keymap('n', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>,', ':lua execute_command()<CR>', { noremap = true, silent = true })

function count_characters()
  local mode = vim.api.nvim_get_mode().mode
  local text = ""

  if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is for visual block mode
    -- Yank selection to "v" register
    vim.cmd('normal! "vy')
    text = vim.fn.getreg("v")
  else
    -- Word under cursor
    text = vim.fn.expand("<cword>")
  end

  local char_count = #text
  print("Character count: " .. char_count)
end

-- Keybindings for counting characters
vim.api.nvim_set_keymap("n", "<leader>cc", ":lua count_characters()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<leader>cc", "<cmd>lua count_characters()<CR>", { noremap = true, silent = true })

-- Command for showing useful file info
-- Usage:
-- :FileInfo C:\local\testing_files\test1.txt
-- :FileInfo (uses current buffer)
-- :FileInfo % (uses current buffer explicitly)
-- :FileInfo $my_notes_path/wow.txt

local uv = vim.uv or vim.loop

local function human_lines(bytes)
  local KB = 1024
  local MB = KB * 1024
  local GB = MB * 1024
  local TB = GB * 1024
  local function f(n) return string.format("%.2f", n) end
  return {
    ("TB:    %s"):format(f(bytes / TB)),
    ("GB:    %s"):format(f(bytes / GB)),
    ("MB:    %s"):format(f(bytes / MB)),
    ("KB:    %s"):format(f(bytes / KB)),
    ("Bytes: %d"):format(bytes),
  }
end

local bit = bit or bit32
local band = bit.band

local function perms_octal(mode)
  -- lower 9 bits are rwx for user/group/other
  --local p = mode % 512 -- 0o777 == 511 in decimal modulus base
  local p = band(mode, 0x1FF)
  return string.format("%03o", p)
end

local function perms_rwx(mode)
  --local p = mode % 512
  local p = band(mode, 0x1FF)
  local bits = {
    0x100, 0x80, 0x40,  -- u: r w x
    0x20,  0x10, 0x8,   -- g: r w x
    0x4,   0x2,  0x1,   -- o: r w x
  }
  local letters = { "r","w","x","r","w","x","r","w","x" }
  local out = {}
  for i, b in ipairs(bits) do
    -- Note: bitwise operator not availble in some lua versions
    --out[i] = (p & b) ~= 0 and letters[i] or "-"
    out[i] = (band(p, b) ~= 0) and letters[i] or "-"
  end
  return table.concat(out)
end

local function file_type_char(stat_type)
  -- stat.type is usually "file","directory","link",...
  if stat_type == "directory" then return "d" end
  if stat_type == "link"      then return "l" end
  return "-" -- default to regular file
end

local function show_lines(lines)
  -- Could display in a scratch float or similar here...
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "FileInfo" })
end

local function collect_info(path)
  local stat = uv.fs_stat(path)
  if not stat then
    show_lines({ "FileInfo: cannot stat file:", path })
    return
  end

  local lines = {}
  table.insert(lines, ("File: %s"):format(path))

  -- sizes
  local sizes = human_lines(stat.size or 0)
  vim.list_extend(lines, sizes)

  -- linux
  local is_linux = (uv.os_uname().sysname or ""):lower():find("linux", 1, true) ~= nil
  if is_linux and stat.mode then
    local oct = perms_octal(stat.mode)
    local rwx = perms_rwx(stat.mode)
    table.insert(lines, "")
    table.insert(lines, ("Type: %s"):format(file_type_char(stat.type)))
    table.insert(lines, ("Perms: %s (%s)"):format(rwx, oct))
    if stat.uid ~= nil and stat.gid ~= nil then
      table.insert(lines, ("UID/GID: %s/%s"):format(stat.uid, stat.gid))
    end
  end

  -- Timestamps
  if stat.mtime and stat.mtime.sec then
    local mtime = os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec)
    table.insert(lines, ("Modified: %s"):format(mtime))
  end

  show_lines(lines)
end

local function fileinfo_cmd(opts)
  local path = opts.args
  if path == nil or path == "" then
    path = vim.api.nvim_buf_get_name(0)
  end
  if path == nil or path == "" then
    show_lines({ "FileInfo: current buffer has no file name." })
    return
  end
  collect_info(path)
end

vim.api.nvim_create_user_command(
  "FileInfo",
  fileinfo_cmd,
  { nargs = "?", complete = "file" }
)

