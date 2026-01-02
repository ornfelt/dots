#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./wow_wtf_fix.sh classic
# ./wow_wtf_fix.sh tbc
# ./wow_wtf_fix.sh wotlk

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

# Resolve wowRoot from environment variable
wowRoot="${!wowEnv:-}"
if [[ -z "$wowRoot" ]]; then
  echo "ERROR: Environment variable '$wowEnv' not found." >&2
  exit 1
fi

# Override with hdd path (to effectively update files on hdd)
USE_HDD=false
#USE_HDD=true

# Note: if needed, also sync Config.wtf to hdd via below commands:
# cp $wow_dir/WTF/Config.wtf /media2/2024/wow/WTF/
# cp $wow_tbc_dir/WTF/Config.wtf /media2/2024/wow_tbc/WTF/
# cp $wow_classic_dir/WTF/Config.wtf /media2/2024/wow_classic/WTF/

if [[ "$USE_HDD" == true ]]; then
    case "$ver" in
        wotlk)   wowRoot="/media2/2024/wow" ;;
        tbc)     wowRoot="/media2/2024/wow_tbc" ;;
        classic) wowRoot="/media2/2024/wow_classic" ;;
    esac
fi

# Debug
echo "Using wowRoot: $wowRoot"

# Resolve code_root_dir or fallback to $HOME
code_root_dir="${code_root_dir:-$HOME}"
destRoot="$code_root_dir/Code2/Wow/addons/wow_addons/$addonSubDir"

# Ensure both paths exist
if [[ ! -d "$destRoot" ]]; then
  echo "ERROR: Source addon directory not found: $destRoot" >&2
  exit 1
fi

if [[ ! -d "$wowRoot" ]]; then
  echo "ERROR: WoW directory not found: $wowRoot" >&2
  exit 1
fi

echo "Copying Account folder FROM $destRoot TO $wowRoot"

# Paths
sourceAccount="$destRoot/Account"
targetWtfDir="$wowRoot/WTF"
targetAccount="$targetWtfDir/Account"

# Ensure WTF folder exists at destination
if [[ ! -d "$targetWtfDir" ]]; then
  echo "WTF directory not found at $targetWtfDir, creating it..."
  mkdir -p "$targetWtfDir"
fi

# Replace Account folder
if [[ -d "$sourceAccount" ]]; then
  if [[ -d "$targetAccount" ]]; then
    rm -rf "$targetAccount"
    echo "Removed existing Account folder at $targetAccount"
  fi
  cp -r "$sourceAccount" "$targetWtfDir"
  echo "Copied Account folder -> $targetAccount"
else
  echo "WARNING: Source Account folder not found: $sourceAccount"
fi

echo "Done."

