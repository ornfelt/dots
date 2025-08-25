#!/bin/bash
set -e  # exit immediately if any command fails

# Determine the downloads directory
if [ -d "/mnt/new/other" ] || [ -d "/mnt/new/my_files" ]; then
    DOWNLOADS_DIR="/mnt/new"
else
    DOWNLOADS_DIR="$HOME/Downloads"
fi

# Determine destination directory for gta_vice and create it if necessary
GTA_VICE_DIR="$DOWNLOADS_DIR/gta_vice"
mkdir -p "$GTA_VICE_DIR"

# Make sure code_root_dir is defined (fall back to $HOME if not)
if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi

# The base directory where reVC executable build paths are expected.
BASE_RE3_VICE_DIR="$code_root_dir/Code/c++/re3_vice/bin"

# Find a directory that matches linux-*
linux_dir=$(find "$BASE_RE3_VICE_DIR" -maxdepth 1 -type d -name "linux-*" 2>/dev/null | head -n 1)

if [ -z "$linux_dir" ]; then
    echo "Error: No directory matching 'linux-*' was found in $BASE_RE3_VICE_DIR."
    exit 1
fi

echo "Found linux_dir: $linux_dir"

# Choose the build configuration: prefer "Release" then "Debug"
if [ -d "$linux_dir/Release" ]; then
    build_dir="$linux_dir/Release"
elif [ -d "$linux_dir/Debug" ]; then
    build_dir="$linux_dir/Debug"
else
    echo "Error: Neither Release nor Debug directory exists in $linux_dir."
    exit 1
fi

echo "Found build_dir: $build_dir"

# Verify that the executable exists
executable="$build_dir/reVC"
if [ ! -x "$executable" ]; then
    echo "Error: Executable 'reVC' not found or not executable in $build_dir."
    exit 1
fi

# Copy the executable to the destination directory
cp "$executable" "$GTA_VICE_DIR/"

echo "Executable 'reVC' has been copied from $executable -> $GTA_VICE_DIR/"

# Change directory to the destination and execute the file
cd "$GTA_VICE_DIR"
./reVC

