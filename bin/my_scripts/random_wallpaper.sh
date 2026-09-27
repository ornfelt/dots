#!/bin/sh
# Set the wallpaper to a random jpg/jpeg/png directly in ~/Pictures/Wallpapers.
# If there is none, leave the current wallpaper alone.
# Used by ~/.dwm/autostart.sh (dwm/dwmr/dwmc) and ~/.config/i3/config;
# awesome does the same in themes/multicolor/theme.lua.

dir="$HOME/Pictures/Wallpapers"

pic=$(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | shuf -n 1)

[ -n "$pic" ] || exit 0
exec feh --bg-fill "$pic"
