#! /bin/bash

#scrot -s -e ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
# maim -s (or slurp) selects, cancelling on Escape: no file is written and
# shot_grab exits
. ~/.local/bin/my_scripts/screenshot_lib.sh
f=/home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
shot_grab "$f"
shot_notify -i "$f" "Screenshot saved" "$(shot_esc "$(shot_path "$f")")"
