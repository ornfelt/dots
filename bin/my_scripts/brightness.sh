#!/bin/bash

# Simple script to modify screen brightness
# USAGE:
# brightness.sh +20 (Increase brightness by 20%)

notify() {
    # the stack tag makes each key press replace the last notification
    notify-send -a brightness -t 1500 -h string:x-dunst-stack-tag:brightness "$@"
}

basedir="/sys/class/backlight/"
if [ -z "$(ls $basedir 2>/dev/null)" ]; then
    notify -u critical "Brightness" "no backlight device in $basedir"
    exit 1
fi

# get the backlight handler
handler=$basedir$(ls $basedir)"/"

# current brightness
old_brightness=$(cat $handler"brightness")

# max brightness
max_brightness=$(cat $handler"max_brightness")

# current %
old_brightness_p=$(( 100 * $old_brightness / $max_brightness ))

# new %, kept within 0-100 (the kernel rejects values past max_brightness)
new_brightness_p=$(($old_brightness_p $1))
[ $new_brightness_p -gt 100 ] && new_brightness_p=100
[ $new_brightness_p -lt 0 ] && new_brightness_p=0

# new brightness value
new_brightness=$(( $max_brightness * $new_brightness_p / 100 ))

# set the new brightness value; -n: sudo fails instead of waiting for a
# password nobody can type (no terminal when a keybind runs this)
[ -w $handler"brightness" ] || sudo -n chmod 666 $handler"brightness"
if err=$( { echo $new_brightness > $handler"brightness"; } 2>&1 ); then
    notify -h int:value:$new_brightness_p "Brightness $new_brightness_p%"
else
    notify -u critical "Brightness: can't set it" "${err##*: }"
fi
