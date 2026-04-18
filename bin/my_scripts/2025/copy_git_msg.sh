#!/usr/bin/env bash

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'
DARKYELLOW='\033[93m'

# Hard-coded skip value for now
n=0

# Build the command as a string
cmd="git log -1 --skip=\"$n\" --pretty=%s | tr -d '\n' | xclip -selection clipboard"

printf "${CYAN}n = ${YELLOW}%s${RESET}\n" "$n"

# If any argument is provided, print the command instead of running it
if [ $# -gt 0 ]; then
    printf "${MAGENTA}Print mode enabled because an argument was provided.${RESET}\n"
    printf "${BLUE}%s${RESET}\n" "$cmd"
else
    printf "${GREEN}Running command...${RESET}\n"
    eval "$cmd"
    printf "${GREEN}Copied latest matching commit subject to clipboard.${RESET}\n"
fi
