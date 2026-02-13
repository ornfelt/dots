require('dbg_log').log_file(debug.getinfo(1, 'S').source)

local uv = vim.uv or vim.loop
local function is_str(s) return type(s)=="string" and s~="" end
local function file_exists(p) return is_str(p) and vim.fn.filereadable(p)==1 end
local function exe_exists(p)  return is_str(p) and vim.fn.executable(p)==1 end

local ENV = vim.loop.os_getenv("ROSLYN_LS_DLL")

local function dll_path()
  if vim.fn.has("win32")==1 then
    local user_profile = vim.env.USERPROFILE or "C:/Users/jonas"
    return user_profile .. [[/Downloads/Microsoft.CodeAnalysis.LanguageServer/content/LanguageServer/win-x64/Microsoft.CodeAnalysis.LanguageServer.dll]]
  else
    --local home = uv.os_homedir() or (vim.env.HOME or "/home/jonas")
    local home = vim.env.HOME or "/home/jonas"
    return home .. [[/Downloads/Microsoft.CodeAnalysis.LanguageServer/content/LanguageServer/linux-x64/Microsoft.CodeAnalysis.LanguageServer.dll]]
  end
end

local DLL = (ENV and ENV:match("%.dll$") and ENV) or dll_path()
local DOTNET = "dotnet"

-- Build cmd with verbose logs
local logdir = (vim.fn.stdpath("cache") .. "/roslyn_logs")
vim.fn.mkdir(logdir, "p")

if file_exists(DLL) and exe_exists(DOTNET) then
  return {
    cmd = {
      DOTNET, DLL,
      "--stdio",
      "--logLevel", "Trace",
      "--extensionLogDirectory", logdir,
    },
    filetypes    = { "cs", "csx", "vb" },
    root_markers = { "global.json", ".sln", ".csproj", ".vbproj", ".git" },
  }
end

--vim.schedule(function()
--  vim.notify(
--    "roslyn: cannot resolve runnable server.\n" ..
--    "Checked DLL: " .. (DLL or "(nil)") .. "\n" ..
--    "dotnet on PATH: " .. (exe_exists(DOTNET) and "yes" or "no"),
--    vim.log.levels.WARN
--  )
--end)

return {}

