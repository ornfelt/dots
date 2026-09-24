#!/usr/bin/env bash
set -euo pipefail

# Ensure we're in a dir with the necessary files, or fall back
if [[ -f "./blocks.h" && -f "./dwmblocks.c" && -f "./Makefile" ]]; then
    echo "Using dwmblocks sources in $(pwd)"
elif [[ -f "$HOME/.config/dwmblocks/blocks.h" ]]; then
    echo "Switching to ~/.config/dwmblocks"
    cd "$HOME/.config/dwmblocks"
else
    echo "Error: blocks.h, dwmblocks.c or Makefile not found here or in ~/.config/dwmblocks."
    exit 1
fi

# Paths
CONFIG_FILE="./blocks.h"
TEMP_FILE="./config_temp.h"
BACKUP_FILE="./config_backup.h"

# Backup original blocks.h and restore it on exit, even if the build fails
cp "$CONFIG_FILE" "$BACKUP_FILE"
restore_config() {
    mv "$BACKUP_FILE" "$CONFIG_FILE"
}
trap restore_config EXIT

# Check battery presence
battery_present=false
for battery in /sys/class/power_supply/BAT?*; do
    if [ -e "$battery" ]; then
        battery_present=true
        break
    fi
done

# If no battery is found, use internet cmd in statusbar instead
if ! $battery_present; then
    echo "No battery found. Modifying blocks.h..."

    sed 's/\(^.*sb-battery.*$\)/\/\* \1 \*\//' "$CONFIG_FILE" > "$TEMP_FILE"
    sed -i 's/\/\* \(.*sb-internet.*\) \*\//\1/' "$TEMP_FILE"

    mv "$TEMP_FILE" "$CONFIG_FILE"
fi

# Compile
make clean
make
sudo make install

echo "Script execution completed."

