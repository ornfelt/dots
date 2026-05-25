-- Copies markdown files into the md viewer project and keeps them
-- synced on save. Picks py / ts variant from myconfig (UseTsMdViewer).
--
-- Commands:
--   :MdCopy        Copy current .md file to the viewer project (captures git info if any)
--   :MdCopyAs      Like MdCopy but choose dest filename (avoids collisions)
--   :MdUnlink      Remove the current file from the viewer project + metadata
--   :MdOpen        Open the viewer in browser at this file's page
--
-- Background sync (BufWritePost) only fires when md_files/<basename> already
-- exists - i.e. when you've previously :MdCopy'd that file.

require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

local M = {}
local uv = vim.uv or vim.loop

-- variant + paths
local DEFAULT_PORTS = { py = 5000, ts = 5001 }

local function variant()
  return myconfig.should_use_ts_md_viewer() and "ts" or "py"
end

local function port()
  return DEFAULT_PORTS[variant()] or 5000
end

local function code_root()
  local r = myconfig.code_root_dir
  if not r or r == "" then return nil end
  -- myconfig appends a trailing slash; strip so we can safely join below.
  return (r:gsub("/+$", ""))
end

local function project_dir()
  local r = code_root()
  if not r then return nil end
  return r .. "/Code2/General/utils/md/" .. variant()
end

local function md_dir()
  local p = project_dir()
  return p and (p .. "/md_files") or nil
end

local function meta_file()
  local p = project_dir()
  return p and (p .. "/metadata.json") or nil
end

local function norm(p)
  if not p then return nil end
  return (p:gsub("\\", "/"))
end

-- io helpers

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function write_file(path, data)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(data)
  f:close()
  return true
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

local function read_json(path)
  local s = read_file(path)
  if not s or s == "" then return {} end
  local ok, t = pcall(vim.json.decode, s)
  if not ok or type(t) ~= "table" then return {} end
  return t
end

local function write_json(path, tbl)
  return write_file(path, vim.json.encode(tbl))
end

local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

-- git

local function git(args, cwd)
  local cmd = { "git", "-C", cwd }
  for _, a in ipairs(args) do table.insert(cmd, a) end
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil end
  return vim.fn.trim(out)
end

