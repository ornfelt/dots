#!/usr/bin/env bash
# cmake.sh - data-driven cmake helper (Linux).
#
# Reads patterns from:  $my_notes_path/scripts/cmake_patterns.json
# (the same file used by cmake.ps1).
#
# Usage:
#   ./cmake.sh                        detect path and RUN the chosen cmake
#   ./cmake.sh onlyprint              detect path and PRINT commands only
#   ./cmake.sh r | release            RUN in Release mode
#   ./cmake.sh r foo                  Release + PRINT-ONLY (any 2nd arg flips)
#   ./cmake.sh rd | rwdi              RUN in RelWithDebInfo mode
#   ./cmake.sh h | help | -h | --help show help
#
# Linux-only assumption: vcpkg is always OFF, so the vcpkg alternative
# from cmake_patterns.json is skipped entirely.

set -u

# ---------- args ----------
Arg="${1:-}"
Arg2="${2:-}"
arg_lc="${Arg,,}"
arg2_lc="${Arg2,,}"

# ---------- colors ----------
RESET='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'
DARKYELLOW='\033[93m'

# ---------- help ----------
for token in h help -h --help; do
    if [[ "$arg_lc" == "$token" || "$arg2_lc" == "$token" ]]; then
        cat <<'EOF'
cmake.sh - data-driven cmake helper (Linux)

Usage:
  ./cmake.sh
      Detect path, pick a pattern, RUN cmake.
  ./cmake.sh onlyprint
      Detect path, pick a pattern, PRINT commands only.
  ./cmake.sh r | release [foo]
      Release mode (PRINT-ONLY if a 2nd arg exists).
  ./cmake.sh rd | rwdi | relwithdebinfo [foo]
      RelWithDebInfo mode (PRINT-ONLY if a 2nd arg exists).
  ./cmake.sh h | help | -h | --help
      Show this help.

Notes:
  - Patterns loaded from $my_notes_path/scripts/cmake_patterns.json
  - BuildType defaults to Debug.
  - cmake prefix is auto-detected:
        ./CMakeLists.txt   -> 'cmake -B build -S . ...'
        ../CMakeLists.txt  -> 'cmake .. ...'
        neither            -> warn + force PRINT-ONLY
  - vcpkg is assumed OFF on Linux; vcpkg alternative is skipped.
  - Requires: jq.
EOF
        exit 0
    fi
done

# ---------- deps ----------
if ! command -v jq >/dev/null 2>&1; then
    printf "%bjq is required to parse cmake_patterns.json. Install jq (e.g. 'sudo apt install jq').%b\n" "$RED" "$RESET" >&2
    exit 1
fi

# ---------- arg parsing (mirror cmake.ps1) ----------
OnlyPrint=""
Release=""
RelWithDebInfo=""
if [[ -n "$Arg" ]]; then
    if [[ "$arg_lc" == "r" || "$arg_lc" == "release" ]]; then
        Release=1
        [[ -n "$Arg2" ]] && OnlyPrint=1
    elif [[ "$arg_lc" == "rd" || "$arg_lc" == "rwdi" || "$arg_lc" == "relwithdebinfo" ]]; then
        RelWithDebInfo=1
        [[ -n "$Arg2" ]] && OnlyPrint=1
    else
        OnlyPrint=1
    fi
    printf "%bIf needed, run:%b\n" "$BLUE" "$RESET"
    printf "%bmake -j\$(nproc)%b\n" "$BLUE" "$RESET"
    echo
fi

BuildType="Debug"
[[ -n "$Release" ]]        && BuildType="Release"
[[ -n "$RelWithDebInfo" ]] && BuildType="RelWithDebInfo"

if [[ -n "$OnlyPrint" ]]; then
    printf "%b[OnlyPrint]=ON  [BuildType]=%s%b\n\n" "$MAGENTA" "$BuildType" "$RESET"
else
    printf "%b[OnlyPrint]=OFF  [BuildType]=%s%b\n\n" "$MAGENTA" "$BuildType" "$RESET"
fi

# ---------- locate patterns file ----------
notes_path="${my_notes_path:-}"
if [[ -z "$notes_path" ]]; then
    notes_path="$(dirname "$(readlink -f "$0")")"
    printf "%bWarning: \$my_notes_path is not set. Falling back to: %s%b\n" "$YELLOW" "$notes_path" "$RESET"
fi
patterns_file="$notes_path/scripts/cmake_patterns.json"

if [[ ! -f "$patterns_file" ]]; then
    printf "%bPatterns file not found: %s%b\n" "$RED" "$patterns_file" "$RESET" >&2
    exit 1
fi

