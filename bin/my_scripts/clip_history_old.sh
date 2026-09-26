#!/bin/bash

# If run with an argument -> greenclip in dmenu or rofi (--dmenu / --rofi,
# else $LAUNCHER, else dmenu; see menu_lib.sh)
# Otherwise -> diodon
. ~/.local/bin/my_scripts/menu_lib.sh
if [ -n "$1" ] && menu_need && [ "$MENU" = dmenu ]; then
	# Dmenu
	greenclip print | grep . | dmenu -i -l 15 | xargs -r -d'\n' -I '{}' greenclip print '{}'
	# Example usage
	#greenclip print | grep . | dmenu -i -l 10 -p clipboard | xargs -r -d'\n' -I '{}' greenclip print '{}'
	# Fzf
	#greenclip print | grep . | fzf -e | xargs -r -d'\n' -I '{}' greenclip print '{}'
elif [ -n "$1" ]; then
	# Rofi. To set rofi theme: rofi-theme-selector -> pick theme -> alt-a to accept
	rofi -modi "clipboard:greenclip print" -show clipboard -run-command '{cmd}'
else
	#sleep 0.1
	/usr/bin/diodon
fi

