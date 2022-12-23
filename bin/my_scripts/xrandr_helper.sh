#!/usr/bin/env bash

rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
xrandr1="xrandr --output DP-3 --primary --mode 1920x1080 --rate 90.00"
xrandr2="xrandr --output DP-3 --primary --mode 1920x1080 --rate 60.00"
xrandr3="xrandr --output HDMI-1 --auto --right-of eDP-1"
xrandr4="xrandr --output HDMI-1 --off "
xrandr5="xrandr --output HDMI-1 --same-as eDP-1"
xrandr6="xrandr --output DP-3 --primary --mode 1920x1080 --rate 240.00 --output DP-1 --mode 1920x1080 --rate 144.00 --right-of DP-3"

# Variable passed to rofi
options="$xrandr1\n$xrandr2\n$xrandr3\n$xrandr4\n$xrandr5\n$xrandr6"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $xrandr1)
		$xrandr1
        ;;
    $xrandr2)
		$xrandr2
        ;;
    $xrandr3)
		$xrandr3
        ;;
    $xrandr4)
		$xrandr4
        ;;
    $xrandr5)
		$xrandr5
        ;;
    $xrandr6)
		$xrandr5
        ;;
esac
