#!/bin/sh
# Extract "words" from terminal output and copy selection to clipboard.
# Replicates wezterm QuickSelectArgs word pattern.
# Usage: pipe terminal content to this script, e.g. via st external pipe.

wordregex='[^│\s]\S*?(?=:\d|[>"'"'"']|$)|[^│\s]\S{2,}?(?=[>"'"'"']|$| )'

words="$(cat | tr -d '\n' |
    grep -aPo "$wordregex" |
    uniq)"

[ -z "$words" ] && exit 1

chosen="$(echo "$words" | rofi -theme 'gruvbox-dark.rasi' -p 'Copy which word?' -dmenu -i -l 20)"
#chosen="$(echo "$words" | dmenu -i -p 'Copy which word?' -l 20)"

[ -z "$chosen" ] && exit 1

printf '%s' "$chosen" | tr -d '\n' | xclip -selection clipboard

