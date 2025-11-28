#!/bin/sh
# Quick select file paths from terminal output

# ./quickselect-paths.sh

tmpfile=$(mktemp /tmp/st-quickselect-paths.XXXXXX)
trap 'rm "$tmpfile"' 0 1 15

# Read input and clean it
sed -n "w $tmpfile"
sed -i 's/\x0//g' "$tmpfile"

# Extract paths using multiple patterns
paths="$(sed 's/.*│//g' "$tmpfile" | # Remove sidebar content
    grep -oE \
        -e '([-._~#+/a-zA-Z0-9$]+/)+[-._~#+/a-zA-Z0-9$]*' \
        -e '[a-zA-Z]:[/\\]+([-._#$:+~a-zA-Z0-9/\\ ]+)' \
        -e '\\\\seusers[^[:space:]]*\.com[/\\]+([-._#$:+~a-zA-Z0-9/\\ ]+)' \
        -e '\$env:[a-zA-Z_][a-zA-Z0-9_]*[/\\]+([-._~#+/a-zA-Z0-9$]*)' |
    uniq)" # Remove duplicates

[ -z "$paths" ] && exit 1

# Present with dmenu/rofi and copy selection
chosen="$(echo "$paths" | dmenu -i -p 'Copy which path?' -l 20)"
# Or use rofi:
# chosen="$(echo "$paths" | rofi -theme 'gruvbox-dark.rasi' -p 'Copy which path?' -dmenu -i -l 20)"

[ -n "$chosen" ] && echo -n "$chosen" | xclip -selection clipboard

