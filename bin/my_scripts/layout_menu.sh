#!/bin/sh

# Layout switcher for awesome, dwm, dwmc and dwmr: a click on the bar's
# layout symbol and mod-r run it.
#
#   layout_menu.sh [--rofi|--dmenu] NAME...
#
# NAMEs are the WM's layouts in its own order (awful.layout.getname in
# awesome, the arrange function in dwm's layouts[]). Shows them in a grid
# with an ascii preview of each, and prints the 0-based index of the chosen
# one (nothing, exit 1, when cancelled). LAYOUT_MENU_CURRENT is the index of
# the current layout, preselected. mod-r closes it again and mod-1..9 picks
# the nth layout. dmenu needs my fork (~/.config/dmenu) for the grid (-g,
# -eh, -sep, -ix, -n and -W) and those keys.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

[ $# -gt 0 ] || menu_err "usage: ${0##*/} [--rofi|--dmenu] NAME..."

# 23x7 preview of layout NAME, numbers are the window order (1 is master)
preview() {
    case $1 in
        spiral) cat <<'EOF' ;;
+-----------+---------+
|           |    2    |
|           +----+----+
|     1     | 5  |    |
|           +----+ 3  |
|           | 4  |    |
+-----------+----+----+
EOF
        dwindle) cat <<'EOF' ;;
+-----------+---------+
|           |    2    |
|           +----+----+
|     1     |    | 4  |
|           | 3  +----+
|           |    | 5  |
+-----------+----+----+
EOF
        tile) cat <<'EOF' ;;
+-----------+---------+
|           |    2    |
|           +---------+
|     1     |    3    |
|           +---------+
|           |    4    |
+-----------+---------+
EOF
        tileleft) cat <<'EOF' ;;
+---------+-----------+
|    2    |           |
+---------+           |
|    3    |     1     |
+---------+           |
|    4    |           |
+---------+-----------+
EOF
        bstack|tilebottom) cat <<'EOF' ;;
+---------------------+
|                     |
|          1          |
|                     |
+------+-------+------+
|  2   |   3   |  4   |
+------+-------+------+
EOF
        tiletop) cat <<'EOF' ;;
+------+-------+------+
|  2   |   3   |  4   |
+------+-------+------+
|                     |
|          1          |
|                     |
+---------------------+
EOF
        deck) cat <<'EOF' ;;
+-----------+---------+
|           |         |
|           |         |
|     1     |  2/3/4  |
|           |         |
|           |         |
+-----------+---------+
EOF
        monocle|max|fullscreen) cat <<'EOF' ;;
+---------------------+
|                     |
|                     |
|       1/2/3/4       |
|                     |
|                     |
+---------------------+
EOF
        centeredmaster|centerwork) cat <<'EOF' ;;
+-----+---------+-----+
|  2  |         |  3  |
|     |         |     |
+-----+    1    +-----+
|  4  |         |  5  |
|     |         |     |
+-----+---------+-----+
EOF
        centeredfloatingmaster) cat <<'EOF' ;;
+------+-------+------+
|  2   |   3   |  4   |
|   +-----------+     |
|   |     1     |     |
|   +-----------+     |
|      |       |      |
+------+-------+------+
EOF
        floating|none) cat <<'EOF' ;;
+---------------------+
| +------+  +-------+ |
| |  1   |  |   2   | |
| +------+  +-------+ |
|    +---------+      |
|    |    3    |      |
+----+---------+------+
EOF
        *) cat <<'EOF' ;;
+---------------------+
|                     |
|                     |
|          ?          |
|                     |
|                     |
+---------------------+
EOF
    esac
}

cur=${LAYOUT_MENU_CURRENT:-0}

# one NUL separated entry per layout: the preview, then its name
entries() {
    for name do
        preview "$name"
        printf "%$(((23 - ${#name}) / 2))s%s\n\0" '' "$name"
    done
}

if [ "$MENU" = rofi ]; then
    entries "$@" | rofi -dmenu -i -no-custom -format i -sep '\0' -eh 8 \
        -theme "$MENU_ROFI_THEME" -p layout -selected-row "$cur" \
        -kb-cancel 'Escape,Control+g,Control+bracketleft,Super+r' \
        -theme-str 'window { width: 820px; }' \
        -theme-str 'listview { columns: 3; lines: 3; fixed-columns: true; }' \
        -theme-str 'element-text { font: "JetBrainsMono Nerd Font 10"; }'
else
    # the same 3x3 grid (for up to 9 layouts) and size as rofi's
    entries "$@" | dmenu -i -ix -sep '\0' -eh 8 -g 3 -l 3 -W 820 \
        -n "$cur" -p layout -fn "JetBrainsMono Nerd Font:size=10"
fi
