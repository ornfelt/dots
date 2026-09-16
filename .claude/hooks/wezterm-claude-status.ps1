# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.ps1 done
#   StopFailure      -> wezterm-claude-status.ps1 failed
#   UserPromptSubmit -> wezterm-claude-status.ps1 clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited (a dead robot when the
# turn ended on an API error instead). Linux equivalent:
# wezterm-claude-status.sh (same state directory and file layout).
#
# Every wezterm-gui process numbers its panes from 0, so with two wezterm
# instances open a pane id alone matches a pane in each of them. Markers are
# therefore named "<instance>-<pane>", where the instance is the pid of the gui
# process -- the tail of WEZTERM_UNIX_SOCKET (".../gui-sock-<pid>"), which every
# pane of that instance inherits. "0" when it can't be told.

param([ValidateSet('done', 'failed', 'clear')][string]$Action = 'done')

# Not running inside wezterm: nothing to mark
if (-not $env:WEZTERM_PANE) { exit 0 }

$UNKNOWN_INSTANCE = '0'
$instance = if ($env:WEZTERM_UNIX_SOCKET -match 'gui-sock-(\d+)$') { $Matches[1] } else { $UNKNOWN_INSTANCE }

$home_dir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$stateDir = Join-Path $home_dir '.wezterm\claude-status'
$markerName = '{0}-{1}' -f $instance, $env:WEZTERM_PANE
$marker = Join-Path $stateDir "$markerName.done"
# Same, while the last turn of this pane ended on an API error
$failedMarker = Join-Path $stateDir "$markerName.failed"

if ($Action -eq 'clear') {
    foreach ($path in @($marker, $failedMarker)) {
        try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop } catch { }
    }
    exit 0
}

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
$label = $null
$data = $null
try {
    $payload = [Console]::In.ReadToEnd()
    if ($payload) { $data = $payload | ConvertFrom-Json; $label = $data.cwd }
} catch { }

# Stop also fires when a turn ends only to wait for background work (shells,
# agents, monitors); the payload lists those in background_tasks. Only mark the
# pane once nothing is still running - the final Stop comes after they finish.
$busyStatuses = @('running', 'pending')
if ($Action -eq 'done' -and $data -and ($data.background_tasks | Where-Object { $busyStatuses -contains $_.status })) { exit 0 }
if (-not $label) { $label = (Get-Location).Path }
$label = Split-Path -Leaf $label

# StopFailure: rate_limit, billing_error, server_error, ... (no whitespace, so
# it can't break the tab separated trail line below)
$errorType = $null
if ($Action -eq 'failed') {
    $errorType = if ($data -and $data.error) { [string]$data.error } else { 'unknown' }
    $errorType = $errorType -replace '\s+', '_'
}

# Window and tab of this pane (1-based, in wezterm's own order), for the other
# instances: they can't look into this one's mux. `wezterm cli` talks to the
# instance named by WEZTERM_UNIX_SOCKET, i.e. this one. Skipped when it fails;
# --no-auto-start keeps a dead socket from spawning a wezterm mux server here.
$window = $null
$tab = $null
try {
    $panes = ((& wezterm cli --no-auto-start list --format json 2>$null) -join "`n") | ConvertFrom-Json
    $me = $panes | Where-Object { "$($_.pane_id)" -eq $env:WEZTERM_PANE } | Select-Object -First 1
    if ($me) {
        $windowIds = New-Object System.Collections.ArrayList
        $tabIds = New-Object System.Collections.ArrayList
        foreach ($entry in $panes) {
            if (-not $windowIds.Contains("$($entry.window_id)")) { [void]$windowIds.Add("$($entry.window_id)") }
            if ("$($entry.window_id)" -eq "$($me.window_id)" -and -not $tabIds.Contains("$($entry.tab_id)")) {
                [void]$tabIds.Add("$($entry.tab_id)")
            }
        }
        $window = $windowIds.IndexOf("$($me.window_id)") + 1
        $tab = $tabIds.IndexOf("$($me.tab_id)") + 1
    }
} catch { }

if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

# Markers of instances that are gone (and old "<pane>.done" ones from before the
# instance was part of the name) would never be visited again; drop them.
Get-ChildItem -LiteralPath $stateDir -File -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Name -match '^\d+\.(done|failed)$') {
        try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch { }
    } elseif ($_.Name -match '^(\d+)-\d+\.(done|failed)$' -and $Matches[1] -ne $UNKNOWN_INSTANCE) {
        $gui = Get-Process -Id ([int]$Matches[1]) -ErrorAction SilentlyContinue
        if (-not $gui -or $gui.ProcessName -notlike 'wezterm*') {
            try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch { }
        }
    }
}

# "key=value" lines; claude.lua and send_hotkey.py read label, error, instance,
# window, tab and pane from it. WriteAllText gives UTF-8 without a BOM.
$content = "label=$label`ninstance=$instance`npane=$($env:WEZTERM_PANE)`n"
if ($window) { $content += "window=$window`ntab=$tab`n" }
if ($errorType) { $content += "error=$errorType`n" }

# One marker per pane: a failure replaces a finished marker and vice versa.
if ($Action -eq 'failed') {
    [System.IO.File]::WriteAllText($failedMarker, $content)
    try { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop } catch { }
} else {
    [System.IO.File]::WriteAllText($marker, $content)
    try { Remove-Item -LiteralPath $failedMarker -Force -ErrorAction Stop } catch { }
}

# Append-only trail of finished responses:
#   "<unix ms>\t<pane>\t<label>\tStop\t\t<instance>"
#   "<unix ms>\t<pane>\t<label>\tStopFailure\t<error type>\t<instance>"
# (older lines stop after <label>, or after <error type>).
# The marker above is short lived -- claude.lua removes it again as soon as the
# tab it belongs to is the active one -- so anything that wants to *wait* for a
# response to finish (send_hotkey.py) reads this instead. claude.lua only globs
# *.done / *.failed, so the log is invisible to it.
$trail = Join-Path $stateDir 'history.log'
$eventName = if ($errorType) { 'StopFailure' } else { 'Stop' }
$line = "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`n" -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(), $env:WEZTERM_PANE, $label, $eventName, $errorType, $instance

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
