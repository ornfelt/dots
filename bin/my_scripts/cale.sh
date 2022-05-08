#!/bin/bash

# Get the max line width
# width=$(cal -3)
cal=$(cal)
rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi -font "mono 15" -markup -width 9 -lines 5 -location 6 -e "${cal}"
