#!/usr/bin/env bash
# Marks / unmarks the wezterm pane this Claude Code session is running in.
#
# Wired up from ~/.claude/settings.json:
#   Stop             -> wezterm-claude-status.sh done
#   UserPromptSubmit -> wezterm-claude-status.sh clear
#
# ~/.wezterm/claude.lua polls the state directory and shows a robot icon on the
# tab containing this pane until that tab is visited. Windows equivalent:
# wezterm-claude-status.ps1 (same state directory and file layout).

set -u

action="${1:-done}"

# Not running inside wezterm: nothing to mark
[ -n "${WEZTERM_PANE:-}" ] || exit 0

state_dir="${HOME}/.wezterm/claude-status"
marker="${state_dir}/${WEZTERM_PANE}.done"

if [ "$action" = "clear" ]; then
  rm -f "$marker"
  exit 0
fi

# Claude Code passes the hook payload as JSON on stdin; cwd is the project dir
payload="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$cwd" ] || cwd="$PWD"

mkdir -p "$state_dir"
label="$(basename "$cwd")"
printf '%s' "$label" > "$marker"

# Append-only trail of finished responses: "<unix ms>\t<pane>\t<label>".
# The marker above is short lived -- claude.lua removes it again as soon as the
# tab it belongs to is the active one -- so anything that wants to *wait* for a
# response to finish (send_hotkey.py) reads this instead. claude.lua only globs
# *.done, so the log is invisible to it. A single short line with >> is written
# atomically, so parallel sessions can't interleave.
trail="${state_dir}/history.log"
now_ms="$(date +%s%3N 2>/dev/null)"
case "$now_ms" in *N*|"") now_ms="$(( $(date +%s) * 1000 ))";; esac
printf '%s\t%s\t%s\n' "$now_ms" "$WEZTERM_PANE" "$label" >> "$trail"

# Keep it from growing forever
if [ "$(wc -c < "$trail" 2>/dev/null || echo 0)" -gt 65536 ]; then
  tail -n 200 "$trail" > "${trail}.tmp" && mv -f "${trail}.tmp" "$trail"
fi

exit 0
