#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════
# lsh - ls helper with human-readable explanations
#
# Runs ls with appropriate flags based on a chosen mode and then prints
# both the raw output and a detailed, color-coded breakdown explaining
# every field: file type, permissions (with octal), owner, group, etc.
#
# ── Installation ─────────────────────────────────────────────────────────
#
#   cp lsh.sh ~/.local/bin/lsh
#   chmod +x ~/.local/bin/lsh
#
# ── Usage ────────────────────────────────────────────────────────────────
#
#   lsh [mode] [path ...] [--debug]
#   lsh raw -- <custom ls flags>
#
# ── Modes ────────────────────────────────────────────────────────────────
#
#   detail   (default)  ls -lh    Detailed listing with metadata
#   dir                 ls -ldh   Directory entry itself, not its contents
#   all                 ls -lAh   Include hidden files (except . and ..)
#   size                ls -lhS   Sort by file size, largest first
#   time                ls -lht   Sort by modification time, recent first
#   type                ls -lhF   Append type indicators (/ * @ |)
#   inode               ls -lhi   Show inode numbers
#   perm                ls -lhd   Target's own entry (permission check)
#   recur               ls -lhR   Recursive listing into subdirectories
#   raw                 custom    Pass arbitrary ls flags after --
#
# ── Options ──────────────────────────────────────────────────────────────
#
#   --debug   Print the resolved ls command instead of running it
#   --help    Show colored help with reference tables
#
# ── Examples ─────────────────────────────────────────────────────────────
#
#   lsh                              # detailed listing of current directory
#   lsh .                            # same thing, explicit current dir
#   lsh /etc                         # detailed listing of /etc
#   lsh ~/projects/myapp/src         # listing of a specific subdirectory
#
#   # --- Understanding a directory's own permissions ---
#   lsh dir /tmp                     # who can write to /tmp? (sticky bit?)
#   lsh dir /var/log                 # check if your user can access logs
#   lsh dir .                        # permissions on the current directory
#
#   # --- Finding files ---
#   lsh all ~                        # show dotfiles in home directory
#   lsh size /var/log                # which log files are eating disk space?
#   lsh time .                       # what changed most recently?
#
#   # --- Permission auditing ---
#   lsh perm /etc/shadow             # check permissions on a sensitive file
#   lsh perm /usr/bin/sudo           # is setuid set? (expect octal 4755)
#   lsh perm ~/.ssh                  # should be 700 (owner only)
#   lsh perm ~/.ssh/id_rsa           # should be 600 (owner read/write only)
#
#   # --- Filesystem details ---
#   lsh inode /tmp                   # see inode numbers (hardlink detection)
#   lsh type /usr/bin                # see which entries are dirs, symlinks, etc.
#   lsh recur ~/projects/small-proj  # full recursive tree with breakdowns
#
#   # --- Debug mode (print command, don't run it) ---
#   lsh size /var/log --debug        # → prints: ls -lhS /var/log
#   lsh all ~ --debug                # → prints: ls -lAh /home/you
#   lsh recur /etc --debug           # → prints: ls -lhR /etc
#
#   # --- Raw mode (pass any ls flags you want) ---
#   lsh raw -- -la /tmp              # custom: ls -la /tmp
#   lsh raw -- -lhS --sort=time .    # custom: combine flags freely
#   lsh raw -- -ldh /usr /var /tmp   # custom: multiple directory entries
#
#   # --- Combine with other tools ---
#   lsh size . 2>&1 | head -50       # truncate long output
#   lsh recur . 2>&1 | less -R       # page through with colors preserved
#
# ══════════════════════════════════════════════════════════════════════════

# === Colors === #
RESET=$'\033[0m'
BOLD=$'\033[1m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
DARKGRAY=$'\033[90m'

# === Write helpers === #
write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }
write_dim()      { echo -e "${DARKGRAY}${1}${RESET}"; }
write_bold()     { echo -e "${BOLD}${1}${RESET}"; }

label() {
    printf "  ${DARKGRAY}%-18s${RESET} %s\n" "$1" "$2"
}
label_colored() {
    # $1=label  $2=color  $3=value
    printf "  ${DARKGRAY}%-18s${RESET} ${2}%s${RESET}\n" "$1" "$3"
}
separator()  { write_dim "$(printf '%.0s─' {1..66})"; }
thin_sep()   { write_dim "$(printf '%.0s·' {1..56})"; }

