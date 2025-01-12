#!/usr/bin/bash

output=$(ps aux | grep -E "/home/jonas/(acore/bin/worldserver|tcore/bin/worldserver|cmangos/run/bin/mangosd|vmangos/bin/mangosd)" | grep -v grep)

# Check if output contains any of the servers
#echo "Output: $output"
if echo "$output" | grep -q "/home/jonas/acore/bin/worldserver"; then
  echo "acore server is running"
elif echo "$output" | grep -q "/home/jonas/tcore/bin/worldserver"; then
  echo "tcore server is running"
elif echo "$output" | grep -q "/home/jonas/cmangos/run/bin/mangosd"; then
  echo "cmangos server is running"
elif echo "$output" | grep -q "/home/jonas/vmangos/bin/mangosd"; then
  echo "vmangos server is running"
else
  echo "No server is running"
fi

ARG=$(echo "$1" | tr '[:upper:]' '[:lower:]')
# ARG=${1,,} # Works in Bash 4.0+

BASE_PATH_MOUNTED="/mnt/new"
BASE_PATH_DOWNLOADS="$HOME/Downloads"
BASE_PATH_MEDIA="/media/2024"

case "$ARG" in
    classic|c)
        WOW_DIR="wow_classic"
        WOW_EXEC="WoW.exe"
        ;;
    tbc)
        WOW_DIR="wow_tbc"
        WOW_EXEC="Wow.exe"
        ;;
    cata)
        WOW_DIR="cata"
        WOW_EXEC="Wow-64.exe"
        ;;
    *)
        WOW_DIR="wow"
        WOW_EXEC="Wow.exe"
        ;;
esac

WOW_PATH_MOUNTED="$BASE_PATH_MOUNTED/$WOW_DIR/$WOW_EXEC"
WOW_PATH_DOWNLOADS="$BASE_PATH_DOWNLOADS/$WOW_DIR/$WOW_EXEC"
WOW_PATH_MEDIA="$BASE_PATH_MEDIA/$WOW_DIR/$WOW_EXEC"

# Check for executable and run
if [ -f "$WOW_PATH_MOUNTED" ]; then
    wine "$WOW_PATH_MOUNTED"
elif [ -f "$WOW_PATH_DOWNLOADS" ]; then
    wine "$WOW_PATH_DOWNLOADS"
elif [ -f "$WOW_PATH_MEDIA" ]; then
    wine "$WOW_PATH_MEDIA"
else
    echo "$WOW_EXEC not found in any of the specified locations for $WOW_DIR."
fi

