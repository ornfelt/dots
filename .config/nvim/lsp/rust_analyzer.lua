require('dbg_log').log_file(debug.getinfo(1, 'S').source)
local myconfig = require("myconfig")

local function get_features_from_env()
  local val = os.getenv("CARGO_FEATURES")
  if not val then return nil end
  val = val:gsub("%s+$", ""):gsub("^%s+", "")
  if val == "" then return nil end
  local features = {}
  for feature in val:gmatch("[^,%s]+") do
    table.insert(features, feature)
  end
  if #features > 0 then return features end
  return nil
end

local function is_rust_file()
  local ft = vim.bo.filetype
  if ft == "rust" then return true end
  local name = vim.api.nvim_buf_get_name(0)
  return name:match("%.rs$") ~= nil
      or name:match("/Cargo%.toml$") ~= nil
      or name:match("\\Cargo%.toml$") ~= nil
end

local env_features = get_features_from_env()

if myconfig.should_debug_print() and is_rust_file() then
  if env_features then
    print("[rust-analyzer] CARGO_FEATURES: " .. table.concat(env_features, ", "))
  else
    print("[rust-analyzer] CARGO_FEATURES: (not set, using allFeatures)")
  end
end

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        --features = { "use_async", "with_imgui", "with_performance" },
        --features = { "use_sound", "threadsafe" },
        --features = { "winit29" },
        --features = { "gfxs" },
        --allFeatures = true,
        features = env_features,
        allFeatures = env_features == nil,
        --noDefaultFeatures = true,
      },
      --check = {
      --  features = { "use_async", "with_imgui", "with_performance" },
      --  --command = "clippy",
      --},
      --checkOnSave = { command = 'clippy' },
      diagnostics = { disabled = { 'inactive-code' } }, -- optional
    },
  },
}
