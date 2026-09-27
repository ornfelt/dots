#!/usr/bin/env bash

# Lists git repos with work that isn't saved upstream yet: modified or untracked
# files, staged but uncommitted changes, stashes, commits that aren't pushed
# (also ones made on a detached HEAD) and unfinished rebases, merges etc.
# Also lists branches that are behind their upstream (or, without one, the
# branch of the same name on the remote), i.e. that have something to pull.
#
#   git_check.sh [-n] [-a] [CATEGORY|DIR...]
#
#   CATEGORY  which of the known repos to check (case insensitive, can be combined)
#               all          everything (the default without CATEGORY and DIR)
#               wow          WoW servers, cores and tools
#               wm           window managers and bars
#               term         terminals (also: terminal)
#               dots         wm + term + dmenu, clipmenu and the dotfiles repos
#               other, x     everything that's in none of the categories above,
#                            plus any other repo found in ~/.config
#               config       every repo in ~/.config, whatever its category
#   DIR       where to look for repos, up to 4 levels deep
#   -n        don't fetch first (offline); the ahead/behind counts are then as of
#             the last fetch, and pushing to a URL (like git_push.sh does) doesn't
#             update them, so pushed commits can still show as not pushed
#   -a        also list the clean repos
#   -h, help  show this help
#
# Known repos that don't exist (yet) or aren't git repos are skipped with a warning.
# A fetch that takes longer than $GIT_CHECK_TIMEOUT seconds (default 60) is
# stopped and warned about.
# Exits with 1 if any repo has something to commit, push or pull, and with 2 on
# an unknown option, category or directory.

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
DARKGRAY='\033[90m'

usage() { sed -n '3,/^$/s/^# \{0,1\}//p' "$0"; }

fetch_timeout=${GIT_CHECK_TIMEOUT:-60}
code_root_dir=${code_root_dir:-$HOME}
my_notes_path=${my_notes_path:-$HOME/Documents/my_notes}
WM_REPOS=(
    "$HOME/.config/awesome"
    "$HOME/.config/dwm"
    "$HOME/.config/dwmblocks"
    "$code_root_dir/Code2/Rust/dwmr"
    "$code_root_dir/Code2/Rust/dwmblocksr"
    "$code_root_dir/Code2/C/dwmc"
    "$code_root_dir/Code2/C/dwmblocksc"
)
TERM_REPOS=(
    "$HOME/.config/st"
    "$code_root_dir/Code2/Rust/wezterm"
    "$code_root_dir/Code2/C/WecTerm"
)
# 'dots' is these plus WM_REPOS and TERM_REPOS
DOTS_REPOS=(
    "$HOME/.config/dmenu"
    "$HOME/.config/clipmenu"
    "$HOME/Downloads/dotfiles"
    "$HOME/Downloads/dots"
    "$HOME/Documents/windows_dots"
)
WOW_REPOS=(
    "$code_root_dir/Code2/Wow/tools/my_wow"
    "$code_root_dir/Code2/Rust/azerothcore-wotlk-rs"
    "$code_root_dir/Code2/C#/mangos-tbc-cs"
    "$code_root_dir/Code2/C#/vmangos_cs"
    "$code_root_dir/Code2/C#/azerothcore-wotlk-cs"
    "$code_root_dir/Code2/C++/AzerothCore-wotlk-with-NPCBots"
    "$code_root_dir/Code2/C++/Trinitycore-3.3.5-with-NPCBots"
    "$code_root_dir/Code2/C++/mangos-tbc"
    "$code_root_dir/Code2/C++/mangos-tbc/src/modules/PlayerBots"
    "$code_root_dir/Code2/C++/mangos-classic"
    "$code_root_dir/Code2/C++/mangos-classic/src/modules/PlayerBots"
    "$code_root_dir/Code2/C++/server"
    "$code_root_dir/Code2/C++/core"
    "$code_root_dir/Code2/C++/azerothcore-wotlk"
    "$code_root_dir/Code2/C++/azerothcore-wotlk-playerbots"
    "$code_root_dir/Code2/C++/azerothcore-wotlk-playerbots/modules/mod-playerbots"
)
# 'other' is these plus the repos in OTHER_DIRS that are in no other category
OTHER_REPOS=(
    "$code_root_dir/Code2/General/utils"
    "$code_root_dir/Code2/C#/my_cs"
    "$code_root_dir/Code2/C#/my_csharp"
    "$code_root_dir/Code2/Python/my_py"
    "$code_root_dir/Code2/General/gfx"
    "$code_root_dir/Code2/C++/space"
    "$code_root_dir/Code2/C++/my_cplusplus"
    "$code_root_dir/Code2/Python/wander_nodes_util"
    "$code_root_dir/Code2/C++/stk-code"
    "$code_root_dir/Code2/Sql/my_sql"
    "$code_root_dir/Code2/C/ioq3"
    "$my_notes_path"
)
OTHER_DIRS=(
    "$HOME/.config"
)

