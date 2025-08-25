#!/bin/bash
set -e  # Exit immediately if any command fails

# Determine the code root directory (use env variable if set, otherwise fallback to $HOME)
if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi

# Define the base directory where OpenJKDF2 source is expected to be
BASE_OPENJKDF2_DIR="$code_root_dir/Code2/C++/OpenJKDF2"

if [ ! -d "$BASE_OPENJKDF2_DIR" ]; then
    echo "Error: Directory $BASE_OPENJKDF2_DIR does not exist."
    exit 1
fi

# Find a build directory matching "build_linux*" (if multiple, pick the first)
build_dir=$(find "$BASE_OPENJKDF2_DIR" -maxdepth 1 -type d -name "build_linux*" 2>/dev/null | head -n 1)

if [ -z "$build_dir" ]; then
    echo "Error: No build directory matching 'build_linux*' was found in $BASE_OPENJKDF2_DIR."
    exit 1
fi

echo "Found build directory: $build_dir"

# Verify that the executable exists in the build directory
executable="$build_dir/openjkdf2"
if [ ! -x "$executable" ]; then
    echo "Error: Executable 'openjkdf2' not found or not executable in $build_dir."
    exit 1
fi

# Set the destination directory and create it if it doesn't exist
DEST_DIR="$HOME/.local/share/OpenJKDF2/openjkdf2"
mkdir -p "$DEST_DIR"

# Copy the executable to the destination directory
cp "$executable" "$DEST_DIR/"
echo "Executable 'openjkdf2' has been copied from $executable -> $DEST_DIR/"

# Change directory to the destination
cd "$DEST_DIR"

# Run the executable
./openjkdf2

