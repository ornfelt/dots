#!/bin/bash

# Array of packages to exclude from installation
exclude_packages=("linux" "linux-firmware" "yay" "yay-git" "vlc")
exclude_patterns=("docker" "linux-headers-rpi" "rpi-" "raspberrypi" "raspi" "arm32" "arm64")

# Array to hold missing packages
missing_packages=()

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

# Function to check missing packages for Arch
check_missing_arch() {
    for file in pk1.txt pk2.txt pk3.txt; do
        while read -r pkg; do
            if ! is_excluded "$pkg"; then
                if ! pacman -Qs "$pkg" > /dev/null; then
                    echo "Missing package (Arch): $pkg"
                    missing_packages+=("$pkg")
                fi
            fi
        done < "$file"
    done
}

# Function to check missing packages for Debian
check_missing_debian() {
    for file in pk1.txt pk2.txt pk3.txt; do
        while read -r pkg; do
            if ! is_excluded "$pkg"; then
                if ! dpkg -s "$pkg" &> /dev/null; then
                    echo "Missing package (Debian): $pkg"
                    missing_packages+=("$pkg")
                fi
            fi
        done < "$file"
    done
}

# Function to install missing packages for Arch
install_missing_arch() {
    for pkg in "${missing_packages[@]}"; do
        sudo pacman -S --noconfirm "$pkg"
    done
}

# Function to install missing packages for Debian
install_missing_debian() {
    for pkg in "${missing_packages[@]}"; do
        sudo apt-get install -y "$pkg"
    done
}

# Print the identified architecture and check for missing packages
if grep -q 'ID=arch' /etc/os-release; then
    echo "Architecture identified: Arch Linux"
    check_missing_arch
elif grep -q 'ID=debian' /etc/os-release || grep -q 'ID_LIKE=debian' /etc/os-release; then
    echo "Architecture identified: Debian-based"
    check_missing_debian
else
    echo "Unsupported Linux distribution."
    exit 1
fi

# Ask the user if they want to install missing packages
if [ "${#missing_packages[@]}" -gt 0 ]; then
    echo "Missing packages: ${missing_packages[@]}"
    read -p "Install missing packages? (yes/YES/y/Y to confirm): " user_input
    if [[ "$user_input" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if grep -q 'ID=arch' /etc/os-release; then
            install_missing_arch
        elif grep -q 'ID=debian' /etc/os-release || grep -q 'ID_LIKE=debian' /etc/os-release; then
            install_missing_debian
        fi
    else
        echo "Skipping installation of missing packages."
    fi
else
    echo "No missing packages found."
fi

