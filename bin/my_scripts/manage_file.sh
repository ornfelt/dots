#!/bin/bash

show_menu() {
    local options=$(cat <<-EOF
[1] chmod +x "$1"
[2] chmod -x "$1"
[3] tar -xvf "$1"
[4] zip "$1.zip" "$1"
[5] unzip "$1"
[6] exit
EOF
)
    if [[ -n "$2" ]]; then
        echo "$options" | rofi -dmenu -p "Choose a command for $1"
    else
        #echo "$options" | dmenu -i -l 20 -p "Choose a command for $1:"
        echo "$options" | dmenu -i -l 20
    fi
}

# Validate arguments
if [[ -z "$1" ]]; then
    echo "Usage: $0 <file_or_directory_path> [use_rofi]"
    exit 1
fi

path="$1"

# Ensure the path exists
if [[ ! -e "$path" ]]; then
    echo "Error: Path does not exist: $path"
    exit 1
fi

# Display the menu and capture the choice
choice=$(show_menu "$path" "$2" | awk '{print $1}' | tr -d '[]')

# Execute the chosen command based on the number
case "$choice" in
    1)
        if [[ -f "$path" ]]; then
            chmod +x "$path" && echo "Made $path executable."
        else
            echo "Error: $path is not a file."
        fi
        ;;
    2)
        if [[ -f "$path" ]]; then
            chmod -x "$path" && echo "Removed executable permission from $path."
        else
            echo "Error: $path is not a file."
        fi
        ;;
    3)
        if [[ -f "$path" && "$path" == *.tar* ]]; then
            tar -xvf "$path" && echo "Extracted $path."
        else
            echo "Error: $path is not a valid tar file."
        fi
        ;;
    4)
        if [[ -f "$path" ]]; then
            zip "$path.zip" "$path" && echo "Zipped $path to $path.zip."
        else
            echo "Error: $path is not a file."
        fi
        ;;
    5)
        if [[ -f "$path" && "$path" == *.zip ]]; then
            unzip "$path" && echo "Unzipped $path."
        else
            echo "Error: $path is not a valid zip file."
        fi
        ;;
    6)
        echo "Exiting."
        ;;
    *)
        echo "Invalid option or no option selected."
        ;;
esac
