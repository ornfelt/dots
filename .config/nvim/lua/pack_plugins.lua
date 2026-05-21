require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- Mirror lazy.nvim's leader-key bootstrap (must run before any plugin loads).
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Mirror lazy's performance.rtp.disabled_plugins
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor = 1
vim.g.loaded_zipPlugin = 1

local plugins = require("pack")

local specs = {}
local seen = {}

local function add_spec(spec)
  if type(spec) == "string" then
    spec = { src = spec }
  end
  if type(spec) ~= "table" or not spec.src or seen[spec.src] then
    return
  end
  seen[spec.src] = true
  local s = { src = spec.src }
  if spec.version ~= nil then s.version = spec.version end
  if spec.name    ~= nil then s.name    = spec.name    end
  table.insert(specs, s)
end

-- Collect every spec (dependencies first so they're on rtp before their parent).
for _, plugin in ipairs(plugins) do
  if type(plugin) == "table" and plugin.src then
    if plugin.dependencies then
      for _, dep in ipairs(plugin.dependencies) do
        add_spec(dep)
      end
    end
    add_spec(plugin)
  end
end

-- Install/update + add to runtimepath
local ok, err = pcall(vim.pack.add, specs)
if not ok then
  vim.notify("vim.pack.add failed: " .. tostring(err), vim.log.levels.ERROR)
end

-- Run config functions in declaration order
for _, plugin in ipairs(plugins) do
  if type(plugin) == "table" and plugin.config then
    local cok, cerr = pcall(plugin.config)
    if not cok then
      vim.notify(
        "pack config error for " .. (plugin.src or "?") .. ": " .. tostring(cerr),
        vim.log.levels.ERROR
      )
    end
  end
end

-- cmd VimPackStatus: simple health check for vimpack
vim.api.nvim_create_user_command("VimPackStatus", function()
  local installed = vim.pack.get()
  local function norm(p) return (p or ""):gsub("\\", "/"):gsub("/$", "") end
  local rtp_set = {}
  for _, p in ipairs(vim.api.nvim_list_runtime_paths()) do
    rtp_set[norm(p)] = true
  end
  local missing = {}
  print(("vim.pack manages %d plugins"):format(#installed))
  print(string.rep("-", 70))
  for _, p in ipairs(installed) do
    local on_rtp   = rtp_set[norm(p.path)] == true
    local has_plug = vim.fn.isdirectory(p.path .. "/plugin") == 1
    local has_lua  = vim.fn.isdirectory(p.path .. "/lua") == 1
    print(string.format("  %-32s  rtp=%s  plugin=%s  lua=%s",
      p.spec.name,
      on_rtp and "Y" or "N",
      has_plug and "Y" or "-",
      has_lua and "Y" or "-"))
    if not on_rtp then table.insert(missing, p.spec.name) end
  end
  if #missing > 0 then
    print(string.rep("-", 70))
    print("Not on rtp: " .. table.concat(missing, ", "))
    print("Try: :packadd <name>")
  end
end, {})
