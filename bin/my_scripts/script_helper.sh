#!/usr/bin/env bash

docsDir="/home/jonas/Documents/my_notes/linux"

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

# Get the directory names from docsDir
directories=$(find "$docsDir" -maxdepth 1 -mindepth 1 -type f -printf "%f\n")

# Show the directory names as options in the menu
chosen=$(echo -e "$directories" | menu "Choose a file" 30 | sed "s/\r//")

# If user picks a directory, open the directory in a terminal
if [ "$chosen" != "" ]; then
    dir_path="$docsDir/$chosen"
    $1 -e bash -c "cd '$docsDir'; nvim '$dir_path'; zsh"
fi