if ! jq -e . "$patterns_file" >/dev/null 2>&1; then
    printf "%bFailed to parse JSON: %s%b\n" "$RED" "$patterns_file" "$RESET" >&2
    exit 1
fi

# ---------- cwd & matching ----------
cwd="$(pwd)"
cwd="${cwd,,}"  # lowercased for case-insensitive substring matching

# Check that keywords appear in $cwd in the given order (case-insensitive).
# $cwd is already lowercased, so we only lower-case the keywords.
path_contains_in_order() {
    local pos=0
    local kw kw_lower sub prefix
    for kw in "$@"; do
        kw_lower="${kw,,}"
        sub="${cwd:$pos}"
        if [[ "$sub" != *"$kw_lower"* ]]; then
            return 1
        fi
        prefix="${sub%%"$kw_lower"*}"
        pos=$((pos + ${#prefix} + ${#kw_lower}))
    done
    return 0
}

# Match a pattern's `keywords` field against $cwd.
# keywords is either ["a","b",...] (single group, all must match in order)
# or [["a","b"],["c","d"]] (multi-group: any group may match).
pattern_matches() {
    local pattern_json="$1"
    local kind
    kind=$(jq -r '
        .keywords as $k
        | if ($k | type) != "array" or ($k | length) == 0 then "empty"
          elif ($k[0] | type) == "string" then "single"
          else "multi"
          end
    ' <<<"$pattern_json")
    case "$kind" in
        single)
            local -a kws=()
            mapfile -t kws < <(jq -r '.keywords[]' <<<"$pattern_json")
            path_contains_in_order "${kws[@]}"
            ;;
        multi)
            local groups
            groups=$(jq -r '.keywords | length' <<<"$pattern_json")
            local i
            for ((i = 0; i < groups; i++)); do
                local -a kws=()
                mapfile -t kws < <(jq -r --argjson i "$i" '.keywords[$i][]' <<<"$pattern_json")
                if path_contains_in_order "${kws[@]}"; then
                    return 0
                fi
            done
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# ---------- cmake prefix auto-detection ----------
CMAKE_PREFIX=""

ensure_cmake_detected() {
    local ctx="${1:-this project}"
    if [[ -f "./CMakeLists.txt" ]]; then
        CMAKE_PREFIX="cmake -B build -S ."
        printf "%bAlternative: mkdir build && cd build%b\n" "$DARKGRAY" "$RESET"
    elif [[ -f "../CMakeLists.txt" ]]; then
        CMAKE_PREFIX="cmake .."
    else
        printf "%bCMakeLists.txt not found in current or parent directory - %s%b\n" "$DARKYELLOW" "$ctx" "$RESET"
        printf "%bMaybe try:%b\n" "$DARKYELLOW" "$RESET"
        printf "%b-> mkdir build && cd build%b\n" "$DARKYELLOW" "$RESET"
        printf "%bThen run the command again.%b\n" "$DARKYELLOW" "$RESET"
        printf "%bSwitching to PRINT-ONLY mode.%b\n" "$DARKYELLOW" "$RESET"
        echo
        OnlyPrint=1
        CMAKE_PREFIX="cmake .."  # best-effort fallback for the printed text
    fi
}

# ---------- substitution / formatting ----------
# @BuildType -> $BuildType, {NPROC} -> $(nproc)
substitute_tokens() {
    local s="$1"
    s="${s//@BuildType/$BuildType}"
    s="${s//\{NPROC\}/$(nproc)}"
    printf '%s' "$s"
}

# Build "-Dk=v -Dk=v ..." from base_flags (and optionally a variant's toggles).
# Order: base order preserved, toggles override matching keys, new keys appended.
flags_string() {
    local pattern_json="$1"
    local variant_idx="${2:-}"
    local raw
    if [[ -z "$variant_idx" ]]; then
        raw=$(jq -r '
            (.base_flags // {})
            | to_entries
            | map("-D\(.key)=\(.value)")
            | join(" ")
        ' <<<"$pattern_json")
    else
        raw=$(jq -r --argjson i "$variant_idx" '
            ((.base_flags // {}) + ((.variants[$i].toggles) // {}))
            | to_entries
            | map("-D\(.key)=\(.value)")
            | join(" ")
        ' <<<"$pattern_json")
    fi
    substitute_tokens "$raw"
}

run_or_print() {
    local cmd="$1"
    if [[ -n "$OnlyPrint" ]]; then
        printf "%b%s%b\n" "$CYAN" "$cmd" "$RESET"
    else
        printf "%bExecuting: %s%b\n" "$CYAN" "$cmd" "$RESET"
        eval "$cmd"
    fi
}

print_only_print_extras() {
    local pattern_json="$1"
    [[ -z "$OnlyPrint" ]] && return
    local count
    count=$(jq -r '(.only_print_extras // []) | length' <<<"$pattern_json")
    [[ "$count" -eq 0 ]] && return

    local i
    for ((i = 0; i < count; i++)); do
        echo
        local label cmd lcount
        label=$(jq -r --argjson i "$i" '.only_print_extras[$i].label // ""' <<<"$pattern_json")
        cmd=$(jq   -r --argjson i "$i" '.only_print_extras[$i].command // ""' <<<"$pattern_json")
        lcount=$(jq -r --argjson i "$i" '(.only_print_extras[$i].lines // []) | length' <<<"$pattern_json")

        [[ -n "$label" ]] && echo "$label"
        [[ -n "$cmd"   ]] && substitute_tokens "$cmd" && echo
        if [[ "$lcount" -gt 0 ]]; then
            local j
            for ((j = 0; j < lcount; j++)); do
                local ln
                ln=$(jq -r --argjson i "$i" --argjson j "$j" '.only_print_extras[$i].lines[$j]' <<<"$pattern_json")
                substitute_tokens "$ln"; echo
            done
        fi
    done
}

# ---------- pattern dispatch ----------
dispatch_pattern() {
    local pattern_json="$1"
    local ctx
    ctx=$(jq -r '.context_name // "pattern"' <<<"$pattern_json")

    # 1) instructions-only entries (e.g. neovim)
    local ins_count
    ins_count=$(jq -r '(.instructions // []) | length' <<<"$pattern_json")
    if [[ "$ins_count" -gt 0 ]]; then
        local i
        for ((i = 0; i < ins_count; i++)); do
            local line
            line=$(jq -r --argjson i "$i" '.instructions[$i]' <<<"$pattern_json")
            substitute_tokens "$line"; echo
        done
        print_only_print_extras "$pattern_json"
        return
    fi

    # 2) custom_command entries (e.g. ioq3, ollama, dhewm3, llama.cpp)
    local custom
    custom=$(jq -r '.custom_command // ""' <<<"$pattern_json")
    if [[ -n "$custom" ]]; then
        ensure_cmake_detected "$ctx"   # warns if no CMakeLists; doesn't alter command
        run_or_print "$(substitute_tokens "$custom")"
        print_only_print_extras "$pattern_json"
        return
    fi

    # 3) standard base_flags + variants
    ensure_cmake_detected "$ctx"

    # vcpkg alternative: skipped on Linux per design.
    # (cmake.ps1 always prints it; cmake.py prints it on Windows.)

    local main_flags
    main_flags=$(flags_string "$pattern_json" "")
    local main_cmd
    if [[ -z "$main_flags" ]]; then
        main_cmd="$CMAKE_PREFIX"
    else
        main_cmd="$CMAKE_PREFIX $main_flags"
    fi
    run_or_print "$main_cmd"

    # variants (only in OnlyPrint mode)
    if [[ -n "$OnlyPrint" ]]; then
        local vcount
        vcount=$(jq -r '(.variants // []) | length' <<<"$pattern_json")
        if [[ "$vcount" -gt 0 ]]; then
            echo
            echo "alternative cmake commands:"
            local vi
            for ((vi = 0; vi < vcount; vi++)); do
                echo
                local vlabel
                vlabel=$(jq -r --argjson i "$vi" '.variants[$i].label // ""' <<<"$pattern_json")
                [[ -n "$vlabel" ]] && echo "${vlabel}:"
                local vflags
                vflags=$(flags_string "$pattern_json" "$vi")
                if [[ -z "$vflags" ]]; then
                    echo "$CMAKE_PREFIX"
                else
                    echo "$CMAKE_PREFIX $vflags"
                fi
            done
        fi
    fi

    print_only_print_extras "$pattern_json"
}

# ---------- main loop ----------
matched=0
while IFS= read -r pattern_json; do
    if pattern_matches "$pattern_json"; then
        dispatch_pattern "$pattern_json"
        matched=1
        break
    fi
done < <(jq -c '.patterns[]' "$patterns_file")

if [[ "$matched" -eq 0 ]]; then
    ensure_cmake_detected "$(basename "$(pwd)")"
    printf "%bNo cmake pattern found for: %s%b\n" "$DARKYELLOW" "$(pwd)" "$RESET"
    printf "%bUsing default cmake command...%b\n" "$DARKYELLOW" "$RESET"
    run_or_print "$CMAKE_PREFIX -DCMAKE_BUILD_TYPE=$BuildType"
fi
