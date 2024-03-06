#!/usr/bin/env bash

docsDir="/home/jonas/Documents/my_notes/linux"

rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Get the directory names from docsDir
directories=$(find "$docsDir" -maxdepth 1 -mindepth 1 -type f -printf "%f\n")

# Show the directory names as options through Rofi
#chosen=$(echo -e "$directories" | $rofi_command -p "Choose a directory" -dmenu -selected-row 0)
chosen=$(echo -e "$directories" | dmenu -i -l 30 | sed "s/\r//")

# If user picks a directory, open the directory in a terminal
if [ "$chosen" != "" ]; then
    dir_path="$docsDir/$chosen"
    $1 -e bash -c "cd '$docsDir'; nvim '$dir_path'; zsh"
fi
