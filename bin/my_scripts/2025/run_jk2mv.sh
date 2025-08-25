#!/bin/bash
set -e  # exit immediately if a command exits with a non-zero status

# Determine the downloads directory
if [ -d "/mnt/new/other" ] || [ -d "/mnt/new/my_files" ]; then
    DOWNLOADS_DIR="/mnt/new"
else
    DOWNLOADS_DIR="$HOME/Downloads"
fi
echo "Using downloads directory: $DOWNLOADS_DIR"

# Set default code root directory if not provided
if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi
echo "Using code root directory: $code_root_dir"

# Change to the release build directory
TARGET_DIR="$code_root_dir/Code/c++/jk2mv/build_new/out/Release"
echo "Changing directory to: $TARGET_DIR"
cd "$TARGET_DIR"

# Define source and destination for the 'base' directory
SOURCE_BASE="$DOWNLOADS_DIR/jedi_outcast_gamedata/base"
DEST_BASE="$TARGET_DIR/base"
TARGET_FILE="$DEST_BASE/assets0.pk3"

# Check if the destination 'base' directory exists
if [ -d "$DEST_BASE" ]; then
    echo "Destination directory '$DEST_BASE' exists."
    # Check if the target file exists
    if [ -f "$TARGET_FILE" ]; then
        echo "File '$TARGET_FILE' already exists. Skipping copy."
    else
        echo "File '$TARGET_FILE' not found. Copying 'base' directory from '$SOURCE_BASE' to '$TARGET_DIR'..."
        cp -r "$SOURCE_BASE" "$TARGET_DIR"
        echo "Copy complete."
    fi
else
    echo "Destination directory '$DEST_BASE' does not exist. Copying 'base' directory from '$SOURCE_BASE' to '$TARGET_DIR'..."
    cp -r "$SOURCE_BASE" "$TARGET_DIR"
    echo "Copy complete."
fi

# Execute the main program
echo "Starting jk2mvmp..."
./jk2mvmp

