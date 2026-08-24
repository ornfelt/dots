# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.ps1 done
#   UserPromptSubmit -> wezterm-claude-status.ps1 clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited. Linux equivalent:
# wezterm-claude-status.sh (same state directory and file layout).

param([ValidateSet('done', 'clear')][string]$Action = 'done')

# Not running inside wezterm: nothing to mark
if (-not $env:WEZTERM_PANE) { exit 0 }

$home_dir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$stateDir = Join-Path $home_dir '.wezterm\claude-status'
$marker = Join-Path $stateDir ('{0}.done' -f $env:WEZTERM_PANE)

if ($Action -eq 'clear') {
    try { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop } catch { }
    exit 0
}

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
$label = $null
try {
    $payload = [Console]::In.ReadToEnd()
    if ($payload) { $label = ($payload | ConvertFrom-Json).cwd }
} catch { }
if (-not $label) { $label = (Get-Location).Path }
$label = Split-Path -Leaf $label

if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

# WriteAllText gives UTF-8 without a BOM, which keeps the label clean in lua
[System.IO.File]::WriteAllText($marker, $label)

# Append-only trail of finished responses: "<unix ms>\t<pane>\t<label>".
# The marker above is short lived -- claude.lua removes it again as soon as the
# tab it belongs to is the active one -- so anything that wants to *wait* for a
# response to finish (send_hotkey.py) reads this instead. claude.lua only globs
# *.done, so the log is invisible to it.
$trail = Join-Path $stateDir 'history.log'
$line = "{0}`t{1}`t{2}`n" -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(), $env:WEZTERM_PANE, $label

# Several sessions can finish at once; retry a few times if the file is locked
foreach ($attempt in 1..5) {
    try {
        [System.IO.File]::AppendAllText($trail, $line)
        break
    } catch {
        Start-Sleep -Milliseconds 50
    }
}

# Keep it from growing forever
try {
    if ((Get-Item -LiteralPath $trail).Length -gt 64KB) {
        $keep = Get-Content -LiteralPath $trail -Tail 200
        [System.IO.File]::WriteAllLines($trail, $keep)
    }
} catch { }

exit 0
