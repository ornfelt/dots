#!/usr/bin/env bash
#
# Program launcher for every WM's mod-d: dmenu or rofi.
#   launcher.sh [dmenu|rofi|--dmenu|--rofi]
# The argument wins; without one, $LAUNCHER (dmenu|rofi) decides, and dmenu is
# the default. Set LAUNCHER in the WM's environment (e.g. export it in
# ~/.xinitrc before the WM starts) to change the default. The switch is
# menu_lib.sh, shared with the other menu scripts.

. ~/.local/bin/my_scripts/menu_lib.sh

# The bare dmenu|rofi argument (the flags are handled by menu_lib.sh)
[ -n "$1" ] && MENU=$1
menu_need

case $MENU in
    dmenu)
        exec dmenu_run -i -l 20
        ;;
    rofi)
        exec rofi -show run -theme "$MENU_ROFI_THEME"
        ;;
esac
