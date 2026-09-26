#!/usr/bin/env bash

# Lists git repos with work that isn't saved upstream yet: modified or untracked
# files, staged but uncommitted changes, and commits that aren't pushed.
# Also lists branches that are behind their upstream (or, without one, the
# branch of the same name on the remote), i.e. that have something to pull.
#
#   git_check_repos.sh [-n] [-a] [DIR...]
#
#   DIR   where to look for repos, up to 4 levels deep (default: ~/.config
#         and the dwm repos under $code_root_dir/Code2, see DEFAULT_DIRS)
#   -n    don't fetch first (offline); the ahead/behind counts are then as of
#         the last fetch, and pushing to a URL (like git_push.sh does) doesn't
#         update them, so pushed commits can still show as not pushed
#   -a    also list the clean repos
#
# Exits with 1 if any repo has something to commit, push or pull.

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'

fetch=true
show_all=false
while getopts "nah" opt; do
    case $opt in
        n) fetch=false ;;
        a) show_all=true ;;
        *) sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done
shift $((OPTIND - 1))

code_root_dir=${code_root_dir:-$HOME}
DEFAULT_DIRS=(
    "$HOME/.config"
    "$code_root_dir/Code2/Rust/dwmr"
    "$code_root_dir/Code2/Rust/dwmblocksr"
    "$code_root_dir/Code2/C/dwmc"
    "$code_root_dir/Code2/C/dwmblocksc"
)
[ $# -eq 0 ] && set -- "${DEFAULT_DIRS[@]}"

# Prints one line per problem in the repo, nothing if it is clean
check_repo() {
    local repo=$1 n branch branch_ref upstream upstream_ref ahead behind remote
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
        while read -r branch upstream_ref upstream; do
            branch_ref=refs/heads/$branch
            if [ -n "$upstream" ] && git -C "$repo" rev-parse -q --verify "$upstream_ref" >/dev/null; then
                read -r ahead behind < <(git -C "$repo" rev-list --left-right --count "$branch_ref...$upstream_ref")
                if [[ $upstream_ref == refs/remotes/* ]]; then
                    ((ahead > 0)) && out+=("${RED}$branch: $ahead commit(s) not pushed to $upstream${RESET}")
                else
                    # tracks a local branch, so being ahead of it says nothing about the remotes
                    ahead=$(git -C "$repo" rev-list --count "$branch_ref" --not --remotes)
                    ((ahead > 0)) && out+=("${RED}$branch: $ahead commit(s) not on any remote (tracks local $upstream)${RESET}")
                fi
            else
                # no upstream: commits that aren't on any remote branch
                ahead=$(git -C "$repo" rev-list --count "$branch_ref" --not --remotes)
                ((ahead > 0)) && out+=("${RED}$branch: $ahead commit(s) not on any remote (no upstream)${RESET}")
                # and whether the branch of the same name on the remote (origin first) has moved on
                upstream='' behind=0
                for remote in origin $(git -C "$repo" remote); do
                    if git -C "$repo" rev-parse -q --verify "refs/remotes/$remote/$branch" >/dev/null; then
                        upstream=$remote/$branch
                        behind=$(git -C "$repo" rev-list --count "$branch_ref..refs/remotes/$upstream")
                        break
                    fi
                done
            fi
            ((behind > 0)) && out+=("${MAGENTA}$branch: $behind commit(s) behind $upstream${RESET}")
        done < <(git -C "$repo" for-each-ref refs/heads --format='%(refname:short) %(upstream) %(upstream:short)')
    fi

    ((${#out[@]} > 0)) && printf '    %b\n' "${out[@]}"
}

repos=()
for dir in "$@"; do
    [ -d "$dir" ] || { printf "%b[warn] %s is not a directory%b\n" "$YELLOW" "$dir" "$RESET"; continue; }
    # repos up to 4 levels deep, so their .git up to 5
    while read -r gitdir; do
        repos+=("${gitdir%/.git}")
    done < <(find "$dir" -maxdepth 5 -name .git \( -type d -o -type f \) -prune 2>/dev/null | LC_ALL=C sort)
done

# Fetch all repos in parallel, so the ahead/behind counts match the remotes
if $fetch; then
    for repo in "${repos[@]}"; do
        [ -n "$(git -C "$repo" remote)" ] || continue
        (git -C "$repo" fetch --all --quiet 2>/dev/null ||
            printf "%b[warn] fetch failed for %s%b\n" "$YELLOW" "${repo/#$HOME/\~}" "$RESET") &
    done
    wait
fi

dirty=0 total=0
for repo in "${repos[@]}"; do
    total=$((total + 1))
    report=$(check_repo "$repo")
    name=${repo/#$HOME/\~}
    if [ -n "$report" ]; then
        dirty=$((dirty + 1))
        printf "%b%s%b %b(%s)%b\n%s\n" "$BLUE" "$name" "$RESET" "$DARKGRAY" \
            "$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" "$RESET" "$report"
    elif $show_all; then
        printf "%b%s%b %bclean%b\n" "$BLUE" "$name" "$RESET" "$GREEN" "$RESET"
    fi
done

if ((total == 0)); then
    printf "%bNo git repos found in %s.%b\n" "$YELLOW" "$*" "$RESET"
elif ((dirty == 0)); then
    printf "%bAll %d repo(s) are clean and in sync.%b\n" "$GREEN" "$total" "$RESET"
else
    printf "\n%b%d of %d repo(s) have changes to commit, push or pull.%b\n" "$YELLOW" "$dirty" "$total" "$RESET"
    $fetch || printf "%bNot fetched (-n), ahead/behind counts are as of the last fetch.%b\n" "$DARKGRAY" "$RESET"
    exit 1
fi
