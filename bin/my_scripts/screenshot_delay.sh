#! /bin/bash
sleep 3
if [ -n "$WAYLAND_DISPLAY" ]; then
    grim /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
    exit
fi
export DISPLAY=:0
# import -window root ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
#scrot ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
maim /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
