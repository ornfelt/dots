#!/bin/bash

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

codeDir="/home/jonas/Code"
case $1 in
	"old") codeDir="/home/jonas/Code" ;;
	"new") codeDir="/home/jonas/Code2" ;;
esac

# Get the directory names from codeDir
directories=$(find "$codeDir" -maxdepth 1 -mindepth 1 -type d -printf "%f\n")

# Show the directory names as options in the menu
chosen=$(echo -e "$directories" | menu "Choose a directory" "" -selected-row 0)

# If user picks a directory, open the directory in a terminal
if [ "$chosen" != "" ]; then
    dir_path="$codeDir/$chosen"
    $2 -e bash -c "cd '$dir_path'; ls --color=auto; exec zsh"
fi
