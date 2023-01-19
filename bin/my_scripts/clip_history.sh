#!/bin/bash

# If you run this command with an argument, it will use greenclip
# If you run this command with two arguments, it will use greenclip and dmenu
# Else use diodon
if [ -n "$2" ]; then
	# Dmenu
	greenclip print | grep . | dmenu -i -l 15 | xargs -r -d'\n' -I '{}' greenclip print '{}'
	# Example usage
	#greenclip print | grep . | dmenu -i -l 10 -p clipboard | xargs -r -d'\n' -I '{}' greenclip print '{}'
	# Fzf
	#greenclip print | grep . | fzf -e | xargs -r -d'\n' -I '{}' greenclip print '{}'
elif [ -n "$1" ]; then
	# To set rofi theme: rofi-theme-selector -> pick theme -> alt-a to accept
	rofi -modi "clipboard:greenclip print" -show clipboard -run-command '{cmd}'
else
	#sleep 0.1
	/usr/bin/diodon
fi
