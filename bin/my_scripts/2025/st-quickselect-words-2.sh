#!/bin/sh

# Quick-select "words" from terminal output and copy to clipboard.
# Read from stdin for compatability with st externalpipe scripts or via tmux
# capture-pane.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. "$HOME/.local/bin/my_scripts/menu_lib.sh"
menu_need

# Usage:
# hook into st:
# { MODKEY|ShiftMask, XK_w, externalpipe, { .v = (const char*[]){ "st-quickselect-words", NULL } } },
# or use tmux scrollback:
# tmux capture-pane -J -p | ./st-quickselect-words.sh

# Read all stdin into a temp file (so we can run multiple passes if needed)
tmpfile=$(mktemp /tmp/st-quick-words.XXXXXX)
trap 'rm -f "$tmpfile"' 0 1 15

cat > "$tmpfile"

# strip st sidebars
sed -i 's/.*│//g' "$tmpfile"

# Grep "word-like" things:
# - Start with a non-space, not the │ bar
# - At least 3 non-space characters total (like my wezterm quickselect pattern)
matches=$(grep -aEo '[^[:space:]│][^[:space:]│]{2,}' "$tmpfile" \
  | sort -u)

# with punctuation trimming
#matches=$(grep -aEo '[^[:space:]│][^[:space:]│]+' "$tmpfile" \
#  | sed 's/[,:;.!?"]$//' \
#  | sort -u)

[ -z "$matches" ] && exit 1

choice=$(printf '%s\n' "$matches" | menu "Copy which word?" 10)

[ -z "$choice" ] && exit 1

printf '%s' "$choice" | tr -d '\n' | xclip -selection clipboard

