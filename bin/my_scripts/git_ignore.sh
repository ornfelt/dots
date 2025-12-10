#!/usr/bin/env bash

# Usage:
#./copy-gitignore.sh <language>

set -u  # Treat unset variables as an error

# Color definitions
COLOR_CYAN='\e[36m'
COLOR_MAGENTA='\e[35m'
COLOR_GREEN='\e[32m'
COLOR_YELLOW='\e[33m'   # "DarkYellow" equivalent
COLOR_RED='\e[31m'
COLOR_RESET='\e[0m'

# Usage
show_usage() {
    echo -e "${COLOR_CYAN}Usage: ./copy-gitignore.sh <language>${COLOR_RESET}"
    echo
    echo "Available code language arguments (case-insensitive):"

    langs=(
        'c'
        'cs / c# / csharp'
        'cpp / c++'
        'go / golang'
        'java'
        'js / javascript'
        'ts / typescript'
        'py / python'
        'rust / rs'
    )

    for lang in "${langs[@]}"; do
        echo -e "  ${COLOR_MAGENTA}${lang}${COLOR_RESET}"
    done
}

# Language alias -> normalized map
declare -A LANGUAGE_MAP=(
    ["c"]="c"
    ["cs"]="csharp"
    ["c#"]="csharp"
    ["csharp"]="csharp"
    ["cpp"]="cpp"
    ["c++"]="cpp"
    ["go"]="go"
    ["golang"]="go"
    ["java"]="java"
    ["js"]="javascript"
    ["javascript"]="javascript"
    ["ts"]="typescript"
    ["typescript"]="typescript"
    ["py"]="python"
    ["python"]="python"
    ["rust"]="rust"
    ["rs"]="rust"
)

# Normalized language -> relative .gitignore path
declare -A GITIGNORE_MAP=(
    ["c"]="Code2/General/utils/cfg/c/.gitignore"
    ["cpp"]="Code2/General/utils/cfg/cpp/.gitignore"
    ["csharp"]="Code2/General/utils/cfg/cs/Cfg/.gitignore"
    ["go"]="Code2/General/utils/cfg/go/.gitignore"
    ["java"]="Code2/General/utils/cfg/java/cfg/.gitignore"
    ["javascript"]="Code2/General/utils/cfg/js/.gitignore"
    ["python"]="Code2/General/utils/cfg/py/.gitignore"
    ["rust"]="Code2/General/utils/cfg/rust/cfg/.gitignore"
    ["typescript"]="Code2/General/utils/cfg/ts/.gitignore"
)

# Helper: trim (simple)
trim() {
    # Trim leading/trailing whitespace from $1
    local var="$1"
    # remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Main logic

# If no argument: show usage/help and exit 0
if [[ $# -lt 1 ]]; then
    show_usage
    exit 0
fi

raw_language="$1"
# Trim & lowercase (similar to PowerShell's .Trim().ToLower())
key=$(trim "$raw_language")
key="${key,,}"   # bash lowercase

# Validate language alias
if [[ -z "${LANGUAGE_MAP[$key]+_}" ]]; then
    echo -e "${COLOR_RED}Unknown code language argument: '$raw_language'${COLOR_RESET}"
    echo
    show_usage
    exit 1
fi

normalized_language="${LANGUAGE_MAP[$key]}"

echo -n "Selected code language: "
echo -e "${COLOR_MAGENTA}${normalized_language}${COLOR_RESET}"

# Ensure env var exists
code_root="${code_root_dir-}"
if [[ -z "$code_root" ]]; then
    echo -e "${COLOR_YELLOW}Environment variable 'code_root_dir' is not set. Cannot resolve .gitignore source path.${COLOR_RESET}"
    exit 1
fi

# Check mapping for normalized language
if [[ -z "${GITIGNORE_MAP[$normalized_language]+_}" ]]; then
    echo -e "${COLOR_YELLOW}No .gitignore mapping defined for normalized language '${normalized_language}'.${COLOR_RESET}"
    exit 1
fi

relative_path="${GITIGNORE_MAP[$normalized_language]}"
source_path="${code_root%/}/$relative_path"   # avoid double slash

# Check that the source .gitignore exists
if [[ ! -f "$source_path" ]]; then
    echo -e "${COLOR_YELLOW}Source .gitignore not found for '${normalized_language}' at:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}${source_path}${COLOR_RESET}"
    exit 1
fi

# Destination: .gitignore in current directory
dest_path="$PWD/.gitignore"

if [[ -e "$dest_path" ]]; then
    echo -e "${COLOR_YELLOW}A .gitignore already exists in the current directory:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}${dest_path}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Nothing was copied.${COLOR_RESET}"
    exit 1
fi

# Copy and handle errors
if cp -- "$source_path" "$dest_path"; then
    echo -e "${COLOR_GREEN}Copied .gitignore for '${normalized_language}' to current directory:${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}Source: ${source_path}${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}Dest:   ${dest_path}${COLOR_RESET}"
else
    echo -e "${COLOR_RED}Failed to copy .gitignore.${COLOR_RESET}"
    exit 1
fi