fetch=true
show_all=false
declare -A want=()
dirs=()
for arg; do
    case ${arg,,} in
        help|--help|-h) usage; exit 0 ;;
        all) want=([wm]=1 [term]=1 [dots]=1 [wow]=1 [other]=1) ;;
        wow|wm|dots|other) want[${arg,,}]=1 ;;
        term|terminal) want[term]=1 ;;
        x) want[other]=1 ;;
        config) dirs+=("$HOME/.config") ;;
        -*)
            opts=${arg#-}
            for ((i = 0; i < ${#opts}; i++)); do
                case ${opts:i:1} in
                    n) fetch=false ;;
                    a) show_all=true ;;
                    h|H) usage; exit 0 ;;
                    *) printf "unknown option: %s\n\n" "$arg" >&2; usage >&2; exit 2 ;;
                esac
            done
            ;;
        *)
            # absolute, so a repo reached through a relative path isn't listed twice
            dir=$(CDPATH='' cd -- "$arg" 2>/dev/null && pwd) || {
                printf "unknown category or directory: %s (see -h)\n" "$arg" >&2
                exit 2
            }
            dirs+=("$dir")
            ;;
    esac
done
((${#want[@]} == 0 && ${#dirs[@]} == 0)) && want=([wm]=1 [term]=1 [dots]=1 [wow]=1 [other]=1)
[ -n "${want[dots]}" ] && want[wm]=1 want[term]=1

warn() { printf "%b[warn] %s%b\n" "$YELLOW" "$1" "$RESET"; }

# Prints the repos in the dir, up to 4 levels deep (so their .git up to 5)
find_repos() {
    find "$1" -maxdepth 5 -name .git \( -type d -o -type f \) -prune -printf '%h\n' 2>/dev/null | LC_ALL=C sort
}

repos=()
declare -A seen=()
add_repo() {
    local repo=$1
    [ -n "${seen[$repo]}" ] && return
    seen[$repo]=1
    if [ ! -d "$repo" ]; then
        warn "${repo/#$HOME/\~} doesn't exist, skipping"
    elif [ ! -e "$repo/.git" ]; then
        warn "${repo/#$HOME/\~} is not a git repo, skipping"
    else
        repos+=("$repo")
    fi
}

for dir in "${dirs[@]}"; do
    while read -r repo; do add_repo "$repo"; done < <(find_repos "$dir")
done
[ -n "${want[wm]}" ] && for repo in "${WM_REPOS[@]}"; do add_repo "$repo"; done
[ -n "${want[term]}" ] && for repo in "${TERM_REPOS[@]}"; do add_repo "$repo"; done
[ -n "${want[dots]}" ] && for repo in "${DOTS_REPOS[@]}"; do add_repo "$repo"; done
[ -n "${want[wow]}" ] && for repo in "${WOW_REPOS[@]}"; do add_repo "$repo"; done
if [ -n "${want[other]}" ]; then
    for repo in "${OTHER_REPOS[@]}"; do add_repo "$repo"; done
    # repos of the other categories found in OTHER_DIRS aren't 'other', so mark them as seen
    for repo in "${WM_REPOS[@]}" "${TERM_REPOS[@]}" "${DOTS_REPOS[@]}" "${WOW_REPOS[@]}"; do
        seen[$repo]=1
    done
    for dir in "${OTHER_DIRS[@]}"; do
        while read -r repo; do add_repo "$repo"; done < <(find_repos "$dir")
    done
fi

# Prints one line per problem in the repo, nothing if it is clean
check_repo() {
    local repo=$1 n branch branch_ref upstream upstream_ref ahead behind remote gitdir op
    local -a out=()

    n=$(git -C "$repo" diff --name-only | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n modified file(s) not staged${RESET}")
    n=$(git -C "$repo" ls-files --others --exclude-standard | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n untracked file(s)${RESET}")
    n=$(git -C "$repo" diff --cached --name-only | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n staged file(s) not committed${RESET}")
    n=$(git -C "$repo" stash list | wc -l)
    ((n > 0)) && out+=("${YELLOW}$n stash(es)${RESET}")
    gitdir=$(git -C "$repo" rev-parse --absolute-git-dir)
    for op in rebase-merge:rebase rebase-apply:rebase/am MERGE_HEAD:merge \
        CHERRY_PICK_HEAD:cherry-pick REVERT_HEAD:revert BISECT_LOG:bisect; do
        [ -e "$gitdir/${op%%:*}" ] && out+=("${YELLOW}${op#*:} in progress${RESET}")
    done

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
        # commits made on a detached HEAD are on no branch, so the loop above misses them
        if ! git -C "$repo" symbolic-ref -q HEAD >/dev/null; then
            ahead=$(git -C "$repo" rev-list --count HEAD --not --branches --remotes)
            ((ahead > 0)) && out+=("${RED}detached HEAD: $ahead commit(s) on no branch or remote${RESET}")
        fi
    fi

    ((${#out[@]} > 0)) && printf '    %b\n' "${out[@]}"
}

# Prints the name of the env var holding the token for a GitHub remote URL,
# nothing if there isn't one (same mapping as git_push.sh)
token_var() {
    [[ $1 =~ github\.com[:/]([^/]+)/([^/]+)$ ]] || return
    [ "${BASH_REMATCH[2]%.git}" = my_notes ] && { echo GITHUB_TOKEN; return; }
    case ${BASH_REMATCH[1]} in
        ornfelt|sveawebpay|rewow) echo GITHUB_TOKEN ;;
        archornf) echo ALT_GITHUB_TOKEN ;;
    esac
}

# Fetches every remote of the repo, never prompting for credentials: private
# GitHub repos get the owner's token through a credential helper that reads it
# from the environment, so it doesn't show up in the process list
fetch_repo() {
    local repo=$1 remote var status failed=false timed_out=false
    for remote in $(git -C "$repo" remote); do
        var=$(token_var "$(git -C "$repo" remote get-url "$remote")")
        if [ -n "$var" ] && [ -n "${!var}" ]; then
            GIT_CHECK_TOKEN=${!var} GIT_TERMINAL_PROMPT=0 timeout "$fetch_timeout" git -C "$repo" \
                -c 'credential.https://github.com.helper=!f() { echo username=x-access-token; echo "password=$GIT_CHECK_TOKEN"; }; f' \
                fetch --quiet "$remote" 2>/dev/null
        else
            GIT_TERMINAL_PROMPT=0 timeout "$fetch_timeout" git -C "$repo" fetch --quiet "$remote" 2>/dev/null
        fi
        status=$?
        ((status == 124)) && timed_out=true
        ((status != 0)) && failed=true
    done
    if $timed_out; then
        warn "fetch timed out after ${fetch_timeout}s for ${repo/#$HOME/\~}"
    elif $failed; then
        warn "fetch failed for ${repo/#$HOME/\~}"
    fi
}

# Fetch all repos in parallel, so the ahead/behind counts match the remotes
if $fetch; then
    for repo in "${repos[@]}"; do
        fetch_repo "$repo" &
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
    printf "%bNo git repos found.%b\n" "$YELLOW" "$RESET"
elif ((dirty == 0)); then
    printf "%bAll %d repo(s) are clean and in sync.%b\n" "$GREEN" "$total" "$RESET"
else
    printf "\n%b%d of %d repo(s) have changes to commit, push or pull.%b\n" "$YELLOW" "$dirty" "$total" "$RESET"
    $fetch || printf "%bNot fetched (-n), ahead/behind counts are as of the last fetch.%b\n" "$DARKGRAY" "$RESET"
    exit 1
fi
