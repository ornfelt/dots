#!/usr/bin/env bash
#
# dmenu/rofi picker for nvimswitch: choose which nvim variant a plain `nvim`
# runs (system / fork / rim). No WM keybinding of its own: it is on PATH, so
# every WM's mod-d launcher (launcher.sh -> dmenu_run / rofi run) finds it -
# type "nvimsw" and Enter.
#
# Built variants switch right away (with a notification); one that is not
# built shows its build command instead. The current one is marked with *.
# See ~/.local/bin/nvimswitch/nvimswitch for the switch itself.
#
# Usage examples:
# pick with the default menu ($LAUNCHER, else dmenu):
# nvimswitch_menu.sh
#
# force dmenu or rofi:
# nvimswitch_menu.sh --dmenu
# nvimswitch_menu.sh --rofi

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

NVIMSWITCH="$HOME/.local/bin/nvimswitch/nvimswitch"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -u normal "nvimswitch" "$1"
}

if [ ! -x "$NVIMSWITCH" ]; then
    menu_msg "nvimswitch is not installed: $NVIMSWITCH"
    exit 1
fi

# "<variant> <TAB> <current> <TAB> <built> <TAB> <exe> <TAB> <build hint>"
entries=$("$NVIMSWITCH" --porcelain) || exit 1

lines=""
while IFS=$'\t' read -r variant current built exe hint; do
    mark="  "
    [ "$current" = 1 ] && mark="* "
    if [ "$built" = 1 ]; then
        detail="$exe"
    else
        detail="not built - $hint"
    fi
    lines+="$(printf '%s%-7s  %s' "$mark" "$variant" "$detail")"$'\n'
done <<< "$entries"

chosen=$(printf '%s' "$lines" | menu "nvim variant" 3 | sed "s/\r//")
[ -z "$chosen" ] && exit 0

# the variant is the first word after the optional "* " marker
variant=$(printf '%s' "$chosen" | sed 's/^\* *//; s/^ *//' | awk '{print $1}')
line=$(printf '%s\n' "$entries" | awk -F'\t' -v v="$variant" '$1 == v')
if [ -z "$line" ]; then
    menu_msg "Unknown choice: $chosen"
    exit 1
fi

IFS=$'\t' read -r variant current built exe hint <<< "$line"
if [ "$built" != 1 ]; then
    menu_msg "$variant is not built yet. Build it with: $hint"
    exit 1
fi

if ! "$NVIMSWITCH" "$variant" >/dev/null 2>&1; then
    notify "Could not switch to $variant"
    exit 1
fi

message="nvim now runs $variant (next start)"
# Until the next X login the wrapper is not on the WM's PATH yet
if [ "$(command -v nvim)" != "$HOME/.local/bin/nvimswitch/nvim" ]; then
    message="$message - takes effect for programs the WM starts after logging in to X again"
fi
notify "$message"
