#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./wow_wtf_update.sh tbc

# Set version from first argument or default to 'wotlk'
ver="${1:-wotlk}"
ver="${ver,,}"  # to lowercase

# Determine environment variable and subdirectory
case "$ver" in
  wotlk)
    wowEnv="wow_dir"
    addonSubDir="wotlk/WTF"
    ;;
  tbc)
    wowEnv="wow_tbc_dir"
    addonSubDir="tbc/WTF"
    ;;
  classic)
    wowEnv="wow_classic_dir"
    addonSubDir="classic/WTF"
    ;;
  *)
    echo "ERROR: Unknown version '$ver'. Valid values are wotlk, tbc, classic." >&2
    exit 1
    ;;
esac

# Resolve wowRoot from environment
wowRoot="${!wowEnv:-}"
if [[ -z "$wowRoot" ]]; then
  echo "ERROR: Environment variable '$wowEnv' not found." >&2
  exit 1
fi

# Resolve code_root_dir or fallback to $HOME
code_root_dir="${code_root_dir:-$HOME}"
destRoot="$code_root_dir/Code2/Wow/addons/wow_addons/$addonSubDir"

# Ensure WOW directory exists
if [[ ! -d "$wowRoot" ]]; then
  echo "ERROR: Wow directory not found: $wowRoot" >&2
  exit 1
fi
echo "Using ${wowEnv} ($ver): $wowRoot"

# Get and print user domain (Windows-style fallback for cross-platform safety)
userDomain="${USERDOMAIN:-$(hostname)}"
echo "User Domain: $userDomain"

# Build paths
sourceWtfDir="$wowRoot/WTF"
sourceConfig="$sourceWtfDir/Config.wtf"
sourceAccount="$sourceWtfDir/Account"

# Check that destination exists
if [[ ! -d "$destRoot" ]]; then
  echo "ERROR: Destination directory not found: $destRoot" >&2
  exit 1
fi

# Copy Config.wtf with domain prefix
destConfig="$destRoot/${userDomain}_Config.wtf"
if [[ ! -f "$sourceConfig" ]]; then
  echo "ERROR: Source Config.wtf not found: $sourceConfig" >&2
  exit 1
fi
cp -f "$sourceConfig" "$destConfig"
echo "Copied Config.wtf -> $destConfig"

# Replace the Account folder
destAccount="$destRoot/Account"
if [[ -d "$sourceAccount" ]]; then
  if [[ -d "$destAccount" ]]; then
    rm -rf "$destAccount"
    echo "Removed existing Account folder at $destAccount"
  fi
  cp -r "$sourceAccount" "$destRoot"
  echo "Copied Account folder -> $destAccount"
else
  echo "WARNING: Source Account folder not found: $sourceAccount"
fi

# Change to destination directory
cd "$destRoot"
echo "Done."

