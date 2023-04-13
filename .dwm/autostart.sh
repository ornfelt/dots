#!/bin/bash

#sh ~/.fehbg
export DISPLAY=:0
feh --bg-fill --randomize ~/Pictures/Wallpapers/* &
#wmname compiz

#arr=("xfce4-power-man" "copyq" "fcitx5" "dunst" "clipmenud" "qv2ray" "redshift-gtk" "mpd" "picom" "qbittorrent" "nutstore" "solaar")
# arr=("xfce4-power-manager" "diodon" "dwmblocks", "firefox")
# arr=("diodon")
#arr=("xfce4-power-manager")

for value in ${arr[@]}; do
  if [[ ! $(pgrep ${value}) ]]; then
    exec "$value" &
  fi
done

# Wake dwmblocks
sleep 0.5
kill -44 $(pidof dwmblocks)
greenclip daemon
sleep 1
kill -44 $(pidof dwmblocks)
