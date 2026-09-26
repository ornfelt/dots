#!/bin/bash

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

# Get the max line width
# width=$(cal -3)
cal=$(cal)
menu_msg "${cal}" -font "mono 15" -markup -width 9 -lines 5 -location 6