# ──────────────────────────────────────────────────────────────────────────
# File type from first character of the permission string
# ──────────────────────────────────────────────────────────────────────────
explain_file_type() {
    case "$1" in
        -)  echo "Regular file" ;;
        d)  echo "Directory" ;;
        l)  echo "Symbolic link" ;;
        c)  echo "Character device" ;;
        b)  echo "Block device" ;;
        p)  echo "Named pipe (FIFO)" ;;
        s)  echo "Socket" ;;
        *)  echo "Unknown type ($1)" ;;
    esac
}

file_type_color() {
    case "$1" in
        d)   echo "$CYAN" ;;
        l)   echo "$MAGENTA" ;;
        c|b) echo "$YELLOW" ;;
        p|s) echo "$RED" ;;
        *)   echo "$GREEN" ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────
# Explain a single rwx/sStT triplet
# ──────────────────────────────────────────────────────────────────────────
explain_triplet() {
    local t="$1"   # 3-char triplet e.g. "rwx", "r-x", "rwS"
    local who="$2" # "owner", "group", or "others"
    local parts=()

    [[ "${t:0:1}" == "r" ]] && parts+=("read")
    [[ "${t:1:1}" == "w" ]] && parts+=("write")

    case "${t:2:1}" in
        x)  parts+=("execute") ;;
        s)  parts+=("execute")
            [[ "$who" == "owner" ]] && parts+=("[setuid]") || parts+=("[setgid]") ;;
        S)  [[ "$who" == "owner" ]] && parts+=("[setuid, no exec]") || parts+=("[setgid, no exec]") ;;
        t)  parts+=("execute"); parts+=("[sticky]") ;;
        T)  parts+=("[sticky, no exec]") ;;
    esac

    if [[ ${#parts[@]} -eq 0 ]]; then
        echo "${RED}none${RESET}"
    else
        echo "${parts[*]}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────
# Convert 10-char permission string to octal (e.g. drwxr-xr-x → 755)
# ──────────────────────────────────────────────────────────────────────────
perm_to_octal() {
    local p="$1"
    local result=""
    local special=0

    local i
    for i in 0 1 2; do
        local offset=$((1 + i * 3))
        local r="${p:$offset:1}"
        local w="${p:$((offset + 1)):1}"
        local x="${p:$((offset + 2)):1}"
        local val=0

        [[ "$r" == "r" ]] && val=$((val + 4))
        [[ "$w" == "w" ]] && val=$((val + 2))

        case "$x" in
            x) val=$((val + 1)) ;;
            s) val=$((val + 1))
               [[ $i -eq 0 ]] && special=$((special + 4)) || special=$((special + 2)) ;;
            S) [[ $i -eq 0 ]] && special=$((special + 4)) || special=$((special + 2)) ;;
            t) val=$((val + 1)); special=$((special + 1)) ;;
            T) special=$((special + 1)) ;;
        esac

        result+="$val"
    done

    if [[ $special -gt 0 ]]; then
        echo "${special}${result}"
    else
        echo "$result"
    fi
}

