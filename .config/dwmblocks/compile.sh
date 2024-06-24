#!/bin/bash

# Paths
CONFIG_FILE="./config.h"
TEMP_FILE="./config_temp.h"
BACKUP_FILE="./config_backup.h"

# Backup original config.h
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Check for the presence of a battery
battery_present=false
for battery in /sys/class/power_supply/BAT?*; do
    if [ -e "$battery" ]; then
        battery_present=true
        break
    fi
done

# If no battery is found, use internet cmd in statusbar instead
if ! $battery_present; then
    echo "No battery found. Modifying config.h..."

    sed 's/\(^.*sb-battery.*$\)/\/\* \1 \*\//' "$CONFIG_FILE" > "$TEMP_FILE"
    sed -i 's/\/\* \(.*sb-internet.*\) \*\//\1/' "$TEMP_FILE"

    mv "$TEMP_FILE" "$CONFIG_FILE"
fi

# Compile
sudo make clean install

# If no battery was found, revert config.h to its original state
if ! $battery_present; then
    mv "$BACKUP_FILE" "$CONFIG_FILE"
    echo "config.h reverted to its original state."
fi

rm -f "$BACKUP_FILE"

echo "Script execution completed."

