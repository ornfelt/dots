#! /bin/bash
export DISPLAY=:0
sleep 3
# import -window root ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
#scrot ~/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
maim /home/jonas/Pictures/Screenshots/Screenshot-$(date --iso-8601=seconds).png
