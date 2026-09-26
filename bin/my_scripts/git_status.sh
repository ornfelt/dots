#!/usr/bin/env bash

OutputOnly=false

function Usage() {
  cat <<EOF
Usage: $(basename "$0") [--output-only]
       $(basename "$0") help | --help | -h

Show git status for the current branch and check it against the branch on
GitHub (origin), which git status alone doesn't do. It can suggest:
  - the update-ref sync command git_push.sh runs, when origin/<branch> is out
    of date because the branch was pushed to a URL
  - a fetch, when origin has commits that aren't fetched yet
  - a fast-forward merge or a rebase, when the branch is behind origin, or
    behind the local branch it tracks (like main)
  - git_push.sh, when there are commits that aren't pushed
Each command is printed, and run only if you answer y or yes. After it has
run, the branch is checked again and the next command (if any) is suggested.

Talks to GitHub with a token from the environment (GITHUB_TOKEN, or
ALT_GITHUB_TOKEN for archornf repos) like git_push.sh, or through the origin
remote as-is if there is no token.

Options:
  -o, --output-only  Print the first suggested command without asking to run it.
  -h, --help, help   Show this help.
EOF
}

# ${1,,}: lowercase, so HELP / --Help / -H also work
case "${1,,}" in
  help|--help|-h)
    Usage
    exit 0
    ;;
esac

for arg in "$@"; do
  case "$arg" in
    -o|--output-only) OutputOnly=true ;;
    *)
      echo "Unknown argument: $arg" >&2
      Usage >&2
      exit 1
      ;;
  esac
done

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'

# Never hang on a username/password prompt, fail instead
export GIT_TERMINAL_PROMPT=0

git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not in a git repository."; exit 1; }

git -c color.status=always status --short --branch

currentBranch="$(git symbolic-ref --short -q HEAD)"
if [[ -z "$currentBranch" ]]; then
  echo "HEAD is detached, no branch to check."
  exit 1
fi

originUrl="$(git remote get-url origin 2>/dev/null)"
if [[ -z "$originUrl" ]]; then
  echo "No origin remote, nothing to compare with."
  exit 1
fi

# Where to reach origin: through a token URL when there is a token for it (the
# same owners and tokens as git_push.sh), otherwise through the remote itself
remoteUrl="origin"
remoteUrlDisplay="origin"
if [[ "$originUrl" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
  repoOwner="${BASH_REMATCH[1]}"
  repoName="${BASH_REMATCH[2]}"
  case "$repoOwner" in
    ornfelt|sveawebpay|rewow) tokenEnvVarName="GITHUB_TOKEN" ;;
    archornf) tokenEnvVarName="ALT_GITHUB_TOKEN" ;;
  esac
  [[ "${repoName%.git}" == "my_notes" ]] && tokenEnvVarName="GITHUB_TOKEN"
  if [[ -n "$tokenEnvVarName" && -n "${!tokenEnvVarName}" ]]; then
    remoteUrl="https://${!tokenEnvVarName}@github.com/${repoOwner}/${repoName}"
    remoteUrlDisplay="https://\$${tokenEnvVarName}@github.com/${repoOwner}/${repoName}"
  fi
fi

if [[ "$remoteUrl" == "origin" ]]; then
  fetchCommandActual="git fetch origin"
  fetchCommandDisplay="git fetch origin"
else
  # A URL fetch only updates origin/* with an explicit refspec
  fetchCommandActual="git fetch $remoteUrl '+refs/heads/*:refs/remotes/origin/*'"
  fetchCommandDisplay="git fetch $remoteUrlDisplay '+refs/heads/*:refs/remotes/origin/*'"
fi

pushScript="$(dirname "$(readlink -f "$0")")/git_push.sh"

# Set by NextStep: why, and the command to suggest (display has no token in it)
stepReason=""
stepDisplay=""
stepActual=""

function SetStep() {
  stepReason="$1"
  stepDisplay="$2"
  stepActual="${3:-$2}"
}

# Merge when the branch has nothing of its own, otherwise rebase its commits
# on top. --autostash so uncommitted changes don't block either.
function SetCatchUpStep() {
  local reason="$1" target="$2" ahead="$3"
  if ((ahead == 0)); then
    SetStep "$reason." "git merge --ff-only --autostash $target"
  else
    SetStep "$reason, and has $ahead commit(s) of its own." "git rebase --autostash $target"
  fi
}

