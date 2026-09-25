#!/bin/sh
# statusline-cache.sh - Claude Code statusLine helper for awesome-claude-usage.
#
# Claude Code pipes a JSON document to the statusLine command on every turn.
# This script stores the parts the widget can use in
#   $XDG_CACHE_HOME/claude-usage/rate_limits.json   (default ~/.cache/...)
#     { ts, rate_limits, context: { used_percentage, size, input_tokens }, model, session_id }
# and then hands the unchanged JSON to an optional downstream statusLine command.
#
# settings.json example (no existing statusline):
#   "statusLine": { "type": "command",
#                   "command": "~/.config/awesome/claude_usage/contrib/statusline-cache.sh" }
# With an existing statusline script:
#   "command": "~/.config/awesome/claude_usage/contrib/statusline-cache.sh ~/.claude/statusline.sh"
#
# Requires jq. Never fails the statusline: every error is swallowed.

input=$(cat)
cache_dir="${CLAUDE_USAGE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage}"

if command -v jq >/dev/null 2>&1; then
	(
		umask 077
		mkdir -p "$cache_dir" 2>/dev/null || exit 0
		out=$(printf '%s' "$input" | jq -c '{
			ts: (now | floor),
			rate_limits: .rate_limits,
			context: (if .context_window then {
				used_percentage: .context_window.used_percentage,
				size: .context_window.context_window_size,
				input_tokens: .context_window.total_input_tokens
			} else null end),
			model: .model.display_name,
			session_id: .session_id
		} | select(.rate_limits != null or .context != null)' 2>/dev/null) \
			|| exit 0
		[ -n "$out" ] || exit 0
		tmp=$(mktemp "$cache_dir/.rate_limits.XXXXXX" 2>/dev/null) || exit 0
		if printf '%s\n' "$out" >"$tmp" 2>/dev/null; then
			mv -f "$tmp" "$cache_dir/rate_limits.json" 2>/dev/null || rm -f "$tmp"
		else
			rm -f "$tmp"
		fi
	) || true
fi

if [ "$#" -gt 0 ]; then
	printf '%s' "$input" | "$@"
else
	# Minimal standalone statusline: model name and context usage.
	printf '%s' "$input" \
		| jq -r '"\(.model.display_name // "Claude")\(if .context_window.used_percentage then " · \(.context_window.used_percentage | floor)% context" else "" end)"' 2>/dev/null \
		|| printf 'Claude\n'
fi
