#!/bin/sh

# Usage:
# hook into st:
# { MODKEY|ShiftMask, XK_e, externalpipe, { .v = (const char*[]){ "st-quickselect-paths", NULL } } },
# or use tmux scrollback:
# tmux capture-pane -J -p | ./st-quickselect-paths.sh

# Quick-select paths from terminal output and copy to clipboard.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. "$HOME/.local/bin/my_scripts/menu_lib.sh"
menu_need

tmpfile=$(mktemp /tmp/st-quick-paths.XXXXXX)
trap 'rm -f "$tmpfile"' 0 1 15

cat > "$tmpfile"

# strip st sidebars
sed -i 's/.*│//g' "$tmpfile"

# Collect paths:
# Unix-style: things starting with / and containing typical path chars
# Windows drive paths: C:\foo\bar or C:/foo/bar
# UNC-ish: \\something\something
# PowerShell $env:VAR\path
matches=$(
  grep -aEo '(/[[:alnum:].,_#+~$/-]+)+(/[[:alnum:].,_#+~$/-]*)?' "$tmpfile"
  grep -aEo '[A-Za-z]:[\\/][^[:space:]]+' "$tmpfile"
  grep -aEo '\\\\[^[:space:]]+' "$tmpfile"
  grep -aEo '\$env:[A-Za-z_][A-Za-z0-9_]*[\\/][^[:space:]]+' "$tmpfile"
)

# De-duplicate
matches=$(printf '%s\n' "$matches" | sort -u)

[ -z "$matches" ] && exit 1

choice=$(printf '%s\n' "$matches" | menu "Copy which path?" 10)

[ -z "$choice" ] && exit 1

printf '%s' "$choice" | tr -d '\n' | xclip -selection clipboard

