#!/usr/bin/env bash

# Usage:
# ./dump_files.sh <input_dir> [output_file] [recursive: true/false] [use_full_paths: true/false] [extensions: ".ext1 .ext2 ..."] [exclude_dirs: "obj bin"]
#        [--include-patterns ...] [--exclude-patterns ...] [--metadata-header] [--debug-command]
#
# Every positional arg is also available as a named option (--input-dir, --output-file,
# --recursive, --full-paths, --extensions, --exclude-dirs). List values accept spaces or commas.
#
# Examples:
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl /tmp/shader_dump.txt
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders /tmp/shader_dump.txt true
# ./dump_files.sh $code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders /tmp/shader_dump.txt true true
# ./dump_files.sh $code_root_dir/Code2/Wow/tools/my_wow/c++/my_web_wow/src /tmp/dump.txt true false ".cpp .h"
# Use cwd and only .cs files:
# ./dump_files.sh . "" false false ".cs"
# cpp example:
# ./dump_files.sh $code_root_dir/Code2/Wow/tools/my_wow/c++/my_web_wow/src "" false false ".cpp .c .h .hpp"
#
# New options:
# All .cs files recursively, ignoring the "obj" and "bin" dirs:
# ./dump_files.sh . --recursive true --extensions ".cs" --exclude-dirs "obj bin"
# ./dump_files.sh . "" true false ".cs" "obj bin"          # same thing, positional
# Same, but also skipping generated files:
# ./dump_files.sh . --recursive true --extensions ".cs" --exclude-dirs "obj bin" --exclude-patterns "*.g.cs *.Designer.cs"
# Only files matching a name pattern (recursive):
# ./dump_files.sh . --recursive true --include-patterns "*Controller*.cs *Service*.cs"
# Write the metadata header at the top of the dump:
# ./dump_files.sh . --recursive true --extensions ".cs" --metadata-header
# Print the command instead of running it (copy/paste it to see what would be dumped):
# ./dump_files.sh . --recursive true --extensions ".cs" --exclude-dirs "obj bin" --debug-command

# -- Color helpers -------------------------------------------------------------

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'

write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }
write_dim()      { echo -e "${DARKGRAY}${1}${RESET}"; }

# Hard-coded toggle: when true, prints metadata header at top of dump file
INCLUDE_METADATA_HEADER=false
#INCLUDE_METADATA_HEADER=true

