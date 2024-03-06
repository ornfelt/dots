#!/bin/bash

codeDir="/home/jonas/Code"
case $1 in
	"old") codeDir="/home/jonas/Code" ;;
	"new") codeDir="/home/jonas/Code2" ;;
esac

rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Get the directory names from codeDir
directories=$(find "$codeDir" -maxdepth 1 -mindepth 1 -type d -printf "%f\n")

# Show the directory names as options through Rofi
chosen=$(echo -e "$directories" | $rofi_command -p "Choose a directory" -dmenu -selected-row 0)

# If user picks a directory, open the directory in a terminal
if [ "$chosen" != "" ]; then
    dir_path="$codeDir/$chosen"
    $2 -e bash -c "cd '$dir_path'; ls --color=auto; exec zsh"
fi
