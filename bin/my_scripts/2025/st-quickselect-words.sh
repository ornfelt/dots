#!/bin/sh
# Extract "words" from terminal output and copy selection to clipboard.
# Replicates wezterm QuickSelectArgs word pattern.
# Usage: pipe terminal content to this script, e.g. via st external pipe.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. "$HOME/.local/bin/my_scripts/menu_lib.sh"
menu_need

wordregex='[^│\s]\S*?(?=:\d|[>"'"'"']|$)|[^│\s]\S{2,}?(?=[>"'"'"']|$| )'

words="$(cat | tr -d '\n' |
    grep -aPo "$wordregex" |
    uniq)"

[ -z "$words" ] && exit 1

chosen="$(echo "$words" | menu 'Copy which word?' 20)"

[ -z "$chosen" ] && exit 1

printf '%s' "$chosen" | tr -d '\n' | xclip -selection clipboard

