#!/bin/sh

# The famous "get a menu of emojis to copy" script.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. "$HOME/.local/bin/my_scripts/menu_lib.sh"
menu_need

# Get user selection via the menu from emoji file.
chosen=$(cut -d ';' -f1 emojipick/chars/* | menu "Emoji" 30 | sed "s/ .*//")

# Exit if none chosen.
[ -z "$chosen" ] && exit

# If you run this command with an argument, it will automatically insert the
# character. Otherwise, show a message that the emoji has been copied.
if [ -n "$1" ]; then
	xdotool type "$chosen"
else
	printf "$chosen" | xclip -selection clipboard
	notify-send "'$chosen' copied to clipboard." &
fi
