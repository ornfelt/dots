#!/usr/bin/bash

# Paths to Wow.exe
WOW_PATH_MOUNTED="/mnt/new/wow_tbc/Wow.exe"
WOW_PATH_DOWNLOADS="$HOME/Downloads/wow_tbc/Wow.exe"
WOW_PATH_MEDIA="/media/2024/wow_tbc/Wow.exe"

# Check where the exe exists
if [ -f "$WOW_PATH_MOUNTED" ]; then
    wine "$WOW_PATH_MOUNTED"
elif [ -f "$WOW_PATH_DOWNLOADS" ]; then
    wine "$WOW_PATH_DOWNLOADS"
elif [ -f "$WOW_PATH_MEDIA" ]; then
    wine "$WOW_PATH_MEDIA"
else
    echo "Wow.exe not found in any of the specified locations."
fi

