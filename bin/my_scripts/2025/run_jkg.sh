#!/bin/bash
set -e  # Exit immediately if any command fails

# Set code_root_dir if not already defined
if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi
echo "Using code root directory: $code_root_dir"

# Define paths for JediAcademy data
JA_DATA_DIR="$HOME/Downloads/ja_data/JediAcademy"
JA_BASE_DIR="$JA_DATA_DIR/base"
TARGET_FILE="$JA_BASE_DIR/assets0.pk3"

# Check if the 'base' directory or assets file in JediAcademy data is missing
if [ ! -d "$JA_BASE_DIR" ] || [ ! -f "$TARGET_FILE" ]; then
    echo "Either '$JA_BASE_DIR' does not exist or '$TARGET_FILE' is missing."
    echo "Copying the 'base' directory from openjk to the target directory..."
    sudo cp -r "$HOME/.local/share/openjk/JediAcademy/base" "$JA_DATA_DIR"
    echo "Copy complete."
else
    echo "'base' directory and '$TARGET_FILE' already exist. Skipping copy."
fi

# Change directory to the Jedi Knight Galaxies source folder
JKG_DIR="$code_root_dir/Code/c++/JediKnightGalaxies"
echo "Changing directory to Jedi Knight Galaxies source: $JKG_DIR"
cd "$JKG_DIR"

# Copy the default configuration file to the JediAcademy base directory
echo "Copying default configuration using sudo..."
sudo cp JKGalaxies/JKG_Defaults.cfg "$JA_BASE_DIR"
echo "Default configuration copy complete."

# Change directory to the JediAcademy data directory to run the game
echo "Changing directory to: $JA_DATA_DIR"
cd "$JA_DATA_DIR"

# Run the Jedi Knight Galaxies executable
echo "Starting jkgalaxies.x86_64..."
./jkgalaxies.x86_64

