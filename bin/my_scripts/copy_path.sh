#!/bin/bash

# Usage examples:
# ./copy_path.sh {code_root_dir}/Code
# ./copy_path.sh {my_notes_path}/test
# ./copy_path.sh /home/jonas/Code
# ./copy_path.sh /home/jonas/Code 1
# ./copy_path.sh /home/jonas/test
# ./copy_path.sh /home/jonas/Documents/my_notes/notes
# ./copy_path.sh /home/jonas/Documents/my_notes/notes 1
# Multiple files
# ./copy_path.sh /home/jonas/Documents/my_notes/notes,/home/jonas/Documents/my_notes/test.txt
# ./copy_path.sh "/home/jonas/Documents/my_notes/notes /home/jonas/Documents/my_notes/test.txt"

if [[ -z "$my_notes_path" || -z "$code_root_dir" ]]; then
    echo "Environment variables 'my_notes_path' or 'code_root_dir' are not set."
    exit 1
fi

if [[ -n "$ps_profile_path" ]]; then
    use_ps_profile_path=true
else
    use_ps_profile_path=false
fi

normalize_path() {
    local path="$1"
    path=$(echo "$path" | sed 's,\\\\,/,g')  # Replace backslashes with slashes
    path=$(echo "$path" | sed 's,//\+,/,g')  # Remove consecutive slashes
    echo "$path"
}

replace_path_based_on_context() {
    local input_path="$1"
    local no_placeholders="$2"

    input_path=$(echo "$input_path" | sed "s|^~/|$HOME/|g")

    input_path=$(normalize_path "$input_path")

    if [[ -z "$no_placeholders" ]]; then
        if [[ "$input_path" == *"{my_notes_path}/"* || "$input_path" == *"{code_root_dir}/"* ]]; then
            input_path=$(echo "$input_path" | sed "s|{my_notes_path}/|$my_notes_path/|g")
            input_path=$(echo "$input_path" | sed "s|{code_root_dir}/|$code_root_dir/|g")
        else
            input_path=$(echo "$input_path" | sed "s|$my_notes_path/|{my_notes_path}/|g")

            if [[ "$input_path" == "$code_root_dir/Code"* ]]; then
                input_path=$(echo "$input_path" | sed "s|$code_root_dir/|{code_root_dir}/|g")
            fi
        fi

        if $use_ps_profile_path; then
            if [[ "$input_path" == *"{ps_profile_path}/"* ]]; then
                input_path=$(echo "$input_path" | sed "s|{ps_profile_path}/|$ps_profile_path/|g")
            else
                input_path=$(echo "$input_path" | sed "s|$ps_profile_path/|{ps_profile_path}/|g")
            fi
        fi
    fi

    input_path=$(normalize_path "$input_path")

    echo "$input_path"
}

input_line="$1"
no_placeholders="$2"

if [[ -z "$input_line" ]]; then
    echo "Usage: $0 <input_line> [no_placeholders]"
    exit 1
fi

format_paths() {
    local line="$1"
    local delimiter="$2"
    local dir
    local formatted_line=""

    # Extract dir from first file path
    dir=$(dirname "$(echo "$line" | cut -d"$delimiter" -f1)")

    # Process each part separated by delimiter
    IFS="$delimiter" read -ra paths <<< "$line"
    for path in "${paths[@]}"; do
        # Check if path contains a forward slash; if not, prepend dir path
        if [[ "$path" != */* ]]; then
            path="$dir/$path"
        fi
        formatted_line+="$path$delimiter"
    done

    # Remove trailing delimiter
    echo "${formatted_line%$delimiter}"
}

# Determine delimiter and process accordingly
if [[ "$input_line" == *,* && "$input_line" != *,*/,* ]]; then
    input_line=$(format_paths "$input_line" ",")
elif [[ "$input_line" == *" "* && "$input_line" != *" "*/*" "* ]]; then
    input_line=$(format_paths "$input_line" " ")
fi

echo -n "$input_line" | xclip -selection clipboard

echo "Updated input_line: $input_line"

output_line=$(replace_path_based_on_context "$input_line" "$no_placeholders")
echo "Processed line: $output_line"
echo -n "$output_line" | xclip -selection clipboard
echo "Path copied to clipboard."