local function get_git_info(file_path)
  local dir = vim.fn.fnamemodify(file_path, ":h")
  local root = git({ "rev-parse", "--show-toplevel" }, dir)
  if not root or root == "" then return nil end
  local remote = git({ "config", "--get", "remote.origin.url" }, dir) or ""
  local branch = git({ "rev-parse", "--abbrev-ref", "HEAD" }, dir) or "main"

  local nfile = norm(file_path)
  local nroot = norm(root)
  local rel = nfile
  if nfile:sub(1, #nroot + 1) == nroot .. "/" then
    rel = nfile:sub(#nroot + 2)
  end

  return {
    git_root = root,
    remote_url = remote,
    branch = branch,
    relative_path = rel,
    source_path = nfile,
  }
end

-- core

local function is_md(file)
  return vim.fn.fnamemodify(file, ":e"):lower() == "md"
end

local function notify(msg, level, silent)
  if silent then return end
  vim.notify("[md] " .. msg, level or vim.log.levels.INFO)
end

--- Copy file to project. Async copy via libuv; metadata is small + sync.
---@param opts { silent: boolean?, file: string?, dest_name: string? }
function M.copy(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local file = opts.file or vim.fn.expand("%:p")

  if not file or file == "" then
    notify("no file", vim.log.levels.ERROR, silent); return
  end
  if not is_md(file) then
    notify("not a markdown file: " .. file, vim.log.levels.ERROR, silent); return
  end

  local mdd = md_dir()
  local mf = meta_file()
  if not mdd or not mf then
    notify("code_root_dir not set", vim.log.levels.ERROR, silent); return
  end
  ensure_dir(mdd)

  local name = opts.dest_name or vim.fn.fnamemodify(file, ":t")
  local dst = mdd .. "/" .. name
  local nfile = norm(file)
  local v = variant()

  uv.fs_copyfile(file, dst, function(err)
    vim.schedule(function()
      if err then
        notify("copy failed: " .. tostring(err), vim.log.levels.ERROR, silent); return
      end
      local meta = read_json(mf)
      local existing = meta[name] or {}
      local gi = get_git_info(file)
      if gi then
        meta[name] = gi
      else
        existing.source_path = nfile
        meta[name] = existing
      end
      write_json(mf, meta)
      notify("copied: " .. name .. "  ->  " .. v, vim.log.levels.INFO, silent)
    end)
  end)
end

--- Background sync: only runs if md_files/<basename> already exists
--- (i.e. you previously :MdCopy'd that file). Skips if metadata says the
--- dest belongs to a different source path, to avoid clobbering.
local function background_sync()
  local file = norm(vim.fn.expand("%:p"))
  if not file or file == "" or not is_md(file) then return end

  local mdd = md_dir()
  if not mdd then return end

  local name = vim.fn.fnamemodify(file, ":t")
  local dst = mdd .. "/" .. name

  -- Primary check: only sync if the file already exists in the project.
  if not file_exists(dst) then return end

  -- Disambiguation: if metadata says dest belongs to a different source, skip.
  local mf = meta_file()
  local meta = mf and read_json(mf) or {}
  local entry = meta[name]
  if entry and entry.source_path and norm(entry.source_path) ~= file then
    return
  end

  uv.fs_copyfile(file, dst, function(_) end) -- silently swallow errors
end

function M.unlink(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local file = vim.fn.expand("%:p")
  local name = vim.fn.fnamemodify(file, ":t")
  local mdd = md_dir()
  local mf = meta_file()
  if not mdd or not mf then
    notify("code_root_dir not set", vim.log.levels.ERROR, silent); return
  end
  local dst = mdd .. "/" .. name
  uv.fs_unlink(dst, function(_)
    vim.schedule(function()
      local meta = read_json(mf)
      if meta[name] then
        meta[name] = nil
        write_json(mf, meta)
      end
      notify("unlinked: " .. name, vim.log.levels.INFO, silent)
    end)
  end)
end

function M.open_in_browser()
  local file = vim.fn.expand("%:p")
  local name = vim.fn.fnamemodify(file, ":t")
  if not is_md(file) then
    notify("not a markdown file", vim.log.levels.ERROR); return
  end
  local url = string.format("http://127.0.0.1:%d/view/%s", port(), name)
  local opener
  if vim.fn.has("mac") == 1 then
    opener = { "open", url }
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    opener = { "cmd", "/c", "start", "", url }
  else
    opener = { "xdg-open", url }
  end
  vim.fn.jobstart(opener, { detach = true })
end

function M.setup(user_opts)
  user_opts = user_opts or {}

  -- cmd MdCopy: MdCopy
  vim.api.nvim_create_user_command("MdCopy", function()
    M.copy({ silent = false })
  end, { desc = "Copy current md file to viewer project" })

  -- cmd MdCopyAs: MdCopyAs
  vim.api.nvim_create_user_command("MdCopyAs", function(args)
    local name = args.args
    if name == "" then
      vim.notify("[md] usage: :MdCopyAs <filename.md>", vim.log.levels.ERROR); return
    end
    if not name:lower():match("%.md$") then name = name .. ".md" end
    M.copy({ silent = false, dest_name = name })
  end, { desc = "Copy current md file with a chosen destination name", nargs = 1 })

  -- cmd MdUnlink: MdUnlink
  vim.api.nvim_create_user_command("MdUnlink", function()
    M.unlink({ silent = false })
  end, { desc = "Remove current md file from viewer project" })

  -- cmd MdOpen: MdOpen
  vim.api.nvim_create_user_command("MdOpen", function()
    M.open_in_browser()
  end, { desc = "Open current md file in the viewer" })

  if user_opts.auto_sync ~= false then
    local grp = vim.api.nvim_create_augroup("MdSync", { clear = true })
    -- autocmd *.md: (BufWritePost)
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = grp,
      pattern = "*.md",
      callback = function()
        -- Defer slightly so write completes; sync runs async via libuv.
        vim.defer_fn(background_sync, 50)
      end,
    })
  end
end

return M
