#!/bin/bash

#sh ~/.fehbg
export DISPLAY=:0
feh --bg-fill --randomize ~/Pictures/Wallpapers/* &
#wmname compiz

#arr=("xfce4-power-man" "copyq" "fcitx5" "dunst" "clipmenud" "qv2ray" "redshift-gtk" "mpd" "picom" "qbittorrent" "nutstore" "solaar")
# arr=("xfce4-power-manager" "diodon" "dwmblocks", "firefox")
# arr=("diodon")
#arr=("xfce4-power-manager")
#
#for value in ${arr[@]}; do
#  if [[ ! $(pgrep ${value}) ]]; then
#    exec "$value" &
#  fi
#done
#
#greenclip daemon

# Compatible with non-array supported shell scripts...
#apps="xfce4-power-manager diodon"
apps="xfce4-power-manager"

for app in $apps; do
  if ! pgrep -x "$app" > /dev/null; then
    "$app" &
  fi
done

greenclip daemon &

# Simple version
#xfce4-power-manager &
#greenclip daemon &

