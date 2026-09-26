#!/bin/bash
# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import png:- | xclip -selection clipboard -t image/png
# maim -s (or slurp) selects, cancelling on Escape. Capture to a temp file so
# that cancelling leaves the clipboard untouched (shot_grab exits then)
. ~/.local/bin/my_scripts/screenshot_lib.sh
if [ -n "$WAYLAND_DISPLAY" ]; then
    shot_need wl-copy:wl-clipboard
else
    shot_need xclip
fi
f=$(mktemp --suffix=.png)
trap 'rm -f "$f" "$SHOT_ERR"' EXIT
shot_grab "$f"
if [ -n "$WAYLAND_DISPLAY" ]; then
    wl-copy -t image/png < "$f" 2>"$SHOT_ERR"
else
    xclip -selection clipboard -t image/png -i "$f" 2>"$SHOT_ERR"
fi || { shot_error "Screenshot: copy to clipboard failed" "$(shot_errmsg)"; exit 1; }
shot_notify -i "$f" "Screenshot copied to clipboard"
