#!/bin/bash
# Lock with a blurred screenshot, with groot.jpg in the middle. The screenshot
# goes in $XDG_RUNTIME_DIR (only readable by you) and is removed once i3lock
# has loaded it. If anything fails, lock_random.sh locks instead.

LOCK=$HOME/.config/neofetch/groot.jpg
fallback=~/.local/bin/my_scripts/lock_random.sh

# Screen size, e.g. 1920x1080
res=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ { print $2; exit }')

tmpbg=$(mktemp --suffix=.png -p "${XDG_RUNTIME_DIR:-/tmp}") || exec "$fallback"
trap 'rm -f "$tmpbg"' EXIT

# i3lock loads the image before it forks, so the file can go right after
if [ -n "$res" ] && [ -f "$LOCK" ] &&
    ffmpeg -loglevel error -y -f x11grab -video_size "$res" -i "$DISPLAY" -i "$LOCK" \
        -filter_complex "boxblur=5:1,overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" \
        -frames:v 1 "$tmpbg" &&
    i3lock -i "$tmpbg"; then
    exit 0
fi

rm -f "$tmpbg"
exec "$fallback"
