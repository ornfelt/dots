#!/bin/bash

# Simple script to modify screen brightness
# USAGE:
# brightness.sh +20 (Increase brightness by 20%)

basedir="/sys/class/backlight/"

# get the backlight handler
handler=$basedir$(ls $basedir)"/"

# current brightness
old_brightness=$(cat $handler"brightness")

# max brightness
max_brightness=$(cat $handler"max_brightness")

# current %
old_brightness_p=$(( 100 * $old_brightness / $max_brightness ))

# new % 
new_brightness_p=$(($old_brightness_p $1))

# new brightness value
new_brightness=$(( $max_brightness * $new_brightness_p / 100 ))

# set the new brightness value
sudo chmod 666 $handler"brightness"
sudo echo $new_brightness > $handler"brightness"
