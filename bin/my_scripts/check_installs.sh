#!/usr/bin/env bash

# Tells whether the installed dwm, dwmc, dwmr, their status bars and dmenu
# are up to date with their sources, i.e. whether `sudo make install` has
# anything to do.
#
#   check_installs.sh [-d] [NAME...]
#
#   NAME  programs to check (default: all in PROGRAMS below)
#   -d    detailed: build the current sources in a copy, `make install` it
#         into a temp dir as you and compare every file it would install
#         (programs, man pages) byte for byte with the installed one. Exact,
#         and new or deleted source files count by themselves; dwmr and
#         dwmblocksr take a while (their cargo target dirs are cached in
#         ~/.cache/check_installs)
#   (without -d) quick: compares the date of the newest file git sees in the
#         repo (tracked or untracked, not ignored) with the installed
#         program's. An edited and reverted file, or a checkout, still shows
#         as newer; a deleted file doesn't show at all
#
# Exits with 1 if any program is out of date, not installed or doesn't build.

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
DARKGRAY='\033[90m'

detailed=false
while getopts "dh" opt; do
    case $opt in
        d) detailed=true ;;
        *) sed -n '3,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done
shift $((OPTIND - 1))

code_root_dir=${code_root_dir:-$HOME}
# name (the installed program), source dir, then the files the build reads
# that git doesn't see: relative to the source dir (gitignored there, copied
# along with -d) or absolute (outside it; the Makefile reads them itself)
PROGRAMS=(
    "dwm        $HOME/.config/dwm"
    "dwmc       $code_root_dir/Code2/C/dwmc $HOME/.config/dwmc/config.h"
    "dwmr       $code_root_dir/Code2/Rust/dwmr"
    "dwmblocks  $HOME/.config/dwmblocks blocks.h"
    "dwmblocksc $code_root_dir/Code2/C/dwmblocksc $HOME/.config/dwmblocksc/blocks.h"
    "dwmblocksr $code_root_dir/Code2/Rust/dwmblocksr"
    "dmenu      $HOME/.config/dmenu"
)
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/check_installs

[ "$EUID" -eq 0 ] && { printf "%bRun this as yourself, not root: the builds use your configs and toolchains.%b\n" "$RED" "$RESET"; exit 2; }

tilde() { echo "${1/#$HOME/\~}"; }
date_of() { date -d "@$1" '+%Y-%m-%d %H:%M'; }

# Files git sees in dir (tracked, or untracked and not ignored) that exist,
# NUL separated, relative to dir
git_files() {
    local dir=$1 f
    while IFS= read -r -d '' f; do
        [ -e "$dir/$f" ] || [ -L "$dir/$f" ] && printf '%s\0' "$f"
    done < <(git -C "$dir" ls-files -co --exclude-standard -z)
}

# The installed program that PATH finds (what .xinitrc and the WMs run), and
# a note for any other copy that PATH hides
installed_note() {
    local name=$1 first p
    first=$(realpath -e "$2")
    while read -r p; do
        [ "$p" != "$first" ] && printf "    %balso %s, not used (%s comes first in PATH)%b\n" "$DARKGRAY" "$(tilde "$p")" "$(tilde "$2")" "$RESET"
    done < <(which -a "$name" 2>/dev/null | xargs -r -d '\n' realpath -e 2>/dev/null | awk '!seen[$0]++')
}

