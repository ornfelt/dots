#!/bin/bash
set -e  # exit immediately if a command exits with a non-zero status

# Fix OpenDiablo2 config.json if it exists
if [ -f "$HOME/.config/OpenDiablo2/config.json" ]; then
    DIABLO_DIRS=(
        "/mnt/new/d2/"
        "$HOME/Downloads/d2/"
        #"/media/2024/d2/"
    )

    NEW_PATH=""
    # Check each directory and set NEW_PATH to the first one that exists
    for DIR in "${DIABLO_DIRS[@]}"; do
        if [ -d "$DIR" ]; then
            NEW_PATH="$DIR"
            break
        fi
    done

    # Check if a new path was found
    if [ -z "$NEW_PATH" ]; then
        echo "No valid Diablo 2 directory found."
    fi

    if [ -n "$NEW_PATH" ]; then
        NEW_PATH="${NEW_PATH}d2video"
    fi

    ESCAPED_NEW_PATH=$(echo "$NEW_PATH" | sed 's/\\/\\\\/g')

    # Update config.json file with new path
    sed -i "s|\"MpqPath\": \".*\"|\"MpqPath\": \"$ESCAPED_NEW_PATH\"|g" $HOME/.config/OpenDiablo2/config.json
    echo "Updated config.json with new MpqPath path: $NEW_PATH"
else
    echo "$HOME/.config/config.json does NOT exist yet. OpenDiablo2 has not been run yet..."
fi

if [ -z "$code_root_dir" ]; then
    code_root_dir="$HOME"
fi

cd $code_root_dir/Code2/Go/OpenDiablo2 && ./OpenDiablo2

