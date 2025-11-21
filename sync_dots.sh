#!/bin/sh

TARGET_DIR="$HOME/Downloads/dots"

# bail check
if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory does not exist: $TARGET_DIR"
  exit 1
fi

# Remove all files and subdirs except for ".git" in the target dir
find "$TARGET_DIR" -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +

# Copy all files and subdirs except for ".git" from current dir to target dir
find . -mindepth 1 -maxdepth 1 ! -name ".git" -exec cp -r {} "$TARGET_DIR" \;

cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }
git status
$SHELL

