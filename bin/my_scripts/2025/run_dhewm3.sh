#!/bin/bash
set -e  # Exit immediately if any command fails

# Set code_root_dir if not already defined
if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi
echo "Using code root directory: $code_root_dir"

# Determine the downloads directory
if [ -d "/mnt/new/other" ] || [ -d "/mnt/new/my_files" ]; then
    DOWNLOADS_DIR="/mnt/new"
else
    DOWNLOADS_DIR="$HOME/Downloads"
fi
echo "Using downloads directory: $DOWNLOADS_DIR"

# Define the target build directory for dhewm3
TARGET_DIR="$code_root_dir/Code2/C++/dhewm3/build"
echo "Changing directory to: $TARGET_DIR"
cd "$TARGET_DIR"

# Define the base directory and target file
BASE_DIR="$TARGET_DIR/base"
TARGET_FILE="$BASE_DIR/game00.pk4"

# Check if the base directory or target file is missing
if [ ! -d "$BASE_DIR" ] || [ ! -f "$TARGET_FILE" ]; then
    echo "Either '$BASE_DIR' does not exist or '$TARGET_FILE' is missing."
    echo "Copying 'base' directory from '$DOWNLOADS_DIR/doom3/base' to '$TARGET_DIR'..."
    cp -r "$DOWNLOADS_DIR/doom3/base" "$TARGET_DIR"
    echo "Copy complete."
else
    echo "'base' directory and '$TARGET_FILE' already exist. Skipping copy."
fi

# Run the dhewm3 executable
echo "Starting dhewm3..."
./dhewm3