# ──────────────────────────────────────────────────────────────────────────
# Explain one line of ls -l output
# ──────────────────────────────────────────────────────────────────────────
explain_entry() {
    local line="$1"
    local has_inode="$2"

    # Parse fields — the last variable in `read` captures everything remaining,
    # so filenames with spaces are handled correctly.
    local inode="" perms links owner group size month day timeoryear name

    if [[ "$has_inode" == "yes" ]]; then
        read -r inode perms links owner group size month day timeoryear name <<< "$line"
    else
        read -r perms links owner group size month day timeoryear name <<< "$line"
    fi

    # Sometimes read can fail silently if line is malformed
    if [[ -z "${perms:-}" ]]; then return 0; fi

    local ftype_char="${perms:0:1}"
    local ftype
    ftype=$(explain_file_type "$ftype_char")
    local fcolor
    fcolor=$(file_type_color "$ftype_char")
    local octal
    octal=$(perm_to_octal "$perms")

    local owner_perm="${perms:1:3}"
    local group_perm="${perms:4:3}"
    local other_perm="${perms:7:3}"

    # Symlink target
    local link_target=""
    local display_name="$name"
    if [[ "$ftype_char" == "l" && "$name" == *" -> "* ]]; then
        display_name="${name%% -> *}"
        link_target="${name##* -> }"
    fi

    # ── Entry header ──
    echo ""
    printf "  ${fcolor}${BOLD}%s${RESET}" "$display_name"
    if [[ -n "$link_target" ]]; then
        printf " ${DARKGRAY}→${RESET} ${MAGENTA}%s${RESET}" "$link_target"
    fi
    echo ""
    thin_sep

    label_colored "Type:"        "$fcolor" "$ftype"
    label         "Permissions:" "$perms  (octal: $octal)"
    printf "  ${DARKGRAY}  ├ Owner:       ${RESET} %s\n" "$(explain_triplet "$owner_perm" "owner")"
    printf "  ${DARKGRAY}  ├ Group:       ${RESET} %s\n" "$(explain_triplet "$group_perm" "group")"
    printf "  ${DARKGRAY}  └ Others:      ${RESET} %s\n" "$(explain_triplet "$other_perm" "others")"
    label         "Owner:"       "$owner"
    label         "Group:"       "$group"
    label         "Size:"        "$size"
    label         "Modified:"    "$month $day $timeoryear"
    label         "Hard links:"  "$links"

    if [[ -n "$link_target" ]]; then label_colored "Points to:" "$MAGENTA" "$link_target"; fi
    if [[ -n "$inode" ]]; then label "Inode:" "$inode"; fi
}

# ──────────────────────────────────────────────────────────────────────────
# Mode → ls flags mapping
# ──────────────────────────────────────────────────────────────────────────
mode_to_flags() {
    case "$1" in
        detail) echo "-lh" ;;
        dir)    echo "-ldh" ;;
        all)    echo "-lAh" ;;
        size)   echo "-lhS" ;;
        time)   echo "-lht" ;;
        type)   echo "-lhF" ;;
        inode)  echo "-lhi" ;;
        recur)  echo "-lhR" ;;
        perm)   echo "-lhd" ;;
        raw)    echo "" ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────
# Human-readable mode descriptions
# ──────────────────────────────────────────────────────────────────────────
describe_mode() {
    case "$1" in
        detail) echo "Detailed listing with metadata (permissions, owner, group, size, dates)" ;;
        dir)    echo "Shows the directory entry itself, not its contents — check a dir's own permissions" ;;
        all)    echo "Includes hidden files (names starting with .), except . and .." ;;
        size)   echo "Sorted by size, largest first" ;;
        time)   echo "Sorted by modification time, most recent first" ;;
        type)   echo "Appends type indicators:  / = dir   * = executable   @ = symlink   | = pipe" ;;
        inode)  echo "Shows inode numbers — unique filesystem-level identifiers for each file" ;;
        recur)  echo "Recursively lists all subdirectories and their contents" ;;
        perm)   echo "Shows the target path's own entry (like 'dir' mode) — useful for permission checks" ;;
        raw)    echo "Custom ls flags passed after --" ;;
        *)      echo "" ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────
# Summary statistics
# ──────────────────────────────────────────────────────────────────────────
print_summary() {
    local output="$1"

    local dirs=0 files=0 links=0 others=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == total* ]] && continue
        [[ "$line" == *: ]] && continue
        # Extract file type from the permission string (handles inode prefix too)
        if [[ "$line" =~ ([dlcbps-])[rwxsStT-]{9} ]]; then
            case "${BASH_REMATCH[1]}" in
                d) dirs=$((dirs + 1)) ;;
                l) links=$((links + 1)) ;;
                -) files=$((files + 1)) ;;
                [cbps]) others=$((others + 1)) ;;
            esac
        fi
    done <<< "$output"

    echo ""
    write_info "  Summary"
    [[ $dirs   -gt 0 ]] && label_colored "Directories:" "$CYAN"    "$dirs"
    [[ $files  -gt 0 ]] && label_colored "Files:"       "$GREEN"   "$files"
    [[ $links  -gt 0 ]] && label_colored "Symlinks:"    "$MAGENTA" "$links"
    [[ $others -gt 0 ]] && label_colored "Special:"     "$YELLOW"  "$others"
    label "Total entries:" "$((dirs + files + links + others))"
}

