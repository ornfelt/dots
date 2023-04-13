#!/bin/sh

theme="/home/jonas/.config/rofi/themes/gruvbox/gruvbox-dark2.rasi"
# Inspired by the famous "get a menu of emojis to copy" script.

# Get user selection via dmenu from file.
#chosen=$(cut -d ';' -f1 raw_oneliners.txt | rofi -theme "$theme" -p "Choose a command to copy" -dmenu -i -l 30 | sed "s/ .*//")
# Dmenu
#chosen=$(cut -d ';' -f1 /home/jonas/.local/bin/my_scripts/script_help_docs/raw_oneliners.txt | dmenu -i -l 30 | sed "s/\r//")
# Rofi
chosen=$(cut -d ';' -f1 /home/jonas/.local/bin/my_scripts/script_help_docs/raw_oneliners.txt | rofi -theme "$theme" -p "Choose a command to copy" -dmenu -i -l 30 | sed "s/\r//")

# Exit if none chosen.
[ -z "$chosen" ] && exit

# If you run this command with an argument, it will automatically insert the
# command. Otherwise, show a message that the command has been copied.
if [ -n "$1" ]; then
	xdotool type "$chosen"
else
    if [ "$chosen" == "ps ajxf | awk" ]; then
		python3 ~/.local/bin/my_scripts/script_help_docs/args.py 100
    elif [ "$chosen" == "for i in */.git" ]; then
		python3 ~/.local/bin/my_scripts/script_help_docs/args.py 101
    elif [ "$chosen" == "for code in {0..255}" ]; then
		python3 ~/.local/bin/my_scripts/script_help_docs/args.py 102
    elif [ "$chosen" == "cat ~/.bash_history | tr ..." ]; then
		python3 ~/.local/bin/my_scripts/script_help_docs/args.py 103
    elif [ "$chosen" == "python3 -c \"import csv, ..." ]; then
		python3 ~/.local/bin/my_scripts/script_help_docs/args.py 104
    elif [ "$chosen" == "perl -e '$|++" ]; then
		python3 ~/.local/bin/my_scripts/script_help_docs/args.py 105
    else
        printf "$chosen" | wl-copy
    fi

    notify-send "'$chosen' copied to clipboard." &
fi
