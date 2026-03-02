#!/usr/bin/env bash

# Usage:
# ./dump_files.sh <input_dir> [output_file] [recursive: true/false] [use_full_paths: true/false]
#
# Examples:
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl /tmp/shader_dump.txt
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders /tmp/shader_dump.txt true
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders /tmp/shader_dump.txt true true

# Hard-coded toggle: when true, prints metadata header at top of dump file
INCLUDE_METADATA_HEADER=false
#INCLUDE_METADATA_HEADER=true

# --- Args ---
INPUT_DIR="${1}"
OUTPUT_FILE="${2:-$(pwd)/dumped_files.txt}"
RECURSIVE="${3:-false}"
USE_FULL_PATHS="${4:-false}"

# Normalize booleans (accept true/1/yes)
to_bool() {
    case "${1,,}" in
        true|1|yes) echo true ;;
        *)          echo false ;;
    esac
}
RECURSIVE=$(to_bool "$RECURSIVE")
USE_FULL_PATHS=$(to_bool "$USE_FULL_PATHS")

# --- Validate input dir ---
if [[ -z "$INPUT_DIR" ]]; then
    echo "Usage: $0 <input_dir> [output_file] [recursive: true/false] [use_full_paths: true/false]" >&2
    exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory does not exist or is not a directory: $INPUT_DIR" >&2
    exit 1
fi

# Resolve to absolute path
RESOLVED_INPUT_DIR="$(cd "$INPUT_DIR" && pwd)"

# --- Ensure output directory exists ---
OUTPUT_PARENT="$(dirname "$OUTPUT_FILE")"
if [[ -z "$OUTPUT_PARENT" || "$OUTPUT_PARENT" == "." ]]; then
    OUTPUT_PARENT="$(pwd)"
    OUTPUT_FILE="${OUTPUT_PARENT}/${OUTPUT_FILE}"
elif [[ ! -d "$OUTPUT_PARENT" ]]; then
    mkdir -p "$OUTPUT_PARENT"
fi

# --- Collect files ---
if [[ "$RECURSIVE" == true ]]; then
    mapfile -d '' files < <(find "$RESOLVED_INPUT_DIR" -type f -print0 | sort -z)
else
    mapfile -d '' files < <(find "$RESOLVED_INPUT_DIR" -maxdepth 1 -type f -print0 | sort -z)
fi

# --- Build output ---
{
    # Optional metadata header
    if [[ "$INCLUDE_METADATA_HEADER" == true ]]; then
        echo "Dump generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "InputDir: $RESOLVED_INPUT_DIR"
        echo "Recursive: $RECURSIVE"
        echo "UseFullPaths: $USE_FULL_PATHS"
        printf '=%.0s' {1..80}; echo
        echo
    fi

    for file in "${files[@]}"; do
        if [[ "$USE_FULL_PATHS" == true ]]; then
            header_name="$file"
        else
            if [[ "$RECURSIVE" == true ]]; then
                # Relative path from input dir
                header_name="${file#"${RESOLVED_INPUT_DIR}"/}"
            else
                # Just filename
                header_name="$(basename "$file")"
            fi
        fi

        echo "${header_name}:"
        echo

        if content=$(cat "$file" 2>/dev/null); then
            printf '%s' "$content"
        else
            echo "[ERROR reading file: $file]"
        fi

        # Ensure separation between files
        echo
        echo
        printf '%.0s-' {1..80}; echo
        echo
    done
} > "$OUTPUT_FILE"

echo "Dumped ${#files[@]} file(s) to: $OUTPUT_FILE"
