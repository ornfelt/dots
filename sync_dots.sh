#!/bin/sh

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'

# Logging helpers
# %b makes printf interpret \033 escapes properly
log_ok()    { printf "%b[ok]%b %b\n"   "$CYAN"   "$RESET" "$*"; }
log_warn()  { printf "%b[warn]%b %b\n" "$YELLOW" "$RESET" "$*"; }
log_err()   { printf "%b[err]%b %b\n"  "$RED"    "$RESET" "$*"; }
log_info()  { printf "%b[i]%b %b\n"    "$DARKGRAY" "$RESET" "$*"; }
log_step()  { printf "\n%b==>%b %b\n"  "$BLUE"   "$RESET" "$*"; }
log_sep()   { log_info "--------------------------------------------------------"; }

say()       { printf "%b\n" "$*"; }
die()       { log_err "$*"; exit 1; }

TARGET_DIR="$HOME/Downloads/dots"

# bail check
#if [ ! -d "$TARGET_DIR" ]; then
#  echo "Target directory does not exist: $TARGET_DIR"
#  exit 1
#fi
[ -d "$TARGET_DIR" ] || die "Target directory does not exist: $TARGET_DIR"

log_step "Cleaning target dir (keeping .git)"
# Remove all files and subdirs except for ".git" in the target dir
find "$TARGET_DIR" -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +

log_step "Copying current dir -> $TARGET_DIR (excluding .git)"
# Copy all files and subdirs except for ".git" from current dir to target dir
find . -mindepth 1 -maxdepth 1 ! -name ".git" -exec cp -r {} "$TARGET_DIR" \;

#cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }
cd "$TARGET_DIR" || die "Failed to change directory to $TARGET_DIR"

sleep 0.5

log_step "git status"
git status

$SHELL