# Quick: newest source file vs the installed program. Prints the report,
# returns 1 if out of date
check_quick() {
    local name=$1 dir=$2 bin=$3 extra newest=0 newest_file t f
    shift 3
    local -a files=()
    while IFS= read -r -d '' f; do files+=("$dir/$f"); done < <(git_files "$dir")
    for extra; do
        [[ $extra == /* ]] && files+=("$extra") || files+=("$dir/$extra")
    done
    while read -r t f; do
        if ((t > newest)); then newest=$t newest_file=$f; fi
    done < <(stat -c '%Y %n' -- "${files[@]}" 2>/dev/null)
    t=$(stat -c %Y "$bin")
    if ((newest > t)); then
        printf "    %bout of date: %s changed %s, installed %s%b\n" "$RED" \
            "$(tilde "$newest_file")" "$(date_of "$newest")" "$(date_of "$t")" "$RESET"
        return 1
    fi
    printf "    %bup to date: installed %s, newest source %s%b\n" "$GREEN" "$(date_of "$t")" "$(date_of "$newest")" "$RESET"
}

# Detailed: build a copy of the sources, `make install` it into a temp dir
# and compare each file with the installed one. Prints the report, returns 1
# if anything differs or the build fails
check_detailed() {
    local name=$1 dir=$2 work=$CACHE/$1 extra f live n=0
    shift 2
    local -a files=() differ=()
    rm -rf "$work/src" "$work/dest" && mkdir -p "$work/src" "$work/dest" || return 1
    while IFS= read -r -d '' f; do files+=("$f"); done < <(git_files "$dir")
    for extra; do [[ $extra == /* ]] || files+=("$extra"); done
    (cd "$dir" && cp -P --parents -t "$work/src" -- "${files[@]}") || return 1
    # cargo: keep the target dir between runs, so only the crate itself is rebuilt
    if [ -e "$work/src/Cargo.toml" ]; then
        mkdir -p "$work/target"
        ln -s "$work/target" "$work/src/target"
    fi
    if ! make -C "$work/src" install DESTDIR="$work/dest" >"$work/build.log" 2>&1; then
        printf "    %bbuild failed, see %s%b\n" "$RED" "$(tilde "$work/build.log")" "$RESET"
        return 1
    fi
    while IFS= read -r -d '' f; do
        live=${f#"$work/dest"}
        n=$((n + 1))
        if [ ! -e "$live" ]; then
            differ+=("${RED}not installed: $live${RESET}")
        elif ! cmp -s "$f" "$live"; then
            differ+=("${RED}differs: $live${RESET}")
        fi
    done < <(find "$work/dest" \( -type f -o -type l \) -print0 | sort -z)
    if ((${#differ[@]} > 0)); then
        printf '    %b\n' "${differ[@]}"
        return 1
    fi
    printf "    %bup to date: all %d installed file(s) match a build of the sources%b\n" "$GREEN" "$n" "$RESET"
}

# Checks one program, printing its report
check() {
    local name=$1 dir=$2 bin
    shift 2
    printf "%b%s%b %b%s%b\n" "$BLUE" "$name" "$RESET" "$DARKGRAY" "$(tilde "$dir")" "$RESET"
    if [ ! -d "$dir" ]; then
        printf "    %bno source dir%b\n" "$YELLOW" "$RESET"
        return 1
    fi
    if ! bin=$(command -v "$name"); then
        printf "    %bnot installed%b\n" "$RED" "$RESET"
        return 1
    fi
    installed_note "$name" "$bin"
    if $detailed; then
        check_detailed "$name" "$dir" "$@"
    else
        check_quick "$name" "$dir" "$bin" "$@"
    fi
}

selected=()
for entry in "${PROGRAMS[@]}"; do
    read -r name _ <<<"$entry"
    if [ $# -eq 0 ] || [[ " $* " == *" $name "* ]]; then
        selected+=("$entry")
    fi
done
for want; do
    [[ " ${PROGRAMS[*]} " == *" $want "* ]] || printf "%b[warn] %s is not in PROGRAMS, skipping%b\n" "$YELLOW" "$want" "$RESET"
done
((${#selected[@]} == 0)) && exit 2

# Run the checks in parallel (the cargo builds dominate with -d) and print
# the reports in order
mkdir -p "$CACHE"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
$detailed && printf "%bBuilding %d program(s)...%b\n" "$DARKGRAY" "${#selected[@]}" "$RESET"
for i in "${!selected[@]}"; do
    # shellcheck disable=SC2086  # the entry is split into its fields on purpose
    { check ${selected[$i]} >"$tmp/$i" 2>&1; echo $? >"$tmp/$i.rc"; } &
done
wait

outdated=()
for i in "${!selected[@]}"; do
    cat "$tmp/$i"
    read -r name dir _ <<<"${selected[$i]}"
    [ "$(cat "$tmp/$i.rc")" = 0 ] || outdated+=("$dir")
done

if ((${#outdated[@]} == 0)); then
    printf "\n%bAll %d program(s) are up to date.%b\n" "$GREEN" "${#selected[@]}" "$RESET"
else
    printf "\n%b%d of %d program(s) need reinstalling:%b\n" "$YELLOW" "${#outdated[@]}" "${#selected[@]}" "$RESET"
    for dir in "${outdated[@]}"; do
        printf "    cd %s && sudo make install\n" "$(tilde "$dir")"
    done
    $detailed || printf "%bBy date only; -d builds and compares the files.%b\n" "$DARKGRAY" "$RESET"
    exit 1
fi
