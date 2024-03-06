#!/bin/bash

theme="/home/jonas/.config/rofi/themes/gruvbox/gruvbox-dark2.rasi"
input_file="/home/jonas/Documents/my_notes/linux/oneliners_raw.txt"

# Get user selection via Rofi from the input file
chosen=$(cut -d ';' -f1 "$input_file" | rofi -theme "$theme" -p "Choose a command to copy" -dmenu -i -l 30 | sed "s/\r//")

# Exit if nothing chosen
[ -z "$chosen" ] && exit

# Define the Python script and pass the chosen command as an argument
python_script="python3 ~/.local/bin/my_scripts/script_help_docs/args.py"

# Check if the chosen command has a corresponding action in the Python script
if grep -q "$chosen" "$python_script"; then
    $python_script "$chosen"
else
    #echo -n "$chosen" | xclip -selection clipboard
    #notify-send "'$chosen' copied to clipboard."
    cleaned_command=$(echo "$chosen" | tr -cd '[:print:]')
    echo -n "$cleaned_command" | xclip -selection clipboard
    notify-send "'$cleaned_command' copied to clipboard."
fi
