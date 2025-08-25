#!/bin/bash
set -e  # exit immediately if a command exits with a non-zero status

# Determine the downloads directory
if [ -d "/mnt/new/other" ] || [ -d "/mnt/new/my_files" ]; then
    DOWNLOADS_DIR="/mnt/new"
else
    DOWNLOADS_DIR="$HOME/Downloads"
fi

# Determine destination directory and create it if necessary
GTA3_DIR="$DOWNLOADS_DIR/gta3"
mkdir -p "$GTA3_DIR"

# Make sure code_root_dir is defined (fall back to $HOME if not)
if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi

# The base directory where re3 executable build paths are expected.
BASE_RE3_DIR="$code_root_dir/Code/c++/re3/bin"

# Find a directory that matches linux-*
linux_dir=$(find "$BASE_RE3_DIR" -maxdepth 1 -type d -name "linux-*" 2>/dev/null | head -n 1)

if [ -z "$linux_dir" ]; then
    echo "Error: No directory matching 'linux-*' was found in $BASE_RE3_DIR."
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
executable="$build_dir/re3"
if [ ! -x "$executable" ]; then
    echo "Error: Executable 're3' not found or not executable in $build_dir."
    exit 1
fi

# Copy the executable to the destination directory
cp "$executable" "$GTA3_DIR/"

echo "Executable 're3' has been copied from $executable -> $GTA3_DIR/"

# Change directory to the destination and execute the file
cd "$GTA3_DIR"
./re3

