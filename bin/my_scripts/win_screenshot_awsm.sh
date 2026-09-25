#!/bin/bash
# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import png:- | xclip -selection clipboard -t image/png
# maim -s selects with slop, which cancels on Escape (exits non-zero). Capture
# to a temp file so that cancelling leaves the clipboard untouched; -u leaves
# the mouse cursor out of the capture
if [ -n "$WAYLAND_DISPLAY" ]; then
    # slurp exits non-zero on Escape, leaving the clipboard untouched
    region=$(slurp) && grim -g "$region" - | wl-copy -t image/png
    exit
fi
f=$(mktemp --suffix=.png) && maim -s -u "$f" && xclip -selection clipboard -t image/png -i "$f"
rm -f "$f"
