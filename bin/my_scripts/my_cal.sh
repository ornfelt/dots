#!/bin/bash

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

# Add a fake tty to get the day highlight
# https://stackoverflow.com/a/32981392
faketty () {
script -qfec "$(printf "%q " "$@")"

}

# Get the max line width
width=$(ncal -3 | wc -L)
if [ "$MENU" = rofi ]; then
cal=$(faketty ncal -3 \
| sed 's|_\(.\)|<span background="white" foreground="black">\1</span>|g' \
| sed 's|\s*$||')
else
# dmenu can't show markup: plain calendar, no day highlight
cal=$(ncal -3 | sed 's|\s*$||')
fi
menu_msg "${cal}" -font "mono 9" -markup -width -"${width}" -lines 8 -location 3
