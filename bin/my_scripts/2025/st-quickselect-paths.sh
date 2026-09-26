#!/bin/sh
# Extract file paths from terminal output and copy selection to clipboard.
# Replicates wezterm QuickSelectArgs path patterns.
# Usage: pipe terminal content to this script, e.g. via st external pipe.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. "$HOME/.local/bin/my_scripts/menu_lib.sh"
menu_need

# Each pattern on its own grep pass, then combine + deduplicate.
input="$(cat | sed 's/│//g')"

paths="$(
    # Unix-style paths
    printf '%s' "$input" | grep -aPo '(?:[-._~#+/a-zA-Z0-9$])*/(?:[-._~#+/a-zA-Z0-9$]*)' 
    # Windows-style paths (forward or backslash)
    printf '%s' "$input" | grep -aPo '[a-zA-Z]:[/\\]+[-._#$:+~a-zA-Z0-9/\\ ]+'
    # UNC paths \\seusers.*.com\...
    printf '%s' "$input" | grep -aPo '\\\\seusers\..*?\.com[/\\]+[-._#$:+~a-zA-Z0-9/\\ ]+'
    # PowerShell $env:VAR\... paths
    printf '%s' "$input" | grep -aPo '\$env:[a-zA-Z_][a-zA-Z0-9_]*[/\\]+[-._~#+/a-zA-Z0-9$]*'
)" 

paths="$(printf '%s' "$paths" | sort -u)"

[ -z "$paths" ] && exit 1

chosen="$(printf '%s' "$paths" | menu 'Copy which path?' 20)"

[ -z "$chosen" ] && exit 1

printf '%s' "$chosen" | tr -d '\n' | xclip -selection clipboard

