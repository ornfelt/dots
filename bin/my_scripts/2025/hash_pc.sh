#!/bin/bash

# Function to get CPU info using lshw
get_cpu_info() {
    local cpu_info=$(lshw -class processor | grep 'product' | head -n 1 | awk -F': ' '{print $2}')
    echo "$cpu_info"
}

# Function to get GPU info using lshw
get_gpu_info() {
    local gpu_info=$(lshw -class display | grep 'product' | head -n 1 | awk -F': ' '{print $2}')
    echo "$gpu_info"
}

# Check the availability of lshw
use_lspci=false
if ! command -v lshw &> /dev/null; then
    use_lspci=true
fi
# To force lspci (uncomment to force lspci - will be set automatically if lshw
# is not available)
use_lspci=true

# Quit if not sudo (required for lshw at least)
if ! $use_lspci; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root or with sudo."
        exit 1
    fi
fi

# Alternative function using lspci for CPU (proxy using lscpu)
get_cpu_info_lspci() {
    local cpu_info=$(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)
    echo "$cpu_info"
}

# Alternative function using lspci for GPU
get_gpu_info_lspci() {
    local gpu_info=$(lspci | grep -iE 'vga|3d' | head -n1 | cut -d ':' -f3 | xargs)
    echo "$gpu_info"
}

# Determine method and retrieve information
if $use_lspci; then
    echo "Using lspci methods for retrieving hardware info:"
    cpu_info=$(get_cpu_info_lspci)
    gpu_info=$(get_gpu_info_lspci)
else
    echo "Using lshw for retrieving hardware info:"
    cpu_info=$(get_cpu_info)
    gpu_info=$(get_gpu_info)
fi

# Print CPU and GPU info
echo "CPU: $cpu_info"
echo "GPU: $gpu_info"

# Combine and hash the information
combined_info="${cpu_info}_${gpu_info}"
hash=$(echo -n "$combined_info" | sha256sum | cut -c1-10)

echo "Unique hardware hash: $hash"

