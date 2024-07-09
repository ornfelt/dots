#!/usr/bin/bash

# Paths to Wow.exe
WOW_PATH_MOUNTED="/mnt/new/wow_classic/WoW.exe"
WOW_PATH_DOWNLOADS="$HOME/Downloads/wow_classic/WoW.exe"
WOW_PATH_MEDIA="/media/2024/wow_classic/WoW.exe"

# Check if Wow.exe exists in /mnt/new/wow/
if [ -f "$WOW_PATH_MOUNTED" ]; then
    wine "$WOW_PATH_MOUNTED"
elif [ -f "$WOW_PATH_DOWNLOADS" ]; then
    wine "$WOW_PATH_DOWNLOADS"
elif [ -f "$WOW_PATH_MEDIA" ]; then
    wine "$WOW_PATH_MEDIA"
else
    echo "Wow.exe not found in any of the specified locations."
fi