# ──────────────────────────────────────────────────────────────────────────
# Column legend
# ──────────────────────────────────────────────────────────────────────────
print_legend() {
    echo ""
    write_info "  How to read ls -l output:"
    echo ""
    write_dim "    Permissions   Links  Owner  Group   Size   Modified       Name"
    write_dim "    ──────────    ─────  ─────  ─────   ────   ────────       ────"
    write_dim "    drwxr-xr-x     2    jonas  staff   4.0K   Jun 24 10:30   mydir"
    write_dim "    │└─┬──┘└┬─┘"
    write_dim "    │  │    │"
    write_dim "    │  │    └─ others: r-x = read + execute"
    write_dim "    │  └────── group:  r-x = read + execute"
    write_dim "    │          owner:  rwx = read + write + execute"
    write_dim "    └───────── type:   d   = directory"
}

# ──────────────────────────────────────────────────────────────────────────
# Usage / help
# ──────────────────────────────────────────────────────────────────────────
usage() {
    echo ""
    write_bold "  lsh — ls helper with human-readable explanations"
    write_dim "  Wraps ls and explains every field in plain English."
    echo ""
    separator
    write_bold "  USAGE"
    separator
    echo ""
    write_info "    lsh [mode] [path ...] [--debug]"
    write_info "    lsh raw -- <custom ls flags>"
    echo ""
    write_dim "    Mode must come before paths. If omitted, defaults to 'detail'."
    write_dim "    Paths can be files or directories (multiple paths supported)."
    echo ""
    separator
    write_bold "  MODES"
    separator
    echo ""
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "detail" "ls -lh"  "Detailed listing with metadata  [default]"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "dir"    "ls -ldh" "Directory entry itself, not its contents"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "all"    "ls -lAh" "Include hidden files (except . and ..)"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "size"   "ls -lhS" "Sort by size, largest first"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "time"   "ls -lht" "Sort by modification time, recent first"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "type"   "ls -lhF" "With type indicators (/ * @ |)"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "inode"  "ls -lhi" "Show inode numbers"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "perm"   "ls -lhd" "Target's own entry (permission check)"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "recur"  "ls -lhR" "Recursive listing"
    printf "    ${GREEN}%-8s${RESET}  ${DARKGRAY}%-14s${RESET} %s\n" "raw"    "custom"  "Pass custom flags after --"
    echo ""
    separator
    write_bold "  OPTIONS"
    separator
    echo ""
    printf "    ${YELLOW}%-12s${RESET}  %s\n" "--debug" "Print the resolved ls command instead of running it"
    printf "    ${YELLOW}%-12s${RESET}  %s\n" "--help, -h" "Show this help"
    echo ""
    separator
    write_bold "  EXAMPLES"
    separator
    echo ""
    write_info "    Basic listing:"
    write_dim "      lsh                            # current dir, detailed"
    write_dim "      lsh /etc                       # list /etc contents"
    write_dim "      lsh all ~                      # home dir including dotfiles"
    echo ""
    write_info "    Finding things:"
    write_dim "      lsh size /var/log              # biggest log files first"
    write_dim "      lsh time .                     # most recently modified first"
    write_dim "      lsh recur ~/project            # recursive tree with breakdowns"
    echo ""
    write_info "    Permission checks:"
    write_dim "      lsh dir /tmp                   # who can write to /tmp?"
    write_dim "      lsh perm /etc/shadow           # check sensitive file perms"
    write_dim "      lsh perm ~/.ssh/id_rsa         # should show octal 600"
    write_dim "      lsh perm /usr/bin/sudo         # should show octal 4755 (setuid)"
    echo ""
    write_info "    Debug mode (shows command without running):"
    write_dim "      lsh size /var --debug           # prints: ls -lhS /var"
    write_dim "      lsh all /etc --debug            # prints: ls -lAh /etc"
    echo ""
    write_info "    Raw mode (pass any flags to ls):"
    write_dim "      lsh raw -- -la /tmp             # ls -la /tmp"
    write_dim "      lsh raw -- -ldh /usr /var /tmp  # multiple dir entries"
    echo ""
    separator
    write_bold "  QUICK REFERENCE — Permission string"
    separator
    echo ""
    write_dim "    The 10-character permission string from ls -l:"
    echo ""
    printf "    ${CYAN}d${RESET}${GREEN}rwx${RESET}${YELLOW}r-x${RESET}${MAGENTA}r--${RESET}    "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}│││${RESET}${MAGENTA}│││${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}│││${RESET}${MAGENTA}││└─ others: execute${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}│││${RESET}${MAGENTA}│└── others: write${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}│││${RESET}${MAGENTA}└─── others: read${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}││└──── group: execute${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}│└───── group: write${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│││${RESET}${YELLOW}└────── group: read${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}││└─────── owner: execute${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}│└──────── owner: write${RESET}\n"
    printf "              "
    printf "${CYAN}│${RESET}${GREEN}└───────── owner: read${RESET}\n"
    printf "              "
    printf "${CYAN}└────────── file type${RESET}\n"
    echo ""
    separator
    write_bold "  QUICK REFERENCE — File types"
    separator
    echo ""
    printf "    ${CYAN}%-4s${RESET}  %s\n" "-" "Regular file"
    printf "    ${CYAN}%-4s${RESET}  %s\n" "d" "Directory"
    printf "    ${CYAN}%-4s${RESET}  %s\n" "l" "Symbolic link"
    printf "    ${CYAN}%-4s${RESET}  %s\n" "c" "Character device  (e.g. /dev/tty)"
    printf "    ${CYAN}%-4s${RESET}  %s\n" "b" "Block device  (e.g. /dev/sda)"
    printf "    ${CYAN}%-4s${RESET}  %s\n" "p" "Named pipe (FIFO)"
    printf "    ${CYAN}%-4s${RESET}  %s\n" "s" "Socket"
    echo ""
    separator
    write_bold "  QUICK REFERENCE — Special permission bits"
    separator
    echo ""
    printf "    ${YELLOW}%-6s${RESET}  %-12s  %s\n" "s" "setuid (4xxx)" "File runs as its owner, not the caller"
    printf "    ${YELLOW}%-6s${RESET}  %-12s  %s\n" "s" "setgid (2xxx)" "File runs as its group / dir inherits group"
    printf "    ${YELLOW}%-6s${RESET}  %-12s  %s\n" "t" "sticky (1xxx)" "Only owner can delete files in this dir"
    printf "    ${YELLOW}%-6s${RESET}  %-12s  %s\n" "S / T" "(uppercase)" "Same as above, but execute bit is NOT set"
    echo ""
    separator
    write_bold "  QUICK REFERENCE — Common octal permissions"
    separator
    echo ""
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "777" "rwxrwxrwx" "Full access for everyone (dangerous)"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "755" "rwxr-xr-x" "Owner full, others read+exec (dirs, scripts)"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "750" "rwxr-x---" "Owner full, group read+exec, others nothing"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "700" "rwx------" "Owner only (private dirs, e.g. ~/.ssh)"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "644" "rw-r--r--" "Owner read+write, others read (normal files)"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "600" "rw-------" "Owner only read+write (private keys, configs)"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "444" "r--r--r--" "Read-only for everyone"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "4755" "rwsr-xr-x" "Setuid + standard exec (e.g. /usr/bin/sudo)"
    printf "    ${GREEN}%-6s${RESET}  %-12s  %s\n" "1777" "rwxrwxrwt" "Sticky + full access (e.g. /tmp)"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════
main() {
    local debug=false
    local mode="detail"
    local targets=()
    local raw_flags=()
    local after_dashdash=false
    local known_modes="detail dir all size time type inode perm recur raw"

    # ── Parse arguments ──
    for arg in "$@"; do
        if [[ "$after_dashdash" == true ]]; then
            raw_flags+=("$arg")
            continue
        fi
        case "$arg" in
            --)         after_dashdash=true ;;
            --debug)    debug=true ;;
            --help|-h)  usage; exit 0 ;;
            *)
                # First non-flag arg matching a known mode → set mode
                if [[ " $known_modes " == *" $arg "* ]] && \
                   [[ ${#targets[@]} -eq 0 ]] && \
                   [[ "$mode" == "detail" ]]; then
                    mode="$arg"
                else
                    targets+=("$arg")
                fi
                ;;
        esac
    done

    # ── Build ls command array ──
    local ls_args=()

    if [[ "$mode" == "raw" ]]; then
        ls_args=("${raw_flags[@]}")
    else
        local flags
        flags=$(mode_to_flags "$mode")
        # Word-split flags intentionally (they're controlled single-token strings)
        # shellcheck disable=SC2206
        ls_args=($flags)
        if [[ ${#targets[@]} -gt 0 ]]; then
            ls_args+=("${targets[@]}")
        fi
    fi

    local cmd_display="ls ${ls_args[*]}"

    # ── Header ──
    echo ""
    separator
    write_bold "  lsh — ls helper"
    separator

    local mode_desc
    mode_desc=$(describe_mode "$mode")
    if [[ -n "$mode_desc" ]]; then
        echo ""
        label_colored "Mode:"    "$GREEN"    "$mode"
        label_colored "Purpose:" "$DARKGRAY" "$mode_desc"
    fi

    echo ""
    label_colored "Command:" "$YELLOW" "$cmd_display"

    # ── Debug mode: print command and exit ──
    if [[ "$debug" == true ]]; then
        echo ""
        write_warn "  ⚑ Debug mode — command not executed."
        write_info "  Copy and run it yourself:"
        echo ""
        write_ok "    $cmd_display"
        echo ""
        exit 0
    fi

    # ── Execute ls (colorless for parsing) ──
    local ls_output ls_exit=0
    ls_output=$(command ls --color=never "${ls_args[@]}" 2>&1) || ls_exit=$?

    if [[ $ls_exit -ne 0 ]]; then
        echo ""
        write_err "  ls failed (exit code $ls_exit):"
        write_err "  $ls_output"
        exit "$ls_exit"
    fi

    if [[ -z "$ls_output" ]]; then
        echo ""
        write_warn "  (no output — directory may be empty)"
        echo ""
        exit 0
    fi

    # ── Print raw output (with color) ──
    echo ""
    write_info "  ┌─ Raw output ──"
    echo ""
    command ls --color=always "${ls_args[@]}" 2>/dev/null | sed 's/^/    /'
    echo ""
    write_info "  └──"

    # ── Check if the output is in long (-l) format ──
    local has_long=false
    while IFS= read -r line; do
        [[ "$line" == total* ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" == *: ]] && continue  # recursive-mode directory headers
        # inode mode: line starts with a number, then permission string
        if [[ "$line" =~ ^[[:space:]]*[0-9]*[[:space:]]*[dlcbps\-][rwxsStT\-]{9} ]]; then
            has_long=true
        fi
        break
    done <<< "$ls_output"

    if [[ "$has_long" == false ]]; then
        echo ""
        write_warn "  Output is not in long format — no detailed breakdown available."
        write_dim "  Tip: modes like 'detail', 'all', 'dir' produce long-format output."
        echo ""
        exit 0
    fi

    # ── Print legend ──
    print_legend

    # ── Count entries ──
    local has_inode="no"
    [[ "$mode" == "inode" ]] && has_inode="yes"

    local entry_count=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == total* ]] && continue
        [[ "$line" == *: ]] && continue
        entry_count=$((entry_count + 1))
    done <<< "$ls_output"

    local max_explain=25
    local shown=0
    local truncated=false
    [[ $entry_count -gt $max_explain ]] && truncated=true

    # ── Explain each entry ──
    echo ""
    separator
    write_bold "  Detailed breakdown  (${entry_count} entries)"
    separator

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        # "total NNN" line
        if [[ "$line" == total* ]]; then
            local total_val="${line#total }"
            write_dim "  (disk blocks allocated: ${total_val})"
            continue
        fi

        # Recursive-mode directory header
        if [[ "$line" == *: ]]; then
            echo ""
            separator
            write_info_alt "  Directory: ${line%:}"
            separator
            continue
        fi

        # Truncate if too many
        if [[ "$truncated" == true ]] && [[ $shown -ge $max_explain ]]; then
            continue
        fi

        # Must look like ls -l output (optionally preceded by inode number)
        if [[ ! "$line" =~ [dlcbps\-][rwxsStT\-]{9} ]]; then
            continue
        fi

        explain_entry "$line" "$has_inode"
        shown=$((shown + 1))
    done <<< "$ls_output"

    if [[ "$truncated" == true ]]; then
        echo ""
        write_warn "  … showing first ${max_explain} of ${entry_count} entries."
        write_dim "  Narrow your path or pipe to a pager for the full listing."
    fi

    # ── Summary ──
    print_summary "$ls_output"
    echo ""
}

main "$@"
