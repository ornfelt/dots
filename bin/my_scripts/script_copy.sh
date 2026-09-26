#!/bin/bash

# Pick a oneliner from the notes with dmenu or rofi and copy it to the
# clipboard.
# With any argument (e.g. `script_copy.sh type`) the command is typed into the
# focused window instead of copied.

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

input_file="/home/jonas/Documents/my_notes/linux/oneliners_raw.txt"

# Get user selection via the menu from the input file. Lines are shown whole: the
# old `cut -d ';' -f1` chopped every oneliner containing a ';' (for loops etc.)
chosen=$(menu "Choose a command to copy" 30 < "$input_file" | sed "s/\r//")

# Exit if nothing chosen
[ -z "$chosen" ] && exit

# Entries abbreviated in oneliners_raw.txt expand to their full command
# (replaces the old args.py)
case "$chosen" in
    "ps ajxf | awk")
        chosen='ps ajxf | awk '\''{ if($2 == $4) { if ($1 == 1) { print "\033[35m" $0"\033[0m"}  else print "\033[1;32m" $0"\033[0m" } else print $0 }'\''' ;;
    "cat ~/.bash_history | tr ...")
        chosen='cat ~/.bash_history | tr "\|\;" "\n" | sed -e "s/^ //g" | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 10' ;;
    'python3 -c "import csv, ...')
        chosen='python3 -c "import csv,json,sys;print(json.dumps(list(csv.reader(open(sys.argv[1])))))" test.csv' ;;
esac

cleaned_command=$(echo "$chosen" | tr -cd '[:print:]')

if [ -n "$1" ]; then
    if [ -n "$WAYLAND_DISPLAY" ]; then
        wtype -- "$cleaned_command"
    else
        # --clearmodifiers so a still-held Super doesn't turn keys into binds
        xdotool type --clearmodifiers -- "$cleaned_command"
    fi
    exit
fi

if [ -n "$WAYLAND_DISPLAY" ]; then
    echo -n "$cleaned_command" | wl-copy
else
    echo -n "$cleaned_command" | xclip -selection clipboard
fi
notify-send "'$cleaned_command' copied to clipboard."
