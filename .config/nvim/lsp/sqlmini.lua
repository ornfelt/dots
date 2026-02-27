require('dbg_log').log_file(debug.getinfo(1, 'S').source)

---@type vim.lsp.Config
return (function()
  local base_dir = os.getenv("code_root_dir")
  if not base_dir then
    if vim.fn.has("win32") == 1 then
      base_dir = os.getenv("USERPROFILE")
    else
      base_dir = os.getenv("HOME")
    end
  end

  --local exe
  --if vim.fn.has("win32") == 1 then
  --  exe = base_dir .. [[\Code2\C#\my_csharp\SqlMiniLsp\bin\Debug\net8.0\SqlMiniLsp.exe]]
  --else
  --  exe = base_dir .. "/Code2/C#/my_csharp/SqlMiniLsp/bin/Debug/net9.0/SqlMiniLsp"
  --end

  -- build dynamically and support net* dir
  local is_win = vim.fn.has("win32") == 1
  local sep = is_win and "\\" or "/"
  local project_dir = base_dir .. sep .. table.concat({
    "Code2", "C#", "my_csharp", "SqlMiniLsp"
  }, sep)
  local bin_debug = project_dir .. sep .. "bin" .. sep .. "Debug"

  -- find candidate TFM dirs: bin/Debug/net*/
  local tfm_dirs = vim.fn.glob(bin_debug .. sep .. "net*", true, true) -- list
  table.sort(tfm_dirs) -- lexicographic; net10.0 sorts after net9.0, etc.

  -- pick the last one
  local tfm_dir = tfm_dirs[#tfm_dirs]
  if not tfm_dir or tfm_dir == "" then
    error("No net* folder found under: " .. bin_debug)
  end

  local exe_name = is_win and "SqlMiniLsp.exe" or "SqlMiniLsp"
  local exe = tfm_dir .. sep .. exe_name

  --print("using sqlminilsp exe: " .. exe)

  local myconfig = require('myconfig')
  local filetypes
  if myconfig.should_use_custom_lsp_for_sql() then
    filetypes = { "sql", "mysql" }
  else
    filetypes = { "csql" }
  end

  return {
    cmd = { exe, "--stdio" },
    filetypes = filetypes,
    -- optional root inference (Neovim 0.11+)
    root_markers = { ".git", "sqlproj" },
    -- or, explicitly:
    -- root_dir = function(fname)
    --   local util = require("lspconfig.util")
    --   return util.root_pattern(".git")(fname) or vim.loop.cwd()
    -- end,
    -- settings = { }, -- none yet
  }
end)()

