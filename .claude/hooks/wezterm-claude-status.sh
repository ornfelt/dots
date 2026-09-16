#!/usr/bin/env bash
# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.sh done
#   StopFailure      -> wezterm-claude-status.sh failed
#   UserPromptSubmit -> wezterm-claude-status.sh clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited (a dead robot when the
# turn ended on an API error instead). Windows equivalent:
# wezterm-claude-status.ps1 (same state directory and file layout).
#
# Every wezterm-gui process numbers its panes from 0, so with two wezterm
# instances open a pane id alone matches a pane in each of them. Markers are
# therefore named "<instance>-<pane>", where the instance is the pid of the gui
# process -- the tail of WEZTERM_UNIX_SOCKET (".../gui-sock-<pid>"), which every
# pane of that instance inherits. "0" when it can't be told.

set -u

action="${1:-done}"

# Not running inside wezterm: nothing to mark
[ -n "${WEZTERM_PANE:-}" ] || exit 0

UNKNOWN_INSTANCE="0"
instance="${WEZTERM_UNIX_SOCKET:-}"
instance="${instance##*gui-sock-}"
case "$instance" in ''|*[!0-9]*) instance="$UNKNOWN_INSTANCE";; esac

state_dir="${HOME}/.wezterm/claude-status"
marker_name="${instance}-${WEZTERM_PANE}"
marker="${state_dir}/${marker_name}.done"
# Same, while the last turn of this pane ended on an API error
failed_marker="${state_dir}/${marker_name}.failed"

if [ "$action" = "clear" ]; then
  rm -f "$marker" "$failed_marker"
  exit 0
fi

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
payload="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$cwd" ] || cwd="$PWD"

# Stop also fires when a turn ends only to wait for background work (shells,
# agents, monitors); the payload lists those in background_tasks. Only mark the
# pane once nothing is still running - the final Stop comes after they finish.
# Quotes inside last_assistant_message are escaped, so these patterns only match
# the real keys.
if [ "$action" = "done" ] && printf '%s' "$payload" | sed -n 's/.*"background_tasks"[[:space:]]*:\(.*\)/\1/p' \
    | grep -Eq '"status"[[:space:]]*:[[:space:]]*"(running|pending)"'; then
  exit 0
fi

# StopFailure: rate_limit, billing_error, server_error, ... (whitespace squeezed
# out, so it can't break the tab separated trail line below)
error_type=""
if [ "$action" = "failed" ]; then
  error_type="$(printf '%s' "$payload" | sed -n 's/.*"error"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | tr -s '[:space:]' '_')"
  [ -n "$error_type" ] || error_type="unknown"
fi

# Window and tab of this pane (1-based, in wezterm's own order), for the other
# instances: they can't look into this one's mux. `wezterm cli` talks to the
# instance named by WEZTERM_UNIX_SOCKET, i.e. this one. Needs python3 for the
# json; skipped when anything is missing. --no-auto-start keeps a dead socket
# from spawning a wezterm mux server here, and timeout anything else that hangs.
location=""
if command -v wezterm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  cli="wezterm"
  command -v timeout >/dev/null 2>&1 && cli="timeout 5 wezterm"
  location="$($cli cli --no-auto-start list --format json 2>/dev/null | python3 -c '
import json, sys
pane = sys.argv[1]
try:
    entries = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
me = next((e for e in entries if str(e.get("pane_id")) == pane), None)
if me is None:
    sys.exit(0)
windows, tabs = [], []
for e in entries:
    if e.get("window_id") not in windows:
        windows.append(e.get("window_id"))
    if e.get("window_id") == me.get("window_id") and e.get("tab_id") not in tabs:
        tabs.append(e.get("tab_id"))
print("%d %d" % (windows.index(me.get("window_id")) + 1, tabs.index(me.get("tab_id")) + 1))
' "$WEZTERM_PANE" 2>/dev/null || true)"
fi

mkdir -p "$state_dir"
label="$(basename "$cwd")"

# Markers of instances that are gone (and old "<pane>.done" ones from before the
# instance was part of the name) would never be visited again; drop them.
for path in "$state_dir"/*.done "$state_dir"/*.failed; do
  [ -e "$path" ] || continue
  name="$(basename "$path")"
  case "$name" in
    [0-9]*-[0-9]*.*)
      pid="${name%%-*}"
      if [ "$pid" != "$UNKNOWN_INSTANCE" ] && ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$path"
      fi
      ;;
    *) case "${name%.*}" in *[!0-9]*) ;; *) rm -f "$path";; esac ;;
  esac
done

# "key=value" lines; claude.lua and send_hotkey.py read label, error, instance,
# window, tab and pane from it
content="label=${label}
instance=${instance}
pane=${WEZTERM_PANE}
"
if [ -n "$location" ]; then
  content="${content}window=${location% *}
tab=${location#* }
"
fi
[ -z "$error_type" ] || content="${content}error=${error_type}
"

# One marker per pane: a failure replaces a finished marker and vice versa
if [ "$action" = "failed" ]; then
  printf '%s' "$content" > "$failed_marker"
  rm -f "$marker"
else
  printf '%s' "$content" > "$marker"
  rm -f "$failed_marker"
fi

# Append-only trail of finished responses:
#   "<unix ms>\t<pane>\t<label>\tStop\t\t<instance>"
#   "<unix ms>\t<pane>\t<label>\tStopFailure\t<error type>\t<instance>"
# (older lines stop after <label>, or after <error type>).
# The marker above is short lived -- claude.lua removes it again as soon as the
# tab it belongs to is the active one -- so anything that wants to *wait* for a
# response to finish (send_hotkey.py) reads this instead. claude.lua only globs
# *.done / *.failed, so the log is invisible to it. A single short line with >>
# is written atomically, so parallel sessions can't interleave.
trail="${state_dir}/history.log"
now_ms="$(date +%s%3N 2>/dev/null)"
case "$now_ms" in *N*|"") now_ms="$(( $(date +%s) * 1000 ))";; esac
event_name="Stop"
[ -z "$error_type" ] || event_name="StopFailure"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$now_ms" "$WEZTERM_PANE" "$label" "$event_name" "$error_type" "$instance" >> "$trail"

# Keep it from growing forever
if [ "$(wc -c < "$trail" 2>/dev/null || echo 0)" -gt 65536 ]; then
  tail -n 200 "$trail" > "${trail}.tmp" && mv -f "${trail}.tmp" "$trail"
fi

exit 0
