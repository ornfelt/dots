#!/bin/bash

# https://github.com/cdown/clipmenu

# clipmenu runs the menu from CM_LAUNCHER: --dmenu / --rofi, else $LAUNCHER,
# else dmenu (see menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need
export CM_LAUNCHER=$MENU

#clipmenu -l 20
clipmenu
