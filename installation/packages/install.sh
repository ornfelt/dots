#!/bin/bash

# Boolean for testing mode (dry / wet run)
testing_mode=false

# Array of packages to exclude from installation
exclude_packages=("linux" "linux-firmware" "yay" "yay-git" "vlc")
exclude_patterns=("docker" "linux-headers-rpi" "rpi-" "raspberrypi" "raspi" "arm32" "arm64")

# Function to check if a package is in the exclusion list or matches an exclusion pattern
is_excluded() {
    local pkg_name="$1"

    # Check exact matches
    for excluded_pkg in "${exclude_packages[@]}"; do
        if [[ "$pkg_name" == "$excluded_pkg" ]]; then
            echo "Skipping $pkg_name due to exclusion in exclude_packages"
            return 0 # Package is excluded
        fi
    done

    # Check patterns
    for pattern in "${exclude_patterns[@]}"; do
        if [[ "$pkg_name" == *"$pattern"* ]]; then
            echo "Skipping $pkg_name due to matching pattern in exclude_patterns"
            return 0 # Package matches an exclusion pattern and is excluded
        fi
    done

    return 1 # Package is not excluded
}

install_arch() {
    for file in pk1.txt pk2.txt pk3.txt; do
    #for file in pk3.txt; do # One pkX file per run...
        while read -r pkg; do
            if ! is_excluded "$pkg"; then
                if [ "$testing_mode" = true ]; then
                    echo "Testing mode: Installing $pkg"
                else
                    sudo pacman -S --noconfirm "$pkg" 2>&1 | tee -a log.txt
                    sleep 3
                fi
            fi
        done < "$file"
    done
}

install_debian() {
    for file in debian/pk1.txt debian/pk2.txt debian/pk3.txt; do
    #for file in debian/pk1.txt; do # One pkX file per run...
        while read -r pkg; do
            if ! is_excluded "$pkg"; then
                if [ "$testing_mode" = true ]; then
                    echo "Testing mode: Installing $pkg"
                else
                    sudo apt-get install -y "$pkg" 2>&1 | tee -a log.txt
                    sleep 3
                fi
            fi
        done < "$file"
    done
}

if grep -q 'ID=arch' /etc/os-release; then
    echo "Architecture identified: Arch Linux"
    install_arch
elif grep -q 'ID=debian' /etc/os-release || grep -q 'ID_LIKE=debian' /etc/os-release; then
    echo "Architecture identified: Debian-based"
    install_debian
else
    echo "Unsupported Linux distribution."
    exit 1
fi