usage() {
    write_info_alt "Usage: $0 <input_dir> [output_file] [recursive: true/false] [use_full_paths: true/false] [extensions: \".ext1 .ext2 ...\"] [exclude_dirs: \"obj bin\"]"
    write_info_alt "       [--include-patterns ...] [--exclude-patterns ...] [--metadata-header] [--debug-command]"
    echo
    write_info_alt "Options:"
    write_info "  --input-dir <dir>             Input directory"
    write_info "  --output-file <file>          Output file (default: ./dumped_files.txt)"
    write_info "  --recursive true/false        Recurse into sub directories (default: false)"
    write_info "  --full-paths true/false       Full paths in the per-file headers (default: false)"
    write_info "  --extensions \"...\"            Extension filter, e.g. \".cs\" or \".cpp .h\""
    write_info "  --exclude-dirs \"...\"          Dir names to skip, e.g. \"obj bin\" (recursive only)"
    write_info "  --include-patterns \"...\"      File name globs to keep, e.g. \"*Controller*.cs\""
    write_info "  --exclude-patterns \"...\"      File name globs to skip, e.g. \"*.g.cs *.Designer.cs\""
    write_info "  --metadata-header             Write the metadata header at the top of the dump"
    write_info "  --debug-command (--show-cmd)  Print the command that would be run instead of running it"
    echo
    write_info_alt "List values accept either spaces or commas as separators."
    write_info_alt "Extension/pattern matching is case-insensitive; patterns match the file name, not the path."
    echo
    write_info_alt "Example usage:"
    write_info_alt "  Only required arg (non-recursive, file names only, output to dumped_files.txt in current dir)"
    write_info "    $0 \"\$code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl\""
    echo
    write_info_alt "  Specify output file:"
    write_info "    $0 \"\$code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders/gl\" \"/tmp/shader_dump.txt\""
    echo
    write_info_alt "  Recursive:"
    write_info "    $0 \"\$code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders\" \"/tmp/shader_dump.txt\" true"
    echo
    write_info_alt "  Recursive + full paths in headers:"
    write_info "    $0 \"\$code_root_dir/Code2/C++/space/cs/BlackholeGfx/shaders\" \"/tmp/shader_dump.txt\" true true"
    echo
    write_info_alt "  Filter by extension:"
    write_info "    $0 \"\$code_root_dir/Code2/C++/myproject\" \"/tmp/dump.txt\" true false \".cpp .h\""
    echo
    write_info_alt "  Use cwd and only .cs files:"
    write_info "    $0 . \"\" false false \".cs\""
    echo
    write_info_alt "  C++ files:"
    write_info "    $0 \"\$code_root_dir/Code2/Wow/tools/my_wow/c++/my_web_wow/src\" \"\" false false \".cpp .c .h .hpp\""
    echo
    write_info_alt "  Recursive + full paths + extension filter:"
    write_info "    $0 \"\$code_root_dir/Code2/C++/myproject\" \"/tmp/dump.txt\" true true \".cpp .h\""
    echo
    write_info_alt "  All .cs files recursively, ignoring the \"obj\" and \"bin\" dirs:"
    write_info "    $0 . --recursive true --extensions \".cs\" --exclude-dirs \"obj bin\""
    write_info "    $0 . \"\" true false \".cs\" \"obj bin\"   # same thing, positional"
    echo
    write_info_alt "  Same, but also skipping generated files:"
    write_info "    $0 . --recursive true --extensions \".cs\" --exclude-dirs \"obj bin\" --exclude-patterns \"*.g.cs *.Designer.cs\""
    echo
    write_info_alt "  Only files matching a name pattern (recursive):"
    write_info "    $0 . --recursive true --include-patterns \"*Controller*.cs *Service*.cs\""
    echo
    write_info_alt "  Skip node_modules and dist when dumping a TS project:"
    write_info "    $0 . --recursive true --extensions \".ts .tsx\" --exclude-dirs \"node_modules dist\""
    echo
    write_info_alt "  Print the command instead of running it:"
    write_info "    $0 . --recursive true --extensions \".cs\" --exclude-dirs \"obj bin\" --debug-command"
}

# Args (positionals keep their original order, each one also has a named option)
INPUT_DIR=""
OUTPUT_FILE=""
RECURSIVE="false"
USE_FULL_PATHS="false"
EXTENSIONS=""
EXCLUDE_DIRS=""
INCLUDE_PATTERNS=""
EXCLUDE_PATTERNS=""
DEBUG_COMMAND=false

# Normalise a list value: commas count as separators, same as spaces
normalize_list() {
    echo "${1//,/ }"
}

need_value() {
    if [[ -z "$2" ]]; then
        write_err "Missing argument for $1" >&2
        exit 1
    fi
}

positional=0
while [[ $# -gt 0 ]]; do
    lower="${1,,}"
    case "$lower" in
        -h|--help|-help|help|-)
            usage
            exit 0
            ;;
        --input-dir)        need_value "$1" "${2:-}"; INPUT_DIR="$2"; shift 2 ;;
        --output-file)      need_value "$1" "${2:-}"; OUTPUT_FILE="$2"; shift 2 ;;
        --recursive)        need_value "$1" "${2:-}"; RECURSIVE="$2"; shift 2 ;;
        --full-paths|--use-full-paths)
                            need_value "$1" "${2:-}"; USE_FULL_PATHS="$2"; shift 2 ;;
        --extensions)       need_value "$1" "${2:-}"; EXTENSIONS="$(normalize_list "$2")"; shift 2 ;;
        --exclude-dirs)     need_value "$1" "${2:-}"; EXCLUDE_DIRS="$(normalize_list "$2")"; shift 2 ;;
        --include-patterns) need_value "$1" "${2:-}"; INCLUDE_PATTERNS="$(normalize_list "$2")"; shift 2 ;;
        --exclude-patterns) need_value "$1" "${2:-}"; EXCLUDE_PATTERNS="$(normalize_list "$2")"; shift 2 ;;
        --metadata-header)  INCLUDE_METADATA_HEADER=true; shift ;;
        --debug-command|--show-cmd)
                            DEBUG_COMMAND=true; shift ;;
        --)
            shift
            ;;
        -*)
            write_err "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            case $positional in
                0) INPUT_DIR="$1" ;;
                1) OUTPUT_FILE="$1" ;;
                2) RECURSIVE="$1" ;;
                3) USE_FULL_PATHS="$1" ;;
                4) EXTENSIONS="$(normalize_list "$1")" ;;
                5) EXCLUDE_DIRS="$(normalize_list "$1")" ;;
                *) write_err "Unexpected extra argument: $1" >&2; exit 1 ;;
            esac
            positional=$((positional + 1))
            shift
            ;;
    esac
