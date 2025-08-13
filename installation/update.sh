#!/bin/bash

get_cpu_info_lspci() {
    local cpu_info=$(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)
    echo "$cpu_info"
}

get_gpu_info_lspci() {
    local gpu_info=$(lspci | grep -iE 'vga|3d' | head -n1 | cut -d ':' -f3 | xargs)
    echo "$gpu_info"
}

echo "Using lspci methods for retrieving hardware info:"
cpu_info=$(get_cpu_info_lspci)
gpu_info=$(get_gpu_info_lspci)

# Print CPU and GPU info
echo "CPU: $cpu_info"
echo "GPU: $gpu_info"

# Combine and hash the information
combined_info="${cpu_info}_${gpu_info}"
hash=$(echo -n "$combined_info" | sha256sum | cut -c1-10)

echo "Unique hardware hash: $hash"

if [ -d "$hash" ]; then
    echo "Directory '$hash' already exists."
else
    echo "Directory '$hash' does not exist. Creating directory."
    mkdir "$hash"
    echo "Copying files from scripts to '$hash'."
    cp -r scripts/* "$hash" || { echo "Failed to copy files"; exit 1; }
fi

# Change directory and run the update script
cd "$hash" || { echo "Failed to change directory to '$hash'."; exit 1; }

if [ -f "./update.sh" ]; then
    echo "Running update.sh script."
    ./update.sh || { echo "update.sh script failed."; exit 1; }
else
    echo "'update.sh' script does not exist in '$hash'."
    exit 1
fi

