#!/usr/bin/env bash

# Usage:
# ./cmake.sh            # detect path and RUN the chosen cmake
# ./cmake.sh onlyprint  # detect path and PRINT commands (no execution)
# ./cmake.sh r/release  # RUN in Release mode
# ./cmake.sh r foo      # RUN in Release mode and PRINT commands (no execution)
# ./cmake.sh rd         # RUN in RelWithDebInfo mode
# ./cmake.sh rwdi foo   # RUN in RelWithDebInfo mode and PRINT commands
#
# Project definitions live in $my_notes_path/scripts/cmake-projects.json
# (shared with cmake.ps1). Requires `jq` to be installed.

# Use OnlyPrint if any arg is provided
#OnlyPrint="${1:-}"

# Use OnlyPrint if any arg is provided EXCEPT r/release
Arg="${1:-}"
arg_lc="${Arg,,}"

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'
DARKYELLOW='\033[93m'

# Help check (case-insensitive)
help_tokens=("h" "help" "-h" "--help")
for token in "${help_tokens[@]}"; do
    if [[ "${1,,}" == "$token" || "${2,,}" == "$token" ]]; then
        cat <<EOF
cmake.sh - context-aware cmake helper

Usage:
  ./cmake.sh
      Detect path and RUN the chosen cmake command.

  ./cmake.sh onlyprint
      Detect path and PRINT commands (no execution).

  ./cmake.sh r | release
      Run in Release mode.

  ./cmake.sh r foo
      Release mode + PRINT-ONLY (because a second arg exists).

  ./cmake.sh rd | rwdi | relwithdebinfo
      Run in RelWithDebInfo mode.

  ./cmake.sh h | help | -h | --help
      Show this help.

