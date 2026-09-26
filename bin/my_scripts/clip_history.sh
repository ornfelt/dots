#!/bin/bash

# https://github.com/cdown/clipmenu

# clipmenu runs the menu from CM_LAUNCHER: --dmenu / --rofi, else $LAUNCHER,
# else dmenu (see menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need
export CM_LAUNCHER=$MENU

# clipmenud fills the history; without it the menu only has old clips
pgrep -x clipmenud >/dev/null ||
    notify-send -a clipmenu "clipmenud isn't running" "new clips aren't saved to the history"

#clipmenu -l 20
# exits non-zero when the menu is cancelled
clipmenu || exit
# clipserve serves the chosen clip (UTF8_STRING only, at first); retry briefly
# in case it doesn't own the clipboard yet
for _ in 1 2 3 4 5; do
    clip=$(xclip -selection clipboard -o -t UTF8_STRING 2>/dev/null) && break
    sleep 0.1
done
notify-send -a clipmenu "Copied to clipboard" \
    "$(printf '%s\n' "$clip" | head -n 8 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
