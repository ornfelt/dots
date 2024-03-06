#!/bin/bash

# Array of packages to exclude from installation
exclude_packages=("linux" "linux-firmware" "yay" "yay-git")
exclude_patterns=("docker" "linux-headers-rpi" "rpi-" "raspberrypi-" "raspi-")

# Function to check if a package is in the exclusion list or matches an exclusion pattern
is_excluded() {
    local pkg_name="$1"

    # Check exact matches
    for excluded_pkg in "${exclude_packages[@]}"; do
        if [[ "$pkg_name" == "$excluded_pkg" ]]; then
            return 0 # Package is excluded
        fi
    done

    # Check patterns
    for pattern in "${exclude_patterns[@]}"; do
        if [[ "$pkg_name" == *"$pattern"* ]]; then
            return 0 # Package matches an exclusion pattern and is excluded
        fi
    done

    return 1 # Package is not excluded
}

# Function to install packages for Arch
install_arch() {
    for file in pk1.txt pk2.txt pk3.txt; do
        while read -r pkg; do
            if ! is_excluded "$pkg"; then
                sudo pacman -S --noconfirm "$pkg" 2>&1 | tee -a log.txt
                #echo "installing $pkg"
		sleep 1
            fi
        done < "$file"
    done
}

# Function to install packages for Debian
install_debian() {
    #for file in pk1.txt pk2.txt pk3.txt; do
    for file in pk3.txt; do
        while read -r pkg; do
            if ! is_excluded "$pkg"; then
                sudo apt-get install -y "$pkg" 2>&1 | tee -a log.txt
                #echo "installing $pkg"
            fi
        done < "$file"
    done
}

# Check the Linux distribution and call the appropriate function
if grep -q 'ID=arch' /etc/os-release; then
    echo "Use arch branch instead of this!"
    #install_arch
elif grep -q 'ID=debian' /etc/os-release || grep -q 'ID_LIKE=debian' /etc/os-release; then
    install_debian
else
    echo "Unsupported Linux distribution."
    exit 1
fi
