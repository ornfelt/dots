#!/bin/sh

# Quick select words from terminal output

tmpfile=$(mktemp /tmp/st-quickselect-words.XXXXXX)
trap 'rm "$tmpfile"' 0 1 15

# Read input and clean it
sed -n "w $tmpfile"
sed -i 's/\x0//g' "$tmpfile"

# Extract words using the pattern (simplified from the lua pattern)
# Matches: non-whitespace sequences that are substantial words
words="$(sed 's/.*│//g' "$tmpfile" | # Remove sidebar content
    grep -oE '[^[:space:]]{3,}|[^[:space:]][^[:space:]]*:[0-9]+' | # Words 3+ chars or word:number
    grep -v '^[>"\047]' | # Remove lines starting with quotes
    uniq)" # Remove duplicates

[ -z "$words" ] && exit 1

# Present with dmenu/rofi and copy selection
chosen="$(echo "$words" | dmenu -i -p 'Copy which word?' -l 20)"
# Or use rofi:
# chosen="$(echo "$words" | rofi -theme 'gruvbox-dark.rasi' -p 'Copy which word?' -dmenu -i -l 20)"

[ -n "$chosen" ] && echo -n "$chosen" | xclip -selection clipboard

