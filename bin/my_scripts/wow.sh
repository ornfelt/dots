#!/usr/bin/bash

# output=$(ps aux | grep -E "/home/jonas/(acore/bin/worldserver|tcore/bin/worldserver|cmangos/run/bin/mangosd|vmangos/bin/mangosd)" | grep -v grep)
# 
# # Check if output contains any of the servers
# if echo "$output" | grep -q "/home/jonas/acore/bin/worldserver"; then
#   echo "acore server is running"
# elif echo "$output" | grep -q "/home/jonas/tcore/bin/worldserver"; then
#   echo "tcore server is running"
# elif echo "$output" | grep -q "/home/jonas/cmangos/run/bin/mangosd"; then
#   echo "cmangos server is running"
# elif echo "$output" | grep -q "/home/jonas/vmangos/bin/mangosd"; then
#   echo "vmangos server is running"
# else
#   echo "No server is running"
# fi

# Paths to Wow.exe
WOW_PATH_MOUNTED="/mnt/new/wow/Wow.exe"
WOW_PATH_DOWNLOADS="$HOME/Downloads/wow/Wow.exe"
WOW_PATH_MEDIA="/media/2024/wow/Wow.exe"

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

