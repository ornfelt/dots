#!/bin/bash

show_menu() {
    local options=$(cat <<-EOF
[1] chmod +x
[2] chmod -x
[3] Extract tar
[4] Create zip
[5] Unzip
[6] Exit
EOF
)
    if [[ -n "$2" ]]; then
        echo "$options" | rofi -dmenu -p "Choose a command for the files"
    else
        #echo "$options" | dmenu -i -l 20 -p "Choose a command for the files"
        echo "$options" | dmenu -i -l 20
    fi
}

if [[ -z "$1" ]]; then
    echo "Usage: $0 <file_or_directory_paths> [use_rofi]"
    exit 1
fi

format_paths() {
    local line="$1"
    local dir
    local formatted_line=""

    # Extract dir from first file path
    dir=$(dirname "$(echo "$line" | cut -d',' -f1)")

    # Process each part separated by commas
    IFS=',' read -ra paths <<< "$line"
    for path in "${paths[@]}"; do
        # Check if path contains a forward slash; if not, prepend dir path
        if [[ "$path" != */* ]]; then
            path="$dir/$path"
        fi
        formatted_line+="$path,"
    done

    # Remove trailing comma
    echo "${formatted_line%,}"
}

path="$1"

if [[ "$path" == *,* && "$path" != *,*/,* ]]; then
    path=$(format_paths "$path")
fi

echo "Updated paths: $path"

IFS=',' read -ra paths <<< "$path"

for path in "${paths[@]}"; do
    if [[ ! -e "$path" ]]; then
        echo "Error: Path does not exist: $path"
        exit 1
    fi
done

choice=$(show_menu "$path" "$2" | awk '{print $1}' | tr -d '[]')

for path in "${paths[@]}"; do
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
            exit 0
            ;;
        *)
            echo "Invalid option or no option selected."
            ;;
    esac
done

