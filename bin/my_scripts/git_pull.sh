#!/usr/bin/env bash

function Usage() {
  cat <<EOF
Usage: $(basename "$0") [anything]
       $(basename "$0") help | --help | -h

Pull the current branch from GitHub using a token from the environment
(GITHUB_TOKEN, or ALT_GITHUB_TOKEN for archornf repos).

Arguments:
  (none)            Run the git pull.
  anything else     Print the git pull command instead of running it.
  -h, --help, help  Show this help.
EOF
}

# ${1,,}: lowercase, so HELP / --Help / -H also work
case "${1,,}" in
  help|--help|-h)
    Usage
    exit 0
    ;;
esac

OutputOnly=""
#if [[ "$1" == "--output-only" ]]; then
if [[ $# -gt 0 ]]; then
  OutputOnly="true"
fi

currentBranch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
pushUrl="$(git remote get-url --push origin 2>/dev/null)"

if [[ -z "$currentBranch" || -z "$pushUrl" ]]; then
  echo "Unable to determine current branch or remote URL."
  exit 1
fi

if [[ "$pushUrl" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
  repoOwner="${BASH_REMATCH[1]}"
  repoName="${BASH_REMATCH[2]}"
else
  echo "Could not extract owner/organization from remote URL."
  exit 1
fi

case "$repoOwner" in
  ornfelt|sveawebpay|rewow)
    tokenEnvVarName="GITHUB_TOKEN"
    ;;
  archornf)
    tokenEnvVarName="ALT_GITHUB_TOKEN"
    ;;
  *)
    echo "Unsupported repository owner: $repoOwner"
    exit 1
    ;;
esac

if [[ "$repoName" == "my_notes" ]]; then
    tokenEnvVarName="GITHUB_TOKEN"
fi

tokenValue="${!tokenEnvVarName}"

if [[ -z "$tokenValue" ]]; then
  echo "No token found for repository owner: $repoOwner"
  exit 1
fi

# Pulling from a URL instead of from origin doesn't update origin/<branch>, so
# git would say the branch is ahead by the pulled commits. Point it at what was
# fetched (FETCH_HEAD) after a successful pull, like pulling from origin does.
syncCommand="git update-ref refs/remotes/origin/${currentBranch} FETCH_HEAD"
# A URL pull never sets an upstream either, and without one git status doesn't
# compare the branch with origin at all. Set it once origin/<branch> exists.
if ! git rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
  syncCommand+=" && git branch --set-upstream-to=origin/${currentBranch}"
fi

pullCommandActual="git pull https://${tokenValue}@github.com/${repoOwner}/${repoName} ${currentBranch} && ${syncCommand}"
pullCommandDisplay="git pull https://\$${tokenEnvVarName}@github.com/${repoOwner}/${repoName} ${currentBranch} && ${syncCommand}"

if [[ -n "$OutputOnly" ]]; then
  echo "$pullCommandDisplay"
else
  #echo "Executing: $pullCommandActual"
  echo "Executing: $pullCommandDisplay"
  eval "$pullCommandActual"
fi