Notes:
  - BuildType defaults to Debug unless you pass r/release.
  - Project definitions live in:
      \${my_notes_path:-<unset>}/scripts/cmake-projects.json
  - Requires \`jq\`.
EOF
        exit 0
    fi
done

# Print-only unless argument is "r" or "release" (case-insensitive)
OnlyPrint=""
Release=""
RelWithDebInfo=""
if [[ -n "$Arg" ]]; then
    if [[ "$arg_lc" == "r" || "$arg_lc" == "release" ]]; then
        Release=1
        [[ -n "${2:-}" ]] && OnlyPrint=1
    elif [[ "$arg_lc" == "rwdi" || "$arg_lc" == "rd" || "$arg_lc" == "relwithdebinfo" ]]; then
        RelWithDebInfo=1
        [[ -n "${2:-}" ]] && OnlyPrint=1
    else
        OnlyPrint=1
    fi

    printf "%bIf needed, run:%b\n" "$BLUE" "$RESET"
    printf "%bmake -j\$(nproc)%b\n" "$BLUE" "$RESET"
    echo
fi

# build type helper
BuildType="Debug"
[[ -n "$Release" ]] && BuildType="Release"
[[ -n "$RelWithDebInfo" ]] && BuildType="RelWithDebInfo"

# Debug print (PowerShell-style)
if [[ -n "$OnlyPrint" ]]; then
    printf "%b[OnlyPrint]=ON  [BuildType]=%s%b\n\n" "$MAGENTA" "$BuildType" "$RESET"
else
    printf "%b[OnlyPrint]=OFF  [BuildType]=%s%b\n\n" "$MAGENTA" "$BuildType" "$RESET"
fi

# get current working dir
cwd="$(pwd)"
lc="${cwd,,}" # lowercase for case-insensitive checks

run_or_print() {
    local cmd="$1"
    if [[ -n "$OnlyPrint" ]]; then
        printf "%b%s%b\n" "$CYAN" "$cmd" "$RESET"
    else
        printf "%bExecuting: %s%b\n" "$CYAN" "$cmd" "$RESET"
        eval "$cmd"
    fi
}

print_alternatives() {
    if [[ -n "$OnlyPrint" && $# -gt 0 ]]; then
        echo
        echo "alternative cmake commands:"
        for l in "$@"; do
            echo "$l"
            echo
        done
    fi
}

test_cmakelists() {
    local where="${1:-current}"
    local context="${2:-this project}"
    local base="$cwd"
    [[ "$where" == "parent" ]] && base="$(dirname "$cwd")"

    local cmake_path="$base/CMakeLists.txt"
    if [[ -f "$cmake_path" ]]; then
        return 0
    fi

    printf "%bCMakeLists.txt not found at: %s - %s%b\n" "$DARKYELLOW" "$cmake_path" "$context" "$RESET"

    if [[ "$where" == "parent" ]]; then
        printf "%bMaybe try:%b\n" "$DARKYELLOW" "$RESET"
        printf "%b-> mkdir build && cd build%b\n" "$DARKYELLOW" "$RESET"
        printf "%bThen run the command again!%b\n" "$DARKYELLOW" "$RESET"
    fi

    #echo "Switching to PRINT-ONLY mode." >&2
    #echo >&2
    printf "%bSwitching to PRINT-ONLY mode.%b\n" "$DARKYELLOW" "$RESET"
    echo

    OnlyPrint=1
    return 1
}

# --- JSON-driven dispatch (parallels cmake.ps1) ---

# Detect platform so the shared JSON can be filtered.
detect_platform() {
    case "$(uname -s 2>/dev/null)" in
        Linux*|Darwin*)        echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*)  echo "windows" ;;
        *)                     echo "linux" ;;
    esac
}
PLATFORM="$(detect_platform)"

# vcpkg path detection (Windows-relevant; on Linux these paths almost always
# don't exist so VCPKG ends up empty -- which is fine, the JSON gates vcpkg
# blocks with platform=windows anyway).
get_vcpkg_path() {
    local primary="${code_root_dir:-}/C++/diablo_devilutionX/vcpkg/scripts/buildsystems/vcpkg.cmake"
    local secondary='C:/local/bin/vcpkg/scripts/buildsystems/vcpkg.cmake'
    if [[ -n "${code_root_dir:-}" && -f "$primary" ]]; then
        echo "$primary"
    elif [[ -f "$secondary" ]]; then
        echo "$secondary"
    fi
}

# Substitute {BuildType}, {VCPKG}, {BASE}, {NPROC} tokens.
expand_tokens() {
    local out="$1"
    out="${out//\{BuildType\}/$BuildType}"
    out="${out//\{VCPKG\}/$VCPKG}"
    out="${out//\{BASE\}/$BASE}"
    out="${out//\{NPROC\}/$NPROC}"
    printf '%s' "$out"
}

# Map PowerShell color names (as used in the JSON) to ANSI codes.
color_for() {
    case "$1" in
        Black)        printf '\033[30m' ;;
        DarkBlue)     printf '\033[34m' ;;
        DarkGreen)    printf '\033[32m' ;;
        DarkCyan)     printf '\033[36m' ;;
        DarkRed)      printf '\033[31m' ;;
        DarkMagenta)  printf '\033[35m' ;;
        DarkYellow)   printf '\033[33m' ;;
        Gray)         printf '\033[37m' ;;
        DarkGray)     printf '\033[90m' ;;
        Blue)         printf '\033[94m' ;;
        Green)        printf '\033[92m' ;;
        Cyan)         printf '\033[96m' ;;
        Red)          printf '\033[91m' ;;
        Magenta)      printf '\033[95m' ;;
        Yellow)       printf '\033[93m' ;;
        White)        printf '\033[97m' ;;
        *)            ;;
    esac
}

write_colored() {
    local text="$1"
    local color_name="${2:-}"
    if [[ -n "$color_name" ]]; then
        local code
        code="$(color_for "$color_name")"
        if [[ -n "$code" ]]; then
            printf '%b%s%b\n' "$code" "$text" "$RESET"
            return
        fi
    fi
    echo "$text"
}

# Predicates referenced by instructions[].if
check_condition() {
    case "$1" in
        linux_debian_or_ubuntu)
            grep -qiE 'debian|ubuntu' /etc/os-release 2>/dev/null
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# Default fallback when no project matched or the JSON isn't usable.
run_default_fallback() {
    test_cmakelists parent "$(basename "$cwd")"
    printf "%bNo cmake command found for: %s%b\n" "$DARKYELLOW" "$cwd" "$RESET"
    printf "%bUsing default cmake command...%b\n" "$DARKYELLOW" "$RESET"
    run_or_print "cmake ../ -DCMAKE_BUILD_TYPE=$BuildType"
}

# Locate and load the JSON. Bail out to default fallback if anything is missing.
JSON_PATH=""
[[ -n "${my_notes_path:-}" ]] && JSON_PATH="${my_notes_path}/scripts/cmake-projects.json"

if ! command -v jq >/dev/null 2>&1; then
    printf "%bWarning: jq is required to read cmake-projects.json. Falling back.%b\n" "$YELLOW" "$RESET"
    run_default_fallback
    exit 0
fi

if [[ -z "$JSON_PATH" || ! -f "$JSON_PATH" ]]; then
    printf "%bWarning: cmake-projects.json not found at: %s%b\n" "$YELLOW" "${JSON_PATH:-<\$my_notes_path unset>}" "$RESET"
    run_default_fallback
    exit 0
fi

JSON_CONTENT="$(cat "$JSON_PATH")"

# Find the first project whose match (and optional platform) applies to $lc.
matched_idx="$(jq -r --arg cwd "$lc" --arg plat "$PLATFORM" '
    def project_matches($c; $p):
        ((.platform // "any") as $pp | ($pp == "any" or $pp == $p)) and
        (.match as $m
         | (($m.all // []) | length > 0) as $ha
         | (($m.any // []) | length > 0) as $hy
         | ($ha or $hy)
         and (if $ha then ($m.all | all(. as $n | $c | contains($n | ascii_downcase))) else true end)
         and (if $hy then ($m.any | any(. as $n | $c | contains($n | ascii_downcase))) else true end));
    .projects | to_entries
    | map(select(.value | project_matches($cwd; $plat)))
    | (.[0].key // -1)
' <<<"$JSON_CONTENT")"

if [[ -z "$matched_idx" || "$matched_idx" == "-1" ]]; then
    run_default_fallback
    exit 0
fi

# Tiny helper: jq query relative to the matched project.
P=".projects[$matched_idx]"
jp() { jq -r "$1" <<<"$JSON_CONTENT"; }

# cmakelists check
cmlc="$(jp "$P.cmakelists_check // empty")"
ctx="$(jp "$P.context // empty")"
case "$cmlc" in
    parent)  test_cmakelists parent  "$ctx" ;;
    current) test_cmakelists current "$ctx" ;;
esac

# Compute tokens
VCPKG="$(get_vcpkg_path)"
NPROC="$(nproc 2>/dev/null || echo 4)"
BASE=""
base_flags_raw="$(jp "$P.base_flags // empty")"
[[ -n "$base_flags_raw" ]] && BASE="$(expand_tokens "$base_flags_raw")"

# pre_main_vcpkg block (Windows-tagged in the JSON for projects that use it)
if [[ "$(jp "$P | has(\"pre_main_vcpkg\")")" == "true" ]]; then
    pre_plat="$(jp "$P.pre_main_vcpkg.platform // \"any\"")"
    if [[ "$pre_plat" == "any" || "$pre_plat" == "$PLATFORM" ]]; then
        echo
        header="$(jp "$P.pre_main_vcpkg.header // empty")"
        hcolor="$(jp "$P.pre_main_vcpkg.header_color // empty")"
        [[ -n "$header" ]] && write_colored "$header" "$hcolor"
        cmd_tpl="$(jp "$P.pre_main_vcpkg.command_template // empty")"
        ccolor="$(jp "$P.pre_main_vcpkg.command_color // empty")"
        if [[ -n "$VCPKG" ]]; then
            write_colored "$(expand_tokens "$cmd_tpl")" "$ccolor"
        else
            miss="$(jp "$P.pre_main_vcpkg.missing_text // \"(no vcpkg toolchain found at expected paths)\"")"
            write_colored "$miss" "$ccolor"
        fi
        echo
    fi
fi

# pre_main_text array (simple platform-tagged colored notes)
pmt_count="$(jp "$P.pre_main_text // [] | length")"
for ((i=0; i<pmt_count; i++)); do
    plat="$(jp "$P.pre_main_text[$i].platform // \"any\"")"
    [[ "$plat" != "any" && "$plat" != "$PLATFORM" ]] && continue
    text="$(jp "$P.pre_main_text[$i].text // empty")"
    color="$(jp "$P.pre_main_text[$i].color // empty")"
    echo
    write_colored "$(expand_tokens "$text")" "$color"
    echo
done

# instructions short-circuit main (used by neovim)
if [[ "$(jp "$P | has(\"instructions\")")" == "true" ]]; then
    instr_count="$(jp "$P.instructions | length")"
    for ((i=0; i<instr_count; i++)); do
        itype="$(jp "$P.instructions[$i] | type")"
        if [[ "$itype" == "string" ]]; then
            echo "$(expand_tokens "$(jp "$P.instructions[$i]")")"
        else
            plat="$(jp "$P.instructions[$i].platform // \"any\"")"
            [[ "$plat" != "any" && "$plat" != "$PLATFORM" ]] && continue
            if_cond="$(jp "$P.instructions[$i].if // empty")"
            if [[ -n "$if_cond" ]] && ! check_condition "$if_cond"; then
                continue
            fi
            txt="$(jp "$P.instructions[$i].text // empty")"
            echo "$(expand_tokens "$txt")"
        fi
    done
    exit 0
fi

# main (with platform override)
main_for_plat="$(jp "$P.main_${PLATFORM} // empty")"
if [[ -n "$main_for_plat" ]]; then
    main_cmd="$main_for_plat"
else
    main_cmd="$(jp "$P.main // empty")"
fi
[[ -n "$main_cmd" ]] && run_or_print "$(expand_tokens "$main_cmd")"

# alternatives (items may be strings OR {platform, command} objects)
alts_count="$(jp "$P.alternatives // [] | length")"
if (( alts_count > 0 )); then
    alts_arr=()
    for ((i=0; i<alts_count; i++)); do
        itype="$(jp "$P.alternatives[$i] | type")"
        if [[ "$itype" == "string" ]]; then
            alts_arr+=( "$(expand_tokens "$(jp "$P.alternatives[$i]")")" )
        else
            plat="$(jp "$P.alternatives[$i].platform // \"any\"")"
            [[ "$plat" != "any" && "$plat" != "$PLATFORM" ]] && continue
            cmd="$(jp "$P.alternatives[$i].command // empty")"
            alts_arr+=( "$(expand_tokens "$cmd")" )
        fi
    done
    (( ${#alts_arr[@]} > 0 )) && print_alternatives "${alts_arr[@]}"
fi

# extras (OnlyPrint mode only)
if [[ -n "$OnlyPrint" ]]; then
    extras_count="$(jp "$P.extras // [] | length")"
    for ((i=0; i<extras_count; i++)); do
        plat="$(jp "$P.extras[$i].platform // \"any\"")"
        [[ "$plat" != "any" && "$plat" != "$PLATFORM" ]] && continue
        etype="$(jp "$P.extras[$i].type // empty")"
        case "$etype" in
            blank)
                echo
                ;;
            text)
                t="$(jp "$P.extras[$i].text // empty")"
                echo "$(expand_tokens "$t")"
                ;;
            label_then_command)
                label="$(jp "$P.extras[$i].label // empty")"
                cmd="$(jp "$P.extras[$i].command // empty")"
                [[ -n "$label" ]] && echo "$label"
                echo "$(expand_tokens "$cmd")"
                ;;
            label_then_vcpkg_command)
                label="$(jp "$P.extras[$i].label // empty")"
                cmd="$(jp "$P.extras[$i].command // empty")"
                fb="$(jp "$P.extras[$i].fallback_command // empty")"
                [[ -n "$label" ]] && echo "$label"
                if [[ -n "$VCPKG" ]]; then
                    echo "$(expand_tokens "$cmd")"
                else
                    echo "(no vcpkg toolchain found at expected paths)"
                    [[ -n "$fb" ]] && echo "$(expand_tokens "$fb")"
                fi
                ;;
        esac
    done
fi

# variants_print_only (used by my_web_wow c++)
if [[ -n "$OnlyPrint" && -n "$BASE" ]] && [[ "$(jp "$P | has(\"variants_print_only\")")" == "true" ]]; then
    pfx_tpl="$(jp "$P.variants_print_only.prefix // empty")"
    vprefix="$(expand_tokens "$pfx_tpl")"
    var_count="$(jp "$P.variants_print_only.items | length")"
    for ((i=0; i<var_count; i++)); do
        label="$(jp "$P.variants_print_only.items[$i].label")"
        vbase="$BASE"
        rep_count="$(jp "$P.variants_print_only.items[$i].replace | length")"
        for ((j=0; j<rep_count; j++)); do
            s="$(jp "$P.variants_print_only.items[$i].replace[$j][0]")"
            r="$(jp "$P.variants_print_only.items[$i].replace[$j][1]")"
            vbase="${vbase//$s/$r}"
        done
        echo
        echo "${label}:"
        echo "${vprefix}${vbase}"
    done
fi
