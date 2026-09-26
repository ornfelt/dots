#!/usr/bin/env bash
#
# Program launcher for every WM's mod-d: dmenu or rofi.
#   launcher.sh [dmenu|rofi]
# The argument wins; without one, $LAUNCHER (dmenu|rofi) decides, and dmenu is
# the default. Set LAUNCHER in the WM's environment (e.g. export it in
# ~/.xinitrc before the WM starts) to change the default.

err() {
    echo "launcher: $1" >&2
    command -v notify-send >/dev/null && notify-send "launcher" "$1"
    exit 1
}

mode="${1:-${LAUNCHER:-dmenu}}"

case $mode in
    dmenu)
        command -v dmenu_run >/dev/null || err "missing: dmenu. Build it with: cd ~/.config/dmenu && sudo make install"
        exec dmenu_run -i -l 20
        ;;
    rofi)
        command -v rofi >/dev/null || err "missing: rofi. Install with: sudo apt install rofi"
        exec rofi -show run -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi
        ;;
    *)
        err "unknown launcher '$mode' (use dmenu or rofi)"
        ;;
esac
