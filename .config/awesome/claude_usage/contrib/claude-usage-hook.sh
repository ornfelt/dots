#!/bin/sh
# claude-usage-hook.sh - Claude Code hook that pokes the AwesomeWM widget immediately.
#
# Register it for the Notification and Stop events (async, so Claude Code never waits):
#   "hooks": {
#     "Notification": [{ "hooks": [{ "type": "command", "async": true, "timeout": 5,
#                        "command": "~/.config/awesome/claude_usage/contrib/claude-usage-hook.sh" }] }],
#     "Stop":         [{ "hooks": [{ "type": "command", "async": true, "timeout": 5,
#                        "command": "~/.config/awesome/claude_usage/contrib/claude-usage-hook.sh" }] }]
#   }
#
# The widget then rescans ~/.claude/sessions right away and, for a Notification that
# needs you (permission prompt, question, idle prompt), shows the desktop notification
# without waiting for the next scan. Only the event name, the notification type and the
# session id are passed on; the message text stays in Claude Code.

command -v awesome-client >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""' 2>/dev/null | tr -cd 'A-Za-z0-9_')
kind=$(printf '%s' "$input" | jq -r '.notification_type // ""' 2>/dev/null | tr -cd 'A-Za-z0-9_')
session=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null | tr -cd 'A-Za-z0-9_-')

[ -n "$event" ] || exit 0
awesome-client "pcall(function() require('claude_usage').hook('$event', '$kind', '$session') end)" >/dev/null 2>&1 || true
exit 0