remoteChecked=false
remoteMissing=false

# Finds the next thing to do for the current branch. Returns 0 and sets the
# step if there is one, 1 if the branch is in sync.
function NextStep() {
  local branchRef="refs/heads/$currentBranch"
  local branchSha upstreamRef upstream remoteBranch trackingRef trackingSha
  local lsOutput remoteSha ahead behind

  branchSha="$(git rev-parse "$branchRef")"
  upstreamRef="$(git for-each-ref --format='%(upstream)' "$branchRef")"
  upstream="$(git for-each-ref --format='%(upstream:short)' "$branchRef")"
  if [[ "$upstreamRef" == refs/remotes/origin/* ]]; then
    remoteBranch="${upstreamRef#refs/remotes/origin/}"
  else
    remoteBranch="$currentBranch"
  fi
  trackingRef="refs/remotes/origin/$remoteBranch"
  trackingSha="$(git rev-parse -q --verify "$trackingRef")"

  # 1. Does origin/<branch> match the branch on GitHub? Asked once, after a
  #    sync or fetch it does.
  if ! $remoteChecked; then
    remoteChecked=true
    if lsOutput="$(git ls-remote "$remoteUrl" "refs/heads/$remoteBranch" 2>/dev/null)"; then
      remoteSha="${lsOutput%%[[:space:]]*}"
      if [[ -z "$remoteSha" ]]; then
        # suggested below, after catching up with a local upstream
        remoteMissing=true
      elif [[ "$remoteSha" != "$trackingSha" ]]; then
        if [[ "$remoteSha" == "$branchSha" ]]; then
          SetStep "$remoteBranch on origin is already at your $currentBranch, only origin/$remoteBranch is out of date (pushed to a URL?)." \
            "git update-ref $trackingRef $branchRef"
        else
          SetStep "origin has changes on $remoteBranch that aren't fetched yet." "$fetchCommandDisplay" "$fetchCommandActual"
        fi
        return 0
      fi
    else
      echo -e "${YELLOW}Couldn't reach origin, comparing with origin/$remoteBranch as of the last fetch.${RESET}"
    fi
  fi

  # 2. Behind the branch it tracks, when that isn't on origin (like local main)
  if [[ -n "$upstreamRef" && "$upstreamRef" != refs/remotes/origin/* ]] &&
    git rev-parse -q --verify "$upstreamRef" >/dev/null; then
    read -r ahead behind < <(git rev-list --left-right --count "$branchRef...$upstreamRef")
    if ((behind > 0)); then
      SetCatchUpStep "$currentBranch is $behind commit(s) behind $upstream, which it tracks" "$upstream" "$ahead"
      return 0
    fi
  fi

  # 3. Behind or ahead of the branch on origin
  if $remoteMissing; then
    remoteMissing=false
    SetStep "$remoteBranch doesn't exist on origin yet." "$pushScript"
    return 0
  elif [[ -z "$trackingSha" ]]; then
    echo "No origin/$remoteBranch to compare with."
    return 1
  fi
  read -r ahead behind < <(git rev-list --left-right --count "$branchRef...$trackingRef")
  if ((behind > 0)); then
    SetCatchUpStep "$currentBranch is $behind commit(s) behind origin/$remoteBranch" "origin/$remoteBranch" "$ahead"
    return 0
  elif ((ahead > 0)); then
    SetStep "$currentBranch has $ahead commit(s) that aren't pushed to origin/$remoteBranch." "$pushScript"
    return 0
  fi

  echo -e "${GREEN}$currentBranch is in sync with origin/$remoteBranch.${RESET}"
  return 1
}

# Bounded, in case a command succeeds without changing anything
for _ in 1 2 3 4 5 6; do
  NextStep || exit 0

  echo
  echo -e "${YELLOW}${stepReason}${RESET}"
  echo -e "  ${BOLD}${stepDisplay/#$HOME/\~}${RESET}"
  [[ "$OutputOnly" == "true" ]] && exit 1

  read -r -p "Run it? [y/N] " answer </dev/tty || exit 1
  case "${answer,,}" in
    y|yes) ;;
    *) exit 1 ;;
  esac

  echo "Executing: $stepDisplay"
  if ! eval "$stepActual"; then
    echo "Command failed."
    exit 1
  fi
done
