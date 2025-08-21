#!/bin/bash

# Find all dirs in the current directory (excluding "scripts")
target_dirs=()
for dir in */; do
    [[ "$dir" == "scripts/" ]] && continue
    [[ -f "$dir/update.sh" ]] && target_dirs+=("${dir%/}")
done

# Print matching directories
echo "Directories with update.sh:"
for dir in "${target_dirs[@]}"; do
    echo "  $dir"
done

echo ""

# Now sync .sh and .py scripts from "scripts/" into each target dir
find scripts/ -type f \( -name "*.sh" -o -name "*.py" \) | while read -r src; do
    for dir in "${target_dirs[@]}"; do
        rel_path="${src#scripts/}"
        dest="$dir/$rel_path"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo "Copied: $src -> $dest"
    done
done

