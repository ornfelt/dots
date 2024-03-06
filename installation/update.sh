#!/bin/bash

# Ensure the packages directory exists
mkdir -p packages

# Check the Linux distribution and call the appropriate function
if grep -q 'ID=arch' /etc/os-release; then
    # Execute commands and save output to files
    pacman -Qe | awk '{print $1}' > package_list.txt
    pacman -Qm > other.txt
elif grep -q 'ID=debian' /etc/os-release || grep -q 'ID_LIKE=debian' /etc/os-release; then
    # All packages
    dpkg-query -W -f='${binary:Package}\n' | awk -F: '{print $1}' > package_list_all.txt
    # Get only manually installed packages
    apt list --manual-installed | sed '1d; s#/.*##' > package_list.txt
    #apt list --manual-installed | awk 'NR > 1 {split($0, a, "/"); print a[1]}' > package_list.txt
    # Old:
    #comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) > package_list.txt
    # Using aptitude
    #comm -23 <(aptitude search '~i !~M' -F '%p' | sed "s/ *$//" | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u > package_list.txt
else
    echo "Unsupported Linux distribution."
    exit 1
fi

pip freeze > requirements.txt
# Calculate the number of lines approximately one-third of the file
total_lines=$(wc -l < package_list.txt)
lines_per_file=$(( (total_lines + 2) / 3 )) # Add 2 for rounding up on division

# Split the file into three parts
split -l "$lines_per_file" package_list.txt packages/pk --additional-suffix=.txt

# Rename the split files to pk1, pk2, pk3
mv packages/pkaa.txt packages/pk1.txt
mv packages/pkab.txt packages/pk2.txt
mv packages/pkac.txt packages/pk3.txt

cp ~/.bash_history ~/history.txt && cat ~/.zsh_history >> ~/history.txt
