require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" }

-- $HOME is never a workspace root ------------------------------------------
-- A dotfile config that lives directly in the home directory (~/.wezterm.lua)
-- has no root marker anywhere above it, so the marker walk runs out and the
-- home directory itself becomes the workspace: lua-language-server is then
-- handed the whole user profile to index, walks AppData/Downloads/scoop/...,
-- trips over Lua.workspace.maxPreload and never reaches the handful of files
-- the config actually requires. `require 'claude'` resolves to nothing and
-- go-to-definition on that line does nothing.
--
-- So: root those buffers at the small sidecar tree the dotfile requires from
-- instead. wezterm puts ~/.wezterm and ~/.config/wezterm on package.path, so
-- rooting there is both correct and cheap - that directory is all that gets
-- scanned, and `require 'claude'` finds ~/.wezterm/claude.lua.
local home_sidecars = { ".wezterm", ".config/wezterm" }

-- Modules with no file behind them (`require 'wezterm'` is served by the
-- wezterm binary itself) only resolve if LuaCATS stubs are on disk; whichever
-- of these exists is loaded as a library. Nothing is created here, and the
-- lua standard library ones (`require 'os'`) luals resolves on its own.
local stub_libraries = { ".wezterm/types", ".config/wezterm/types", ".local/share/wezterm-types" }

local function norm(p) return (tostring(p or ""):gsub("\\", "/"):gsub("/+$", "")) end
local function isdir(p) return p ~= "" and vim.fn.isdirectory(p) == 1 end

-- Case-insensitive throughout: on Windows a buffer name can be spelled
-- c:/users/jonas/... while $USERPROFILE says C:\Users\jonas.
local function same(a, b) return a ~= "" and a:lower() == b:lower() end
local function under(path, dir)
  return dir ~= "" and (path:lower() .. "/"):sub(1, #dir + 1) == (dir:lower() .. "/")
end

local home = norm(vim.env.USERPROFILE or vim.env.HOME or "")

local sidecars = {}
for _, rel in ipairs(home_sidecars) do
  local dir = home .. "/" .. rel
  if isdir(dir) then sidecars[#sidecars + 1] = dir end
end

local function workspace_root(fname)
  local dir = norm(vim.fs.dirname(fname))

  -- already inside a sidecar: stay there, never widen out to $HOME
  for _, side in ipairs(sidecars) do
    if under(dir, side) then return side end
  end

  local root = vim.fs.root(fname, root_markers)
  if root then
    root = norm(root)
    if not same(root, home) then return root end
  end

  -- nothing but $HOME above the file
  if same(dir, home) then
    -- an absent sidecar is still the right answer: luals finds an empty
    -- workspace and behaves like single-file mode, which is what a stray
    -- ~/foo.lua wants - anything but a crawl of the profile
    return sidecars[1] or (home .. "/" .. home_sidecars[1])
  end

  return dir      -- single_file_support: the file's own directory
end

local library = {}
if vim.env.VIMRUNTIME and vim.env.VIMRUNTIME ~= "" then library[#library + 1] = vim.env.VIMRUNTIME end
for _, rel in ipairs(stub_libraries) do
  local dir = home .. "/" .. rel
  if isdir(dir) then library[#library + 1] = dir end
end

return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = root_markers,
  root_dir = function(bufnr, on_dir)
    local fname = norm(vim.api.nvim_buf_get_name(bufnr))
    if fname == "" then return end                      -- no file: don't start
    if not fname:match("^/") and not fname:match("^%a:/") then
      fname = norm(vim.fn.getcwd()) .. "/" .. fname     -- ':p', for a relative buffer name
    end
    on_dir(workspace_root(fname))
  end,
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim', 'use' } },
      workspace = {
        checkThirdParty = false,
        library = library,
        ignoreDir = { "build","node_modules","third_party",".git","AppData","Application Data","scoop",".vim",
                      "Downloads","OneDrive",".cargo",".rustup",".nuget",".cache",".local/share" },
      },
      telemetry = { enable = false },
    },
  },
}
