require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local myconfig = require("myconfig")

local function get_build_flags_from_goflags()
  local handle = io.popen("go env GOFLAGS 2>/dev/null")
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()
  if not result then return nil end

  result = result:gsub("%s+$", "")

  if result == "" then return nil end

  local flags = {}
  for flag in result:gmatch("%S+") do
    table.insert(flags, flag)
  end

  if #flags > 0 then return flags end
  return nil
end

local function is_go_file()
  local ft = vim.bo.filetype
  if ft == "go" or ft == "gomod" or ft == "gosum" then
    return true
  end

  local name = vim.api.nvim_buf_get_name(0)
  return name:match("%.go$") ~= nil
      or name:match("/go%.mod$") ~= nil
      or name:match("/go%.sum$") ~= nil
      or name:match("\\go%.mod$") ~= nil
      or name:match("\\go%.sum$") ~= nil
end

local goflags = get_build_flags_from_goflags()
if myconfig.should_debug_print() and is_go_file() then
  if goflags then
    print("[gopls] GOFLAGS buildFlags: " .. table.concat(goflags, ", "))
  else
    print("[gopls] GOFLAGS: (not set)")
  end
end

return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gosum' },
  root_markers = {
    'go.mod',
    'go.sum',
  },
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        --fieldalignment = true,
        inferTypeArgs = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      staticcheck = true,
      gofumpt = true,
      semanticTokens = true,
      -- reads from go env GOFLAGS
      buildFlags = goflags,
      -- or, uncomment a hardcoded line below to override:
      --buildFlags = { "-tags=appconfig" },
      --buildFlags = { "-tags=appconfig tests" },
      --buildFlags = { "-tags=with_debug_rendering async_loader", },
      --buildFlags = { "-tags=async cimgui with_performance", },
    },
  },
}
