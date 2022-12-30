#!/bin/bash

# To set rofi theme: rofi-theme-selector -> pick theme -> alt-a to accept
# If you run this command with an argument, it will use greenclip
if [ -n "$1" ]; then
	rofi -modi "clipboard:greenclip print" -show clipboard -run-command '{cmd}'
else
	#sleep 0.1
	/usr/bin/diodon
fi
