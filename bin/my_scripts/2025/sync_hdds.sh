#!/bin/bash

set -e

SRC_ROOT="/media2"
DEST_ROOT="/media"

# Exit if /media/Movies already exists
#if [ -d "$DEST_ROOT/Movies" ]; then
#    echo "Directory $DEST_ROOT/Movies already exists. Exiting."
#    exit 0
#fi

# Create required directory structure
echo "Creating directories under $DEST_ROOT..."
mkdir -p "$DEST_ROOT/Movies/Series/Anime"
mkdir -p "$DEST_ROOT/Movies/Movies"

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

# Copy from /media2/Movies/Movies to /media/Movies/Movies
echo "Copying from $SRC_ROOT/Movies/Movies to $DEST_ROOT/Movies/Movies..."
for entry in "$SRC_ROOT/Movies/Movies"/*; do
    copy_with_wait "$entry" "$DEST_ROOT/Movies/Movies"
done

# Copy from /media2/Movies/Series to /media/Movies/Series (except Anime)
echo "Copying from $SRC_ROOT/Movies/Series to $DEST_ROOT/Movies/Series..."
for entry in "$SRC_ROOT/Movies/Series"/*; do
    name=$(basename "$entry")
    if [ "$name" == "Anime" ]; then
        continue
    fi
    copy_with_wait "$entry" "$DEST_ROOT/Movies/Series"
done

# Special handling for Anime
echo "Copying Anime folder content one-by-one..."
for anime_entry in "$SRC_ROOT/Movies/Series/Anime"/*; do
    copy_with_wait "$anime_entry" "$DEST_ROOT/Movies/Series/Anime"
done

echo "[ok] All copy operations completed."

