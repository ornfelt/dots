#! /bin/bash

#scrot -s -e ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
# maim -s selects with slop, which cancels on Escape (exits non-zero, and no
# file is written); -u leaves the mouse cursor out of the capture
if [ -n "$WAYLAND_DISPLAY" ]; then
    # slurp exits non-zero on Escape, same as maim -s
    region=$(slurp) || exit
    grim -g "$region" /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
else
    maim -s -u /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
fi

