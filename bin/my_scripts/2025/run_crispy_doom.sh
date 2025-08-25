#!/bin/bash
set -e  # exit immediately if a command fails

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

# Change to the crispy-doom source directory
TARGET_DIR="$code_root_dir/Code2/C++/crispy-doom/src"
echo "Changing directory to: $TARGET_DIR"
cd "$TARGET_DIR"

# Define the command to run
CMD="./crispy-doom -iwad $DOWNLOADS_DIR/doom/DOOM/DOOM.WAD"
echo "Executing command: $CMD"

# Run the command
$CMD

