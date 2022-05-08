#!/bin/sh

# Prints the current volume percentage
vol="$(awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master))"
echo "$vol"
