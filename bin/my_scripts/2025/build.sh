#!/usr/bin/env bash

# This script prints relevant build commands based on cwd
# see:
# {my_notes_path}/scripts/build_script_desc.txt
#
# Simple pattern -> source-file mappings are loaded from:
#   $my_notes_path/scripts/build_patterns.ini
# Only patterns that need custom logic remain hard-coded below.

cwd_full="$(pwd)"
cwd="${cwd_full,,}"   # lowercase for case-insensitive matching

# Colors

RESET='\033[0m'
WHITE='\033[97m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'
DARKYELLOW='\033[93m'
BOLD='\033[1m'

# Output helpers

#write_label()     { echo -e "  ${DARKGRAY}$1${RESET}"; }
#write_cmd()       { echo -e "  ${CYAN}$1${RESET}"; }
#write_alt()       { echo -e "  ${MAGENTA}$1${RESET}"; }
#write_extra()     { echo -e "  ${BLUE}$1${RESET}"; }
#write_warn()      { echo -e "${DARKYELLOW}$1${RESET}"; }
#
#write_header() {
#    echo ""
#    echo -e "  ${BOLD}${WHITE}=== $1 ===${RESET}"
#    echo ""
#}
#
#write_subheader() {
#    echo ""
#    echo -e "  ${WHITE}--- $1 ---${RESET}"
#}

# Note: use printf instead since above will turn "\t" into a tab... For example:
# vim .\test.txt
# ->
# vim .    est.txt
write_label() { printf '  %b%s%b\n' "$DARKGRAY" "$1" "$RESET"; }
#write_cmd()   { printf '  %b%s%b\n' "$CYAN" "$1" "$RESET"; }
write_alt()   { printf '  %b%s%b\n' "$MAGENTA" "$1" "$RESET"; }
write_extra() { printf '  %b%s%b\n' "$BLUE" "$1" "$RESET"; }
write_warn()  { printf '%b%s%b\n' "$DARKYELLOW" "$1" "$RESET"; }

# Fix env vars for linux
fix_cmd_text() {
    local text="$1"
    # Bash script = always Linux-style output.
    # Replace $Env:foo / $env:foo / $ENV:foo with $foo
    # (pure-bash substitution; avoids forking a subshell + sed per command)
    _fix_cmd_result="${text//\$[Ee][Nn][Vv]:/\$}"
}

write_cmd() {
    fix_cmd_text "$1"
    printf '  %b%s%b\n' "$CYAN" "$_fix_cmd_result" "$RESET"
}

write_header() {
    printf '\n'
    printf '  %b=== %s ===%b\n\n' "$BOLD$WHITE" "$1" "$RESET"
}

write_subheader() {
    printf '\n'
    printf '  %b--- %s ---%b\n' "$WHITE" "$1" "$RESET"
}

# Collect filter args: comma- or whitespace-separated, lowercased.
FILTERS=()
for _arg in "$@"; do
    # Replace commas with spaces, then rely on word splitting.
    for _p in ${_arg//,/ }; do
        [[ -n "$_p" ]] && FILTERS+=("${_p,,}")
    done
done
unset _arg _p

# Path matching helpers

# Check that keywords appear in the path in the given order (case-insensitive).
# $cwd is already lowercased, so we only need to lowercase the keywords.
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

# Usage-example extraction

# Given a file extension (with leading dot, any case), populate globals:
#   CS_SINGLE, CS_MSTART, CS_MEND
# An empty value means "not supported for this language".
get_comment_syntax() {
    local ext_lower="${1,,}"

    CS_SINGLE=""
    CS_MSTART=""
    CS_MEND=""

    case "$ext_lower" in
        .go|.rs|.js|.ts|.jsx|.tsx|.mjs|.cjs|.c|.cpp|.cc|.h|.hpp|.cs|.java|.kt|.swift|.php)
            CS_SINGLE="//"; CS_MSTART="/*"; CS_MEND="*/" ;;
        .py)
            CS_SINGLE="#"; CS_MSTART='"""'; CS_MEND='"""' ;;
        .rb)
            CS_SINGLE="#"; CS_MSTART="=begin"; CS_MEND="=end" ;;
        .sh)
            CS_SINGLE="#" ;;
        .ps1)
            CS_SINGLE="#"; CS_MSTART="<#"; CS_MEND="#>" ;;
        .lua)
            CS_SINGLE="--"; CS_MSTART="--[["; CS_MEND="]]" ;;
        .sql)
            CS_SINGLE="--"; CS_MSTART="/*"; CS_MEND="*/" ;;
        .html|.xml)
            CS_MSTART="<!--"; CS_MEND="-->" ;;
        *)
            CS_SINGLE="//"; CS_MSTART="/*"; CS_MEND="*/" ;;
    esac
}

