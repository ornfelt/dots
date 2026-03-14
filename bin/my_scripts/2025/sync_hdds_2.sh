#!/bin/bash

set -e
# enable Bash’s dotglob so * also matches hidden entries.
shopt -s dotglob nullglob

SRC_ROOT="/media"
DEST_ROOT="/media2"

# Note: Run this for 2024/2025/my_files and run sync_hdds.sh for Movies

# Exit if 2024 already exists in DEST_ROOT
#if [ -d "$DEST_ROOT/2024" ]; then
#    echo "Directory $DEST_ROOT/2024 already exists. Exiting."
#    exit 0
#fi

# Create required directory structure
echo "Creating directories under $DEST_ROOT..."
mkdir -p "$DEST_ROOT/my_files"
mkdir -p "$DEST_ROOT/2024"
mkdir -p "$DEST_ROOT/2025"

copy_with_wait() {
    local src_path="$1"
    local dest_dir="$2"
    local name
    name=$(basename "$src_path")
    local dest_path="$dest_dir/$name"

    if [ -e "$dest_path" ]; then
        echo "Skipping '$name' - already exists at destination."
        return
    fi

    echo "Copying $name -> $dest_dir"
    cp -r "$src_path" "$dest_dir"

    if [ -d "$src_path" ]; then
        # 20% chance to sleep 60s, else 30s
        if (( RANDOM % 5 == 0 )); then
            echo "Copied directory '$name'. Sleeping 60 seconds (lucky delay)..."
            sleep 60
        else
            echo "Copied directory '$name'. Sleeping 30 seconds..."
            sleep 30
        fi
    fi
}

echo "Copying from $SRC_ROOT/2024 to $DEST_ROOT/2024..."
for entry in "$SRC_ROOT/2024"/*; do
    copy_with_wait "$entry" "$DEST_ROOT/2024"
done

echo "Copying from $SRC_ROOT/2025 to $DEST_ROOT/2025..."
for entry in "$SRC_ROOT/2025"/*; do
    copy_with_wait "$entry" "$DEST_ROOT/2025"
done

echo "Copying from $SRC_ROOT/my_files to $DEST_ROOT/my_files..."
for entry in "$SRC_ROOT/my_files"/*; do
    copy_with_wait "$entry" "$DEST_ROOT/my_files"
done

echo "[ok] All copy operations completed."

