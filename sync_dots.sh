#!/bin/sh

TARGET_DIR="$HOME/Downloads/dots"

# Remove all files and subdirectories except for ".git" in the target directory
find "$TARGET_DIR" -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +

# Copy all files and subdirectories except for ".git" from the current directory to the target directory
find . -mindepth 1 -maxdepth 1 ! -name ".git" -exec cp -r {} "$TARGET_DIR" \;

cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }
git status
$SHELL