# Helper: trim leading whitespace
ltrim() { _trim_result="${1#"${1%%[![:space:]]*}"}"; }
# Helper: trim trailing whitespace
rtrim() { _trim_result="${1%"${1##*[![:space:]]}"}"; }
# Helper: trim both
trim()  { local s="${1#"${1%%[![:space:]]*}"}"; _trim_result="${s%"${s##*[![:space:]]}"}"; }

# Track block-comment state across a scanned line, using starts/ends.
# Updates $IN_BLOCK global. Used while scanning for the marker.
_advance_block_state() {
    local line="$1" mStart="$2" mEnd="$3"
    [[ -z "$mStart" ]] && return 0

    local pos=0 len=${#line} sIdx eIdx
    while (( pos <= len )); do
        if [[ $IN_BLOCK -eq 0 ]]; then
            local rest="${line:$pos}"
            if [[ "$rest" != *"$mStart"* ]]; then break; fi
            local pre="${rest%%"$mStart"*}"
            sIdx=$((pos + ${#pre}))
            IN_BLOCK=1
            pos=$((sIdx + ${#mStart}))
        else
            local rest="${line:$pos}"
            if [[ "$rest" != *"$mEnd"* ]]; then break; fi
            local pre="${rest%%"$mEnd"*}"
            eIdx=$((pos + ${#pre}))
            IN_BLOCK=0
            pos=$((eIdx + ${#mEnd}))
        fi
    done
}

# Extract the first "example usage:" / "usage examples:" block from $1.
# Populates globals:
#   UE_FILE_EXISTS   0/1
#   UE_FOUND         0/1
#   UE_LINES         array of extracted lines
get_usage_examples() {
    local file="$1"

    UE_FILE_EXISTS=0
    UE_FOUND=0
    UE_LINES=()

    [[ -f "$file" ]] || return 0
    UE_FILE_EXISTS=1

    local ext=".${file##*.}"
    [[ "$ext" == ".$file" ]] && ext=""
    get_comment_syntax "$ext"
    local single="$CS_SINGLE" mStart="$CS_MSTART" mEnd="$CS_MEND"
    local hasSingle=0 hasMulti=0
    [[ -n "$single" ]] && hasSingle=1
    [[ -n "$mStart" ]] && hasMulti=1

    # Read all lines into an array (preserving blanks, stripping CR).
    local -a lines=()
    local raw
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        raw="${raw%$'\r'}"
        lines+=("$raw")
    done < "$file"

    local marker_re='([Ee][Xx][Aa][Mm][Pp][Ll][Ee][[:space:]]+[Uu][Ss][Aa][Gg][Ee]|[Uu][Ss][Aa][Gg][Ee][[:space:]]+[Ee][Xx][Aa][Mm][Pp][Ll][Ee][Ss])[[:space:]]*:'

    IN_BLOCK=0
    local n=${#lines[@]}
    local i j line
    for (( i=0; i<n; i++ )); do
        line="${lines[$i]}"

        if [[ ! "$line" =~ $marker_re ]]; then
            _advance_block_state "$line" "$mStart" "$mEnd"
            continue
        fi

        # Marker matched — find its index and end.
        local match="${BASH_REMATCH[0]}"
        local before="${line%%"$match"*}"
        local markerIdx=${#before}
        local markerEnd=$((markerIdx + ${#match}))

        local isMulti=0 isSingle=0

        if (( IN_BLOCK == 1 )); then
            isMulti=1
        elif (( hasMulti == 1 )); then
            # Find first /* and first */ on this line; if /* precedes the
            # marker and */ is either absent or after the marker, we're in multi.
            local startIdx=-1 endIdx=-1
            if [[ "$line" == *"$mStart"* ]]; then
                local pre="${line%%"$mStart"*}"
                startIdx=${#pre}
            fi
            if [[ "$line" == *"$mEnd"* ]]; then
                local pre2="${line%%"$mEnd"*}"
                endIdx=${#pre2}
            fi
            if (( startIdx >= 0 && startIdx < markerIdx )) \
               && { (( endIdx < 0 )) || (( endIdx > markerIdx )); }; then
                isMulti=1
            fi
        fi

        if (( isMulti == 0 && hasSingle == 1 )); then
            local lt; ltrim "$line"; lt="$_trim_result"
            [[ "$lt" == "$single"* ]] && isSingle=1
        fi

        if (( isMulti == 0 && isSingle == 0 )); then
            _advance_block_state "$line" "$mStart" "$mEnd"
            continue
        fi

        UE_FOUND=1

        if (( isMulti == 1 )); then
            local rest="${line:$markerEnd}"

            # Does the block close on this same line?
            if [[ -n "$mEnd" && "$rest" == *"$mEnd"* ]]; then
                local beforeEnd="${rest%%"$mEnd"*}"
                local afterEnd="${rest#*"$mEnd"}"
                local b; trim "$beforeEnd"; b="$_trim_result"
                [[ -n "$b" ]] && UE_LINES+=("$b")
                local a; trim "$afterEnd"; a="$_trim_result"
                [[ -n "$a" ]] && UE_LINES+=("$a")
                return 0
            else
                local rt; trim "$rest"; rt="$_trim_result"
                [[ -n "$rt" ]] && UE_LINES+=("$rt")
            fi

            # Subsequent lines until the block end-tag.
            for (( j=i+1; j<n; j++ )); do
                local l="${lines[$j]}"
                if [[ -n "$mEnd" && "$l" == *"$mEnd"* ]]; then
                    local beforeEnd="${l%%"$mEnd"*}"
                    local afterEnd="${l#*"$mEnd"}"
                    # Strip leading spaces + leading '*' characters + one space.
                    local bclean; ltrim "$beforeEnd"; bclean="$_trim_result"
                    while [[ "$bclean" == '*'* ]]; do bclean="${bclean#\*}"; done
                    [[ "$bclean" == ' '* ]] && bclean="${bclean# }"
                    rtrim "$bclean"; bclean="$_trim_result"
                    [[ -n "$bclean" ]] && UE_LINES+=("$bclean")
                    local atrim; trim "$afterEnd"; atrim="$_trim_result"
                    [[ -n "$atrim" ]] && UE_LINES+=("$atrim")
                    return 0
                else
                    local cleaned; ltrim "$l"; cleaned="$_trim_result"
                    while [[ "$cleaned" == '*'* ]]; do cleaned="${cleaned#\*}"; done
                    [[ "$cleaned" == ' '* ]] && cleaned="${cleaned# }"
                    rtrim "$cleaned"; cleaned="$_trim_result"
                    UE_LINES+=("$cleaned")
                fi
            done
            return 0
        fi

        if (( isSingle == 1 )); then
            for (( j=i+1; j<n; j++ )); do
                local lt; ltrim "${lines[$j]}"; lt="$_trim_result"
                if [[ "$lt" == "$single"* ]]; then
                    local stripped="${lt:${#single}}"
                    [[ "$stripped" == ' '* ]] && stripped="${stripped# }"
                    rtrim "$stripped"; stripped="$_trim_result"
                    UE_LINES+=("$stripped")
                else
                    break
                fi
            done
            return 0
        fi
    done

    return 0
}

# Render an extracted example block, or a friendly warning if something's off.
render_usage_from_file() {
    local file="$1"

    get_usage_examples "$file"

    if (( UE_FILE_EXISTS == 0 )); then
        write_warn "  [!] File not found:"
        echo -e "      ${DARKYELLOW}${file}${RESET}"
        return 0
    fi
    if (( UE_FOUND == 0 )); then
        write_warn "  [!] No 'example usage:' or 'usage examples:' marker found in:"
        echo -e "      ${DARKYELLOW}${file}${RESET}"
        return 0
    fi
    if (( ${#UE_LINES[@]} == 0 )); then
        write_warn "  [!] Marker found but no example content extracted from:"
        echo -e "      ${DARKYELLOW}${file}${RESET}"
        return 0
    fi

    local ln trimmed tr_ln lt_trimmed
    for ln in "${UE_LINES[@]}"; do
        rtrim "$ln"; trimmed="$_trim_result"
        trim "$ln"; tr_ln="$_trim_result"
        ltrim "$trimmed"; lt_trimmed="$_trim_result"

        if [[ -z "$tr_ln" ]]; then
            echo ""
        elif [[ "$trimmed" == *: ]]; then
            write_label "$ln"
        elif [[ "$lt_trimmed" =~ ^[Nn][Oo][Tt][Ee][[:space:]]*: ]]; then
            write_label "$ln"
        elif [[ ! "$trimmed" =~ [A-Za-z] ]]; then
            # no alphabetical chars (e.g. "---", "====", "***") => treat as label
            write_label "$ln"
        else
            write_cmd "$ln"
        fi
    done
}

# Resolve <env var>/<relative path> and render in one step.
# $1 = header text, $2 = env var name, $3 = relative path
show_project() {
    local header="$1" env_name="$2" rel="$3"

    write_header "$header"

    local root="${!env_name}"
    if [[ -z "$root" ]]; then
        write_warn "  [!] Environment variable '\$${env_name}' is not set."
        return 0
    fi

    # Strip trailing slash from root, normalise separators in rel.
    root="${root%/}"
    rel="${rel//\\//}"
    rel="${rel#/}"

    render_usage_from_file "${root}/${rel}"
}

# Render multiple files under a single header, each preceded by a sub-header.
# Honors $FILTERS (global): if non-empty, only files whose leaf name contains
# at least one filter substring are rendered.
# $1 = header, $2 = env var, remaining args = relative paths
show_project_multi() {
    local header="$1" env_name="$2"
    shift 2

    write_header "$header"

    local root="${!env_name}"
    if [[ -z "$root" ]]; then
        write_warn "  [!] Environment variable '\$${env_name}' is not set."
        return 0
    fi
    root="${root%/}"

    local -a all_paths=("$@")
    local -a selected=()
    local rel leaf leaf_lower f

    if (( ${#FILTERS[@]} > 0 )); then
        for rel in "${all_paths[@]}"; do
            leaf="${rel##*/}"
            leaf_lower="${leaf,,}"
            for f in "${FILTERS[@]}"; do
                if [[ "$leaf_lower" == *"$f"* ]]; then
                    selected+=("$rel")
                    break
                fi
            done
        done
        if (( ${#selected[@]} == 0 )); then
            write_warn "  [!] No files matched filter(s): ${FILTERS[*]}"
            write_label "Available:"
            for rel in "${all_paths[@]}"; do
                echo -e "      ${DARKYELLOW}${rel##*/}${RESET}"
            done
            return 0
        fi
    else
        selected=("${all_paths[@]}")
    fi

    local full
    for rel in "${selected[@]}"; do
        rel="${rel//\\//}"
        rel="${rel#/}"
        full="${root}/${rel}"
        leaf="${full##*/}"
        write_subheader "$leaf"
        render_usage_from_file "$full"
    done
}


# Patterns config (data-driven)
#
# Minimal INI parser. Each section's key/value pairs are collected into
# parallel global arrays:
#
#   PE_HEADERS[i]   section name (becomes the project header)
#   PE_PATTERNS[i]  patterns joined by PE_DELIM
#   PE_ENVS[i]      env var name
#   PE_MULTI[i]     0 = single file, 1 = multi
#   PE_PATHS[i]     single path (multi=0) or paths joined by PE_DELIM (multi=1)
#
# Values that span multiple lines (where continuation lines are indented
# under the key, like:
#
#     files =
#         path/a
#         path/b
#
# ) are joined with newlines and split back into a list by the flush step.
# Lines starting with '#' or ';' (after trim) are comments; section names
# can contain '#' (e.g. [C# (my_web_wow)]) because comment detection only
# triggers at start-of-line.

PATTERNS_CONFIG_REL="scripts/build_patterns.ini"
PE_DELIM=$'\x1f'   # ASCII Unit Separator — safe join delimiter

PE_HEADERS=()
PE_PATTERNS=()
PE_ENVS=()
PE_MULTI=()
PE_PATHS=()

# Join args with $PE_DELIM. Uses local IFS in a function scope.
_pe_join() {
    local IFS="$PE_DELIM"
    printf '%s' "$*"
}

# Append a finished section into the PE_* arrays. Reads section state from
# $_sec_name / $_sec_patterns / $_sec_env / $_sec_file / $_sec_files in the
# caller's scope (bash dynamic scoping). Sections missing required fields
# are silently skipped.
_pe_flush_section() {
    [[ -z "$_sec_name" ]] && return 0

    local patterns_raw="$_sec_patterns" env_name="$_sec_env"
    local file_single="$_sec_file" files_block="$_sec_files"

    [[ -z "$patterns_raw" || -z "$env_name" ]] && return 0

    # Split patterns on commas/whitespace, drop empties.
    local -a patterns=()
    local p
    for p in ${patterns_raw//,/ }; do
        [[ -n "$p" ]] && patterns+=("$p")
    done
    (( ${#patterns[@]} == 0 )) && return 0

    if [[ -n "$files_block" ]]; then
        local -a files=()
        local fline ftrim
        while IFS= read -r fline; do
            trim "$fline"; ftrim="$_trim_result"
            [[ -n "$ftrim" ]] && files+=("$ftrim")
        done <<< "$files_block"
        (( ${#files[@]} == 0 )) && return 0

        PE_HEADERS+=("$_sec_name")
        PE_PATTERNS+=("$(_pe_join "${patterns[@]}")")
        PE_ENVS+=("$env_name")
        PE_MULTI+=(1)
        PE_PATHS+=("$(_pe_join "${files[@]}")")
    elif [[ -n "$file_single" ]]; then
        PE_HEADERS+=("$_sec_name")
        PE_PATTERNS+=("$(_pe_join "${patterns[@]}")")
        PE_ENVS+=("$env_name")
        PE_MULTI+=(0)
        PE_PATHS+=("$file_single")
    fi
}

load_patterns_config() {
    PE_HEADERS=(); PE_PATTERNS=(); PE_ENVS=(); PE_MULTI=(); PE_PATHS=()

    [[ -z "${my_notes_path:-}" ]] && return 0
    local config_path="${my_notes_path%/}/$PATTERNS_CONFIG_REL"
    [[ -f "$config_path" ]] || return 0

    local _sec_name=""
    local _sec_patterns="" _sec_env="" _sec_file="" _sec_files=""
    local current_key=""

    local raw trimmed key val
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        raw="${raw%$'\r'}"
        trim "$raw"; trimmed="$_trim_result"

        # Blank or comment line: reset continuation, skip.
        if [[ -z "$trimmed" ]] || [[ "$trimmed" == \#* ]] || [[ "$trimmed" == ';'* ]]; then
            current_key=""
            continue
        fi

        # Section header [name]
        if [[ "$trimmed" == '['*']' ]]; then
            _pe_flush_section
            _sec_name="${trimmed#[}"; _sec_name="${_sec_name%]}"
            _sec_patterns=""; _sec_env=""; _sec_file=""; _sec_files=""
            current_key=""
            continue
        fi

        # Continuation: raw starts with whitespace AND we have an active key.
        if [[ -n "$current_key" ]] && [[ "$raw" == [[:space:]]* ]]; then
            case "$current_key" in
                patterns) [[ -z "$_sec_patterns" ]] && _sec_patterns="$trimmed" || _sec_patterns="${_sec_patterns}"$'\n'"$trimmed" ;;
                env)      [[ -z "$_sec_env" ]]      && _sec_env="$trimmed"      || _sec_env="${_sec_env}"$'\n'"$trimmed" ;;
                file)     [[ -z "$_sec_file" ]]     && _sec_file="$trimmed"     || _sec_file="${_sec_file}"$'\n'"$trimmed" ;;
                files)    [[ -z "$_sec_files" ]]    && _sec_files="$trimmed"    || _sec_files="${_sec_files}"$'\n'"$trimmed" ;;
            esac
            continue
        fi

        # key = value
        if [[ "$trimmed" == *"="* ]]; then
            trim "${trimmed%%=*}"; key="${_trim_result,,}"
            trim "${trimmed#*=}"; val="$_trim_result"
            case "$key" in
                patterns) _sec_patterns="$val"; current_key="patterns" ;;
                env)      _sec_env="$val";      current_key="env" ;;
                file)     _sec_file="$val";     current_key="file" ;;
                files)    _sec_files="$val";    current_key="files" ;;
                *)        current_key="" ;;
            esac
        else
            current_key=""
        fi
    done < "$config_path"

    # Flush last section.
    _pe_flush_section
}


# Match rules

matched=0

# ----------------------------------------------------------------------
# Data-driven entries from $my_notes_path/scripts/build_patterns.ini
# (covers all simple show_project / show_project_multi cases)
# ----------------------------------------------------------------------
load_patterns_config
for (( _pe_i=0; _pe_i<${#PE_HEADERS[@]}; _pe_i++ )); do
    IFS=$'\x1f' read -ra _pe_pats <<< "${PE_PATTERNS[$_pe_i]}"
    if path_contains_in_order "${_pe_pats[@]}"; then
        if (( ${PE_MULTI[$_pe_i]} == 1 )); then
            IFS=$'\x1f' read -ra _pe_files <<< "${PE_PATHS[$_pe_i]}"
            show_project_multi "${PE_HEADERS[$_pe_i]}" "${PE_ENVS[$_pe_i]}" "${_pe_files[@]}"
        else
            show_project "${PE_HEADERS[$_pe_i]}" "${PE_ENVS[$_pe_i]}" "${PE_PATHS[$_pe_i]}"
        fi
        matched=1
        break
    fi
done
unset _pe_i _pe_pats _pe_files

# ----------------------------------------------------------------------
# Custom-logic patterns (can't be expressed as simple file mappings)
# ----------------------------------------------------------------------
if (( matched == 0 )); then

# my_notes -> scripts -> live_plotext / live_termplot (same file set)
if path_contains_in_order my_notes scripts live_plotext \
  || path_contains_in_order my_notes scripts live_termplot \
  || path_contains_in_order downloads live_plotext \
  || path_contains_in_order downloads live_termplot; then

    # Which subfolder?
    if path_contains_in_order live_plotext; then
        folder="live_plotext"
    else
        folder="live_termplot"
    fi

    # Which root?
    if path_contains_in_order my_notes scripts; then
        env_name="my_notes_path"
        prefix="notes/svea/scripts/stats/${folder}"
    else
        env_name="HOME"
        prefix="Downloads/${folder}"
    fi

    live_files=(
        "live_address.py"
        "live_audit.py"
        "live_filejobs.py"
        "live_general.py"
        "live_orders.py"
        "live_pending.py"
        "live_useractionlog.py"
        "live_gpt_stats.py"
    )

    rel_paths=()
    for f in "${live_files[@]}"; do
        rel_paths+=("${prefix}/${f}")
    done

    show_project_multi "$folder" "$env_name" "${rel_paths[@]}"
    matched=1

# code2 -> webwowviewer   (prefer .ts, fall back to .js)
elif path_contains_in_order code2 webwowviewer; then
    write_header "Web WoW Viewer (npm)"
    root="${code_root_dir:-}"
    if [[ -z "$root" ]]; then
        write_warn "  [!] Environment variable '\$code_root_dir' is not set."
    else
        root="${root%/}"
        ts_path="${root}/Code2/Wow/tools/WebWoWViewer/js/application/angular/app_wow.ts"
        js_path="${root}/Code2/Wow/tools/WebWoWViewer/js/application/angular/app_wowjs.js"
        if [[ -f "$ts_path" ]]; then
            render_usage_from_file "$ts_path"
        elif [[ -f "$js_path" ]]; then
            render_usage_from_file "$js_path"
        else
            write_warn "  [!] Neither of these files exist:"
            echo -e "      ${DARKYELLOW}${ts_path}${RESET}"
            echo -e "      ${DARKYELLOW}${js_path}${RESET}"
        fi
    fi
    matched=1

# code2 -> spelunker
elif path_contains_in_order code2 spelunker; then
    write_header "Spelunker"
    write_label "setup:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/spelunker'
    write_cmd   "./setup.sh"
    echo ""
    write_label "start wow mpq file server and do (in both spelunker-api and spelunker-web):"
    write_cmd   "source ../../.envrc && npm start"
    echo ""
    write_label "If needed for file server (if mounted) you might need:"
    write_extra "npm install express cors --no-bin-links"
    matched=1

# code2 -> azeroth-web-proxy  (must come before azeroth-web)
elif path_contains_in_order code2 azeroth-web-proxy; then
    write_header "Azeroth Web Proxy"
    write_cmd   "npm start"
    echo ""
    write_label "Also run script in my_notes via:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/azeroth-web'
    write_cmd   "./setup.sh"
    echo ""
    write_label "Also start either acore/tcore to be able to login!"
    matched=1

# code2 -> azeroth-web
elif path_contains_in_order code2 azeroth-web; then
    write_header "Azeroth Web"
    write_cmd   "npm install -g typescript"
    write_cmd   "npm run dev"
    echo ""
    write_label "Also run script in my_notes via:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/azeroth-web'
    write_cmd   "./setup.sh"
    echo ""
    write_label "Also start either acore/tcore to be able to login!"
    matched=1

# code2 -> wowser
elif path_contains_in_order code2 wowser; then
    write_header "Wowser"
    write_label "Run script in my_notes via:"
    write_cmd   'cd $HOME/Documents/my_notes/scripts/wow/wowser'
    write_cmd   "./setup.sh"
    echo ""
    write_cmd   "npm run serve"
    write_label "NOTE: specify wow client dir after running npm run serve!"
    write_label "you may need this if client dir is wrong:"
    write_alt   "npm run reset"
    write_label "use:"
    write_extra '$wow_dir'
    echo ""
    write_label "then, in another shell:"
    write_cmd   "npm run web-dev"
    matched=1

# code2 -> my_js -> keybinds
elif path_contains_in_order code2 my_js keybinds; then
    write_header "my_js / Keybinds"
    write_label "do this:"
    write_cmd   "npm run dev"
    echo ""
    write_alt   "npm run start"
    matched=1

# Fallback: check files in current directory
else
    if [[ -f "worldserver.exe" && -f "authserver.exe" ]]; then
        write_header "World Server"
        write_cmd   "python overwrite.py && ./worldserver.exe"
        echo ""
        write_label "Linux gdb:"
        write_alt   "python overwrite.py && gdb -x gdb.conf --batch ./worldserver"
        matched=1

    elif [[ -f "cors_server.js" && -f "cors_server.py" ]]; then
        write_header "CORS Server"
        write_cmd  "node ./cors_server.js"
        write_alt  "python ./cors_server.py"
        matched=1
    fi
fi

fi  # end: if matched == 0 (custom-logic block)

# No match
if [[ $matched -eq 0 ]]; then
    echo ""
    write_warn "  [!] No build commands matched for:"
    echo -e "      ${DARKYELLOW}${cwd_full}${RESET}"
    echo ""
fi