done

OUTPUT_FILE="${OUTPUT_FILE:-$(pwd)/dumped_files.txt}"

# Normalize booleans (accept true/1/yes)
to_bool() {
    case "${1,,}" in
        true|1|yes) echo true ;;
        *)          echo false ;;
    esac
}
RECURSIVE=$(to_bool "$RECURSIVE")
USE_FULL_PATHS=$(to_bool "$USE_FULL_PATHS")

# Validate input dir
if [[ -z "$INPUT_DIR" ]]; then
    usage >&2
    exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    write_err "Error: Input directory does not exist or is not a directory: $INPUT_DIR" >&2
    exit 1
fi

if [[ -n "$EXCLUDE_DIRS" && "$RECURSIVE" != true ]]; then
    write_warn "Note: --exclude-dirs only has an effect when --recursive is true."
fi

# Resolve to absolute path
RESOLVED_INPUT_DIR="$(cd "$INPUT_DIR" && pwd)"

# Ensure output directory exists
OUTPUT_PARENT="$(dirname "$OUTPUT_FILE")"
if [[ -z "$OUTPUT_PARENT" || "$OUTPUT_PARENT" == "." ]]; then
    OUTPUT_PARENT="$(pwd)"
    OUTPUT_FILE="${OUTPUT_PARENT}/${OUTPUT_FILE}"
elif [[ ! -d "$OUTPUT_PARENT" ]]; then
    mkdir -p "$OUTPUT_PARENT"
fi

# Normalise extensions to lowercase with leading dot (done up front so --debug-command can print them)
NORMALIZED_EXTS=""
for wanted in $EXTENSIONS; do
    wanted="${wanted,,}"
    [[ "$wanted" != .* ]] && wanted=".$wanted"
    NORMALIZED_EXTS+="${NORMALIZED_EXTS:+ }$wanted"
done

