#!/bin/bash

mkdir -p packages

merge_requirements() {
    local req_file="$1"
    local temp_file="$2"
    local output_file="$req_file"

    if [[ -f "$req_file" ]]; then
        cp "$req_file" "$temp_file"
    fi

    pip freeze >> "$temp_file"
    awk -F'==' '!seen[tolower($1)]++' "$temp_file" | sort -f > "$output_file"
    rm -f "$temp_file"
}

if grep -q 'ID=arch' /etc/os-release; then
    pacman -Qe | awk '{print $1}' > package_list.txt
    pacman -Qm > other.txt

    pip freeze > requirements.txt
    merge_requirements "requirements.txt" "requirements_temp.txt"

    # Calculate number of lines for approximately one-third of the file
    total_lines=$(wc -l < package_list.txt)
    lines_per_file=$(( (total_lines + 2) / 3 )) # Add 2 for rounding up on division

    # Split file into three parts
    split -l "$lines_per_file" package_list.txt packages/pk --additional-suffix=.txt

    mv packages/pkaa.txt packages/pk1.txt
    mv packages/pkab.txt packages/pk2.txt
    mv packages/pkac.txt packages/pk3.txt

    cp ~/.bash_history ~/history.txt && cat ~/.zsh_history >> ~/history.txt

elif grep -q 'ID=debian' /etc/os-release || grep -q 'ID_LIKE=debian' /etc/os-release; then
    mkdir -p packages/debian

    pip freeze > packages/debian/requirements.txt
    merge_requirements "packages/debian/requirements.txt" "packages/debian/requirements_temp.txt"

    dpkg-query -W -f='${binary:Package}\n' | awk -F: '{print $1}' > packages/debian/package_list_all.txt
    # Get manually installed packages
    apt list --manual-installed | sed '1d; s#/.*##' > packages/debian/package_list.txt
    #apt list --manual-installed | awk 'NR > 1 {split($0, a, "/"); print a[1]}' > packages/debian/package_list.txt
    # Old:
    #comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) > packages/debian/package_list.txt
    # Using aptitude
    #comm -23 <(aptitude search '~i !~M' -F '%p' | sed "s/ *$//" | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u > packages/debian/package_list.txt

    # Calculate number of lines for approximately one-third of the file
    total_lines=$(wc -l < packages/debian/package_list.txt)
    lines_per_file=$(( (total_lines + 2) / 3 )) # Add 2 for rounding up on division

    # Split file into three parts
    split -l "$lines_per_file" packages/debian/package_list.txt packages/debian/pk --additional-suffix=.txt

    mv packages/debian/pkaa.txt packages/debian/pk1.txt
    mv packages/debian/pkab.txt packages/debian/pk2.txt
    mv packages/debian/pkac.txt packages/debian/pk3.txt

    cp ~/.bash_history ~/history.txt && cat ~/.zsh_history >> ~/history.txt
else
    echo "Unsupported Linux distribution."
    exit 1
fi

