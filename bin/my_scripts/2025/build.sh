#!/usr/bin/env bash

# This script prints relevant build commands based on cwd
# see:
# {my_notes_path}/scripts/build_script_desc.txt

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
write_cmd()   { printf '  %b%s%b\n' "$CYAN" "$1" "$RESET"; }
write_alt()   { printf '  %b%s%b\n' "$MAGENTA" "$1" "$RESET"; }
write_extra() { printf '  %b%s%b\n' "$BLUE" "$1" "$RESET"; }
write_warn()  { printf '%b%s%b\n' "$DARKYELLOW" "$1" "$RESET"; }

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
ltrim() { local s="$1"; printf '%s' "${s#"${s%%[![:space:]]*}"}"; }
# Helper: trim trailing whitespace
rtrim() { local s="$1"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }
# Helper: trim both
trim()  { local s; s="$(ltrim "$1")"; rtrim "$s"; }

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
            local lt; lt="$(ltrim "$line")"
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
                local b; b="$(trim "$beforeEnd")"
                [[ -n "$b" ]] && UE_LINES+=("$b")
                local a; a="$(trim "$afterEnd")"
                [[ -n "$a" ]] && UE_LINES+=("$a")
                return 0
            else
                local rt; rt="$(trim "$rest")"
                [[ -n "$rt" ]] && UE_LINES+=("$rt")
            fi

            # Subsequent lines until the block end-tag.
            for (( j=i+1; j<n; j++ )); do
                local l="${lines[$j]}"
                if [[ -n "$mEnd" && "$l" == *"$mEnd"* ]]; then
                    local beforeEnd="${l%%"$mEnd"*}"
                    local afterEnd="${l#*"$mEnd"}"
                    # Strip leading spaces + leading '*' characters + one space.
                    local bclean; bclean="$(ltrim "$beforeEnd")"
                    while [[ "$bclean" == '*'* ]]; do bclean="${bclean#\*}"; done
                    [[ "$bclean" == ' '* ]] && bclean="${bclean# }"
                    bclean="$(rtrim "$bclean")"
                    [[ -n "$bclean" ]] && UE_LINES+=("$bclean")
                    local atrim; atrim="$(trim "$afterEnd")"
                    [[ -n "$atrim" ]] && UE_LINES+=("$atrim")
                    return 0
                else
                    local cleaned; cleaned="$(ltrim "$l")"
                    while [[ "$cleaned" == '*'* ]]; do cleaned="${cleaned#\*}"; done
                    [[ "$cleaned" == ' '* ]] && cleaned="${cleaned# }"
                    cleaned="$(rtrim "$cleaned")"
                    UE_LINES+=("$cleaned")
                fi
            done
            return 0
        fi

        if (( isSingle == 1 )); then
            for (( j=i+1; j<n; j++ )); do
                local lt; lt="$(ltrim "${lines[$j]}")"
                if [[ "$lt" == "$single"* ]]; then
                    local stripped="${lt:${#single}}"
                    [[ "$stripped" == ' '* ]] && stripped="${stripped# }"
                    stripped="$(rtrim "$stripped")"
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

    local ln trimmed
    for ln in "${UE_LINES[@]}"; do
        trimmed="$(rtrim "$ln")"

        if [[ -z "$(trim "$ln")" ]]; then
            echo ""
        elif [[ "$trimmed" == *: ]]; then
            write_label "$ln"
        elif [[ "$(ltrim "$trimmed")" =~ ^[Nn][Oo][Tt][Ee][[:space:]]*: ]]; then
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

# Match rules

matched=0

# code2 -> go -> my_web_wow
if path_contains_in_order code2 go my_web_wow; then
    show_project "Go (my_web_wow)" code_root_dir \
        "Code2/Wow/tools/my_wow/go/my_web_wow/main.go"
    matched=1

# code2 -> go -> tbc
elif path_contains_in_order code2 go tbc; then
    show_project "Go (tbc)" code_root_dir \
        "Code2/Wow/tools/my_wow/go/tbc/main.go"
    matched=1

# code2 -> rust -> my_web_wow
elif path_contains_in_order code2 rust my_web_wow; then
    show_project "Rust (my_web_wow)" code_root_dir \
        "Code2/Wow/tools/my_wow/rust/my_web_wow/src/main.rs"
    matched=1

# code2 -> rust -> tbc
elif path_contains_in_order code2 rust tbc; then
    show_project "Rust (tbc)" code_root_dir \
        "Code2/Wow/tools/my_wow/rust/tbc/src/main.rs"
    matched=1

# code2 -> py -> my_web_wow
elif path_contains_in_order code2 py my_web_wow; then
    show_project "Python (my_web_wow)" code_root_dir \
        "Code2/Wow/tools/my_wow/python/my_web_wow/main.py"
    matched=1

# code2 -> py -> tbc
elif path_contains_in_order code2 py tbc; then
    show_project "Python (tbc)" code_root_dir \
        "Code2/Wow/tools/my_wow/python/tbc/main.py"
    matched=1

