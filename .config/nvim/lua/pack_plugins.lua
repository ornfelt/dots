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