# True when any directory segment below the input dir is one of EXCLUDE_DIRS
is_in_excluded_dir() {
    local rel_dir
    rel_dir="$(dirname "${1#"${RESOLVED_INPUT_DIR}"/}")"
    [[ "$rel_dir" == "." ]] && return 1

    local segment wanted
    local IFS='/'
    for segment in $rel_dir; do
        local IFS=$' \t\n'
        for wanted in $EXCLUDE_DIRS; do
            [[ "${segment,,}" == "${wanted,,}" ]] && return 0
        done
    done
    return 1
}

# True when the file name matches one of the given globs (case-insensitive, like PowerShell -like)
name_matches_any() {
    local name="$1"
    local patterns="$2"
    local pattern
    local matched=1
    shopt -s nocasematch
    for pattern in $patterns; do
        if [[ "$name" == $pattern ]]; then
            matched=0
            break
        fi
    done
    shopt -u nocasematch
    return $matched
}

# Debug: print the command(s) instead of running anything
if [[ "$DEBUG_COMMAND" == true ]]; then
    write_info_alt "[debug] Resolved options:"
    write_info "  InputDir:        $RESOLVED_INPUT_DIR"
    write_info "  OutputFile:      $OUTPUT_FILE"
    write_info "  Recursive:       $RECURSIVE"
    write_info "  UseFullPaths:    $USE_FULL_PATHS"
    write_info "  Extensions:      ${NORMALIZED_EXTS:-<all>}"
    write_info "  ExcludeDirs:     ${EXCLUDE_DIRS:-<none>}"
    write_info "  IncludePatterns: ${INCLUDE_PATTERNS:-<none>}"
    write_info "  ExcludePatterns: ${EXCLUDE_PATTERNS:-<none>}"
    write_info "  MetadataHeader:  $INCLUDE_METADATA_HEADER"
    echo

    # The file collection command, printed so it can be pasted straight into a terminal
    collection_command="find '$RESOLVED_INPUT_DIR'"
    [[ "$RECURSIVE" != true ]] && collection_command+=" -maxdepth 1"
    for wanted in $EXCLUDE_DIRS; do
        collection_command+=" -type d -iname '$wanted' -prune -o"
    done
    collection_command+=" -type f"
    if [[ -n "$NORMALIZED_EXTS" ]]; then
        ext_clause=""
        for wanted in $NORMALIZED_EXTS; do
            ext_clause+="${ext_clause:+ -o }-iname '*$wanted'"
        done
        collection_command+=" \\( $ext_clause \\)"
    fi
    if [[ -n "$INCLUDE_PATTERNS" ]]; then
        inc_clause=""
        for pattern in $INCLUDE_PATTERNS; do
            inc_clause+="${inc_clause:+ -o }-iname '$pattern'"
        done
        collection_command+=" \\( $inc_clause \\)"
    fi
    for pattern in $EXCLUDE_PATTERNS; do
        collection_command+=" ! -iname '$pattern'"
    done
    collection_command+=" -print | sort"
    write_info_alt "[debug] File collection command (lists the files that would be dumped):"
    write_dim "  $collection_command"
    echo

    # The same run, expressed as a single self-contained invocation of this script
    invocation_command="$0 '$RESOLVED_INPUT_DIR' '$OUTPUT_FILE' $RECURSIVE $USE_FULL_PATHS"
    [[ -n "$EXTENSIONS" ]]       && invocation_command+=" --extensions '$EXTENSIONS'"
    [[ -n "$EXCLUDE_DIRS" ]]     && invocation_command+=" --exclude-dirs '$EXCLUDE_DIRS'"
    [[ -n "$INCLUDE_PATTERNS" ]] && invocation_command+=" --include-patterns '$INCLUDE_PATTERNS'"
    [[ -n "$EXCLUDE_PATTERNS" ]] && invocation_command+=" --exclude-patterns '$EXCLUDE_PATTERNS'"
    [[ "$INCLUDE_METADATA_HEADER" == true ]] && invocation_command+=" --metadata-header"
    write_info_alt "[debug] Equivalent invocation (writes the dump):"
    write_dim "  $invocation_command"
    exit 0
fi

# Collect files
if [[ "$RECURSIVE" == true ]]; then
    mapfile -d '' files < <(find "$RESOLVED_INPUT_DIR" -type f -print0 | sort -z)
else
    mapfile -d '' files < <(find "$RESOLVED_INPUT_DIR" -maxdepth 1 -type f -print0 | sort -z)
fi

# Skip anything living under one of the excluded dir names
if [[ -n "$EXCLUDE_DIRS" ]]; then
    filtered=()
    for file in "${files[@]}"; do
        is_in_excluded_dir "$file" || filtered+=("$file")
    done
    files=("${filtered[@]}")
fi

# Filter by extension if specified (normalise to lowercase with leading dot)
if [[ -n "$NORMALIZED_EXTS" ]]; then
    filtered=()
    for file in "${files[@]}"; do
        ext=".${file##*.}"
        ext="${ext,,}"
        for wanted in $NORMALIZED_EXTS; do
            if [[ "$ext" == "$wanted" ]]; then
                filtered+=("$file")
                break
            fi
        done
    done
    files=("${filtered[@]}")
fi

# Keep only files whose name matches one of the include patterns
if [[ -n "$INCLUDE_PATTERNS" ]]; then
    filtered=()
    for file in "${files[@]}"; do
        name_matches_any "$(basename "$file")" "$INCLUDE_PATTERNS" && filtered+=("$file")
    done
    files=("${filtered[@]}")
fi

# Skip files whose name matches any of the exclude patterns
if [[ -n "$EXCLUDE_PATTERNS" ]]; then
    filtered=()
    for file in "${files[@]}"; do
        name_matches_any "$(basename "$file")" "$EXCLUDE_PATTERNS" || filtered+=("$file")
    done
    files=("${filtered[@]}")
fi

# Build output
{
    # Optional metadata header
    if [[ "$INCLUDE_METADATA_HEADER" == true ]]; then
        echo "Dump generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "InputDir: $RESOLVED_INPUT_DIR"
        echo "Recursive: $RECURSIVE"
        echo "UseFullPaths: $USE_FULL_PATHS"
        echo "ExcludeDirs: ${EXCLUDE_DIRS:-<none>}"
        echo "IncludePatterns: ${INCLUDE_PATTERNS:-<none>}"
        echo "ExcludePatterns: ${EXCLUDE_PATTERNS:-<none>}"
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

if [[ ${#files[@]} -eq 0 ]]; then
    write_warn "No files matched the given filters. Wrote empty dump to: $OUTPUT_FILE"
else
    write_ok "Dumped ${#files[@]} file(s) to: $OUTPUT_FILE"
fi
