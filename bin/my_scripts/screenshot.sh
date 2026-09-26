#! /usr/bin/bash

[ -z "$WAYLAND_DISPLAY" ] && export DISPLAY=:0
target_dir="$HOME/Pictures/Screenshots"
. ~/.local/bin/my_scripts/screenshot_lib.sh

#if [ -n "$(ls -A /mnt/new 2>/dev/null)" ]; then
#    target_dir="/mnt/new/Pictures/Screenshots"
#else
#    target_dir="$HOME/Pictures/Screenshots"
#fi

# Check if the target directory exists and create it if it doesn't
if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    #echo "Directory $target_dir created."
fi

# import -window root ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
#scrot ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png

#maim /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png 2> /home/jonas/screen_err
screenshot_file="$target_dir/Screenshot-$(date --iso-8601=seconds).png"
if [ -n "$WAYLAND_DISPLAY" ]; then
    shot_need grim
    grim "$screenshot_file" 2> $HOME/screen_err
else
    shot_need maim
    maim "$screenshot_file" 2> $HOME/screen_err
fi || { shot_error "Screenshot failed" "$(shot_errmsg "$HOME/screen_err")"; exit 1; }
shot_notify -i "$screenshot_file" "Screenshot saved" "$(shot_esc "$(shot_path "$screenshot_file")")"

