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

commands=()

function AddUpstreamIfMissing() {
  local upstreamUrl="$1"
  local existingUpstream
  existingUpstream="$(git remote get-url upstream 2>/dev/null)"
  if [[ -z "$existingUpstream" ]]; then
    commands+=("git remote add upstream $upstreamUrl")
    echo "upstream url did NOT exist... Added: $upstreamUrl"
  else
    echo "upstream url already added: $upstreamUrl"
  fi
}

if [[ "$repoOwner" == "ornfelt" ]]; then
  #case "$repoName" in
  case "${repoName%.git}" in
    "dwm")
      AddUpstreamIfMissing "https://git.suckless.org/dwm"
      commands+=('git fetch --all')
      commands+=('git diff upstream/master...master > diff_upstream.diff')
      commands+=('git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
      commands+=('git diff origin/new -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_new.diff')
      commands+=('git add -A')
      commands+=('git commit -m "update diff files"')
      ;;
    "dmenu")
      AddUpstreamIfMissing "https://git.suckless.org/dmenu"
      commands+=('git fetch --all')
      commands+=('git diff upstream/master...master > diff_upstream.diff')
      commands+=('git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
      commands+=('git add -A')
      commands+=('git commit -m "update diff files"')
      ;;
    "st")
      AddUpstreamIfMissing "https://git.suckless.org/st"
      commands+=('git fetch --all')
      commands+=('git diff upstream/master...master > diff_upstream.diff')
      commands+=('git diff bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
      commands+=('git add -A')
      commands+=('git commit -m "update diff files"')
      ;;
    "dwmblocks")
      AddUpstreamIfMissing "https://github.com/torrinfail/dwmblocks"
      commands+=('git fetch --all')
      commands+=('git diff upstream/master...master > diff_upstream.diff')
      commands+=('git add -A')
      commands+=('git commit -m "update diff files"')
      ;;
    "awsm")
      AddUpstreamIfMissing "https://github.com/lcpz/awesome-copycats"
      commands+=('git fetch --all')
      commands+=('git diff upstream/master...master > diff_upstream.diff')
      commands+=('git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff')
      commands+=('git diff origin/tarneaux -- . ":(exclude)*.diff" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_tarneaux.diff')
      commands+=('git add -A')
      commands+=('git commit -m "update diff files"')
      ;;
    *)
      # Nothing
      ;;
  esac
fi

if [[ "${repoName%.git}" == "AzerothCore-wotlk-with-NPCBots" ]]; then
  AddUpstreamIfMissing "https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots"
  commands+=('git fetch upstream')
  if [[ "$currentBranch" == "linux" ]]; then
    commands+=('git diff upstream/npcbots_3.3.5...linux -- . ":(exclude)*.conf" ":(exclude)*.patch" ":(exclude)*.diffx" | tee acore.diffx')
  else
    commands+=('git diff upstream/npcbots_3.3.5...npcbots_3.3.5 -- . ":(exclude)*.conf" ":(exclude)*.patch" ":(exclude)*.diffx" | tee acore.diffx')
  fi
    commands+=('git add -A')
    commands+=('git commit -m "update diff files"')
fi

if [[ "${repoName%.git}" == "TrinityCore-3.3.5-with-NPCBots" ]]; then
  AddUpstreamIfMissing "https://github.com/trickerer/TrinityCore-3.3.5-with-NPCBots"
  commands+=('git fetch upstream')
  commands+=('git diff upstream/npcbots_3.3.5...npcbots_3.3.5 -- . ":(exclude)*.conf" ":(exclude)*.patch" ":(exclude)*.diffx" | tee tcore.diffx')
  commands+=('git add -A')
  commands+=('git commit -m "update diff files"')
fi

if [[ -n "$OutputOnly" ]]; then
  for cmd in "${commands[@]}"; do
    echo "$cmd"
  done
else
  for cmd in "${commands[@]}"; do
    echo "Executing: $cmd"
    eval "$cmd"
  done
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

if [[ "${repoName%.git}" == "my_notes" ]]; then
    tokenEnvVarName="GITHUB_TOKEN"
fi

tokenValue="${!tokenEnvVarName}"

if [[ -z "$tokenValue" ]]; then
  echo "No token found for repository owner: $repoOwner"
  exit 1
fi

pushCommandActual="git push https://${tokenValue}@github.com/${repoOwner}/${repoName} ${currentBranch}"
pushCommandDisplay="git push https://\$${tokenEnvVarName}@github.com/${repoOwner}/${repoName} ${currentBranch}"

if [[ -n "$OutputOnly" ]]; then
  echo "$pushCommandDisplay"
else
  #echo "Executing: $pushCommandActual"
  echo "Executing: $pushCommandDisplay"
  eval "$pushCommandActual"
fi

