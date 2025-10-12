if vim.fn.has('win32') == 1 then
  -- you might need to run this:
  -- Get-ChildItem "$env:USERPROFILE\Downloads\PowerShellEditorServices" -Recurse -File | Unblock-File
  local user_profile = vim.loop.os_getenv("USERPROFILE") or "C:/Users/jonas"
  local base_dir = user_profile .. [[/Downloads/PowerShellEditorServices]]
  local script_ps1 = base_dir .. [[/PowerShellEditorServices/Start-EditorServices.ps1]]
  local log_path = user_profile .. [[/AppData/Local/nvim-data/powershell_es.log]]
  local session_path = user_profile .. [[/AppData/Local/nvim-data/PowerShellEditorServices.json]]

  if vim.fn.filereadable(script_ps1) == 1 and vim.fn.executable('powershell.exe') == 1 then
    return {
      cmd = {
        'powershell.exe',
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-Command',
        ( [[& '%s' -HostName 'Neovim' -HostProfileId 'Neovim' -HostVersion '1.0.0' ]] ..
          [[-LogLevel 'Normal' -LogPath '%s' -SessionDetailsPath '%s' ]] ..
          [[-BundledModulesPath '%s' -Stdio]] )
          :format(script_ps1, log_path, session_path, base_dir),
      },
      filetypes    = { 'ps1', 'psm1', 'psd1' },
      root_markers = { '.git' },
    }
  else
    return {}
  end
else
  return {}
end

