--return {
--  cmd = { 'sqls' },
--  filetypes = { 'sql', 'mysql' },
--  root_markers = { '.git' },
--  settings = {
--    sqls = {
--      connections = {
--        {
--          driver = 'mysql',
--          dataSourceName = 'acore:acore@tcp(localhost:3306)/acore_world?parseTime=true',
--        },
--      },
--    },
--  },
--}

local function read_connections_from_file()
  local is_windows = vim.fn.has("win32") == 1
  --local uv = vim.loop
  --local home = uv.os_homedir() or vim.env.HOME or "/home/jonas"
  local home = vim.env.HOME or "/home/jonas"
  local cfg_path = is_windows and "C:/local/sqls_config.txt" or (home .. "/Documents/local/sqls_config.txt")

  local fd = io.open(cfg_path, "r")
  if not fd then
    return {}, cfg_path
  end

  local connections = {}
  for line in fd:lines() do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^#") then
      local driver, dsn = trimmed:match("^(%w+)%s*:%s*(.+)$")
      if driver and dsn then
        table.insert(connections, {
          driver = driver,
          dataSourceName = dsn,
        })
      end
    end
  end
  fd:close()

  -- Debug
  --if #connections > 0 then
  --  local lines = { "sqls: connections from " .. cfg_path .. ":" }
  --  for i, c in ipairs(connections) do
  --    lines[#lines+1] = string.format("  [%d] driver=%s, dataSourceName=%s", i, c.driver, c.dataSourceName)
  --  end
  --  vim.schedule(function()
  --    for _, l in ipairs(lines) do vim.notify(l) end
  --  end)
  --end

  return connections, cfg_path
end

local connections, used_path = read_connections_from_file()

return {
  cmd = { 'sqls' },
  filetypes = { 'sql', 'mysql' },
  root_markers = { '.git' },
  settings = {
    sqls = {
      connections = connections,
    },
  },
}

