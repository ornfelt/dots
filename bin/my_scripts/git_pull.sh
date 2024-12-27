#!/usr/bin/env bash

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

pullCommandActual="git pull https://${tokenValue}@github.com/${repoOwner}/${repoName} ${currentBranch}"
pullCommandDisplay="git pull https://\$${tokenEnvVarName}@github.com/${repoOwner}/${repoName} ${currentBranch}"

if [[ -n "$OutputOnly" ]]; then
  echo "$pullCommandDisplay"
else
  #echo "Executing: $pullCommandActual"
  echo "Executing: $pullCommandDisplay"
  eval "$pullCommandActual"
fi

