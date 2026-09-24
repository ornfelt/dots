#!/usr/bin/env bash

# Lists git repos with work that isn't saved upstream yet: modified or untracked
# files, staged but uncommitted changes, and commits that aren't pushed.
#
#   git_check_repos.sh [-f] [-a] [DIR...]
#
#   DIR   where to look for repos, up to 4 levels deep (default: ~/.config)
#   -f    fetch every repo first, so the ahead counts are current
#         (without it they are as of the last fetch/pull/push)
#   -a    also list the clean repos
#
# Exits with 1 if any repo has something to commit or push.

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
DARKGRAY='\033[90m'

fetch=false
show_all=false
while getopts "fah" opt; do
    case $opt in
        f) fetch=true ;;
        a) show_all=true ;;
        *) sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -eq 0 ] && set -- "$HOME/.config"

# Prints one line per problem in the repo, nothing if it is clean
check_repo() {
    local repo=$1 n branch upstream ahead
    local -a out=()

    n=$(git -C "$repo" diff --name-only | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n modified file(s) not staged${RESET}")
    n=$(git -C "$repo" ls-files --others --exclude-standard | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n untracked file(s)${RESET}")
    n=$(git -C "$repo" diff --cached --name-only | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n staged file(s) not committed${RESET}")

    if [ -z "$(git -C "$repo" remote)" ]; then
        out+=("${RED}no remote, nothing is pushed anywhere${RESET}")
    else
        while read -r branch upstream; do
            if [ -n "$upstream" ] && git -C "$repo" rev-parse -q --verify "$upstream" >/dev/null; then
                ahead=$(git -C "$repo" rev-list --count "$upstream..$branch")
                ((ahead > 0)) && out+=("${RED}$branch: $ahead commit(s) not pushed to $upstream${RESET}")
            else
                # no upstream: commits that aren't on any remote branch
                ahead=$(git -C "$repo" rev-list --count "$branch" --not --remotes)
                ((ahead > 0)) && out+=("${RED}$branch: $ahead commit(s) not on any remote (no upstream)${RESET}")
            fi
        done < <(git -C "$repo" for-each-ref refs/heads --format='%(refname:short) %(upstream:short)')
    fi

    ((${#out[@]} > 0)) && printf '    %b\n' "${out[@]}"
}

dirty=0 total=0
for dir in "$@"; do
    [ -d "$dir" ] || { printf "%b[warn] %s is not a directory%b\n" "$YELLOW" "$dir" "$RESET"; continue; }
    while read -r gitdir; do
        repo=${gitdir%/.git}
        total=$((total + 1))
        if $fetch && [ -n "$(git -C "$repo" remote)" ]; then
            git -C "$repo" fetch --all --quiet 2>/dev/null ||
                printf "%b[warn] fetch failed for %s%b\n" "$YELLOW" "${repo/#$HOME/\~}" "$RESET"
        fi
        report=$(check_repo "$repo")
        name=${repo/#$HOME/\~}
        if [ -n "$report" ]; then
            dirty=$((dirty + 1))
            printf "%b%s%b %b(%s)%b\n%s\n" "$BLUE" "$name" "$RESET" "$DARKGRAY" \
                "$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" "$RESET" "$report"
        elif $show_all; then
            printf "%b%s%b %bclean%b\n" "$BLUE" "$name" "$RESET" "$GREEN" "$RESET"
        fi
    # repos up to 4 levels deep, so their .git up to 5
    done < <(find "$dir" -maxdepth 5 -name .git \( -type d -o -type f \) -prune 2>/dev/null | LC_ALL=C sort)
done

if ((total == 0)); then
    printf "%bNo git repos found in %s.%b\n" "$YELLOW" "$*" "$RESET"
elif ((dirty == 0)); then
    printf "%bAll %d repo(s) are clean and pushed.%b\n" "$GREEN" "$total" "$RESET"
else
    printf "\n%b%d of %d repo(s) have changes to commit or push.%b\n" "$YELLOW" "$dirty" "$total" "$RESET"
    $fetch || printf "%bAhead counts are as of the last fetch, use -f to fetch first.%b\n" "$DARKGRAY" "$RESET"
    exit 1
fi