# code2 -> c# -> my_web_wow
elif path_contains_in_order code2 "c#" my_web_wow; then
    show_project "C# (my_web_wow)" code_root_dir \
        "Code2/Wow/tools/my_wow/c#/my_web_wow/my_web_wow/Program.cs"
    matched=1

# code2 -> c# -> tbc
elif path_contains_in_order code2 "c#" tbc; then
    show_project "C# (tbc)" code_root_dir \
        "Code2/Wow/tools/my_wow/c#/tbc/tbc/Program.cs"
    matched=1

# code2 -> gfx -> wc_testing_go   (must come before wc_testing)
elif path_contains_in_order code2 gfx wc_testing_go; then
    show_project_multi "WC Testing (Go)" code_root_dir \
        "Code2/General/gfx/wc_testing_go/adt_app.go" \
        "Code2/General/gfx/wc_testing_go/m2_app.go" \
        "Code2/General/gfx/wc_testing_go/wdl_app.go" \
        "Code2/General/gfx/wc_testing_go/wmo_app.go"
    matched=1

# code2 -> gfx -> wc_testing_py   (must come before wc_testing)
elif path_contains_in_order code2 gfx wc_testing_py; then
    show_project_multi "WC Testing (Python)" code_root_dir \
        "Code2/General/gfx/wc_testing_py/adt_app.py" \
        "Code2/General/gfx/wc_testing_py/m2_app.py" \
        "Code2/General/gfx/wc_testing_py/wdl_app.py" \
        "Code2/General/gfx/wc_testing_py/wmo_app.py"
    matched=1

# code2 -> gfx -> wc_testing_rs   (must come before wc_testing)
elif path_contains_in_order code2 gfx wc_testing_rs; then
    show_project_multi "WC Testing (Rust)" code_root_dir \
        "Code2/General/gfx/wc_testing_rs/src/adt_app.rs" \
        "Code2/General/gfx/wc_testing_rs/src/m2_app.rs" \
        "Code2/General/gfx/wc_testing_rs/src/wdl_app.rs" \
        "Code2/General/gfx/wc_testing_rs/src/wmo_app.rs"
    matched=1

# code2 -> gfx -> wc_testing   (C# variant, plain name)
elif path_contains_in_order code2 gfx wc_testing; then
    show_project_multi "WC Testing (C#)" code_root_dir \
        "Code2/General/gfx/wc_testing/AdtApp.cs" \
        "Code2/General/gfx/wc_testing/M2App.cs" \
        "Code2/General/gfx/wc_testing/WdlApp.cs" \
        "Code2/General/gfx/wc_testing/WmoApp.cs"
    matched=1

# my_notes -> scripts -> live_plotext / live_termplot (same file set)
elif path_contains_in_order my_notes scripts live_plotext \
  || path_contains_in_order my_notes scripts live_termplot; then

    if path_contains_in_order my_notes scripts live_plotext; then
        folder="live_plotext"
    else
        folder="live_termplot"
    fi

    live_files=(
        "live_address.py"
        "live_audit.py"
        "live_filejobs.py"
        "live_general.py"
        "live_orders.py"
        "live_pending.py"
        "live_useractionlog.py"
    )

    rel_paths=()
    for f in "${live_files[@]}"; do
        rel_paths+=("notes/svea/scripts/stats/${folder}/${f}")
    done

    show_project_multi "$folder" my_notes_path "${rel_paths[@]}"
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

# code2 -> my_js -> mysql
elif path_contains_in_order code2 my_js mysql; then
    show_project "my_js / MySQL" code_root_dir \
        "Code2/Javascript/my_js/Testing/mysql/main.js"
    matched=1

# code2 -> my_js -> navigation -> ffi-napi   (must come before plain navigation)
elif path_contains_in_order code2 my_js navigation ffi-napi; then
    show_project "my_js / Navigation (ffi-napi)" code_root_dir \
        "Code2/Javascript/my_js/Testing/navigation/ffi-napi/main.js"
    matched=1

# code2 -> my_js -> navigation
elif path_contains_in_order code2 my_js navigation; then
    show_project "my_js / Navigation" code_root_dir \
        "Code2/Javascript/my_js/Testing/navigation/main.js"
    matched=1

# code2 -> my_js -> keybinds
elif path_contains_in_order code2 my_js keybinds; then
    write_header "my_js / Keybinds"
    write_label "do this:"
    write_cmd   "npm run dev"
    echo ""
    write_alt   "npm run start"
    matched=1

# my_notes -> orders_ts
elif path_contains_in_order my_notes orders_ts; then
    show_project "orders_ts" my_notes_path \
        "notes/svea/scripts/orders_ts/src/orders.ts"
    matched=1

# my_notes -> latest-orders-ts
elif path_contains_in_order my_notes latest-orders-ts; then
    show_project "latest-orders-ts" my_notes_path \
        "notes/svea/scripts/stats/latest-orders-ts/app/src/server.ts"
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

# No match
if [[ $matched -eq 0 ]]; then
    echo ""
    write_warn "  [!] No build commands matched for:"
    echo -e "      ${DARKYELLOW}${cwd_full}${RESET}"
    echo ""
fi
