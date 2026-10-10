#!/bin/bash

# Include /etc/machine-id in the hash to make it per machine (not just per
# CPU/GPU model) - note that the machine-id changes on an OS reinstall
include_machine_id=false

get_cpu_info_lspci() {
    local cpu_info=$(LC_ALL=C lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)
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
if $include_machine_id; then
    machine_id=$(cat /etc/machine-id)
    echo "Machine ID: $machine_id"
    combined_info="${combined_info}_${machine_id}"
fi
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

