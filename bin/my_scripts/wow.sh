#!/usr/bin/bash
# Re-run in bash when started via `sh wow.sh` (dash), the detection below uses bash syntax
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}$*${NC}"; }
success() { echo -e "${GREEN}$*${NC}"; }
warn()    { echo -e "${YELLOW}$*${NC}"; }
error()   { echo -e "${RED}$*${NC}"; }

WORLD_PORT=8085
REALM_PORT=3724
WORLD_PROCS="mangosd|worldserver"
REALM_PROCS="realmd|authserver"

# Map a server binary path to "<name> <expansion>" (tbc checked before plain cmangos)
classify_server() {
  case "${1,,}" in
    *cmangos-tbc*|*mangos-tbc*)              echo "mangos-tbc tbc" ;;
    *mangoszero*|*mangos-zero*)              echo "mangoszero classic" ;;
    *vmangos*)                               echo "vmangos classic" ;;
    *cmangos*|*mangos-classic*)              echo "mangos-classic classic" ;;
    *acore*|*azerothcore*)                   echo "azerothcore wotlk" ;;
    *tcore*|*trinitycore*|*trinity*)         echo "trinitycore wotlk" ;;
  esac
}

# Resolve a pid to its binary path; ps only shows "./mangosd" when started from its bin dir
pid_exe() {
  local exe
  exe=$(readlink -f "/proc/$1/exe" 2>/dev/null) && [ -n "$exe" ] && { echo "$exe"; return; }
  local cwd cmd
  cwd=$(readlink -f "/proc/$1/cwd" 2>/dev/null)
  cmd=$(tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null | awk '{print $1}')
  [[ "$cmd" == /* ]] && echo "$cmd" || echo "$cwd/$cmd"
}

port_open() { timeout 1 bash -c "</dev/tcp/127.0.0.1/$1" 2>/dev/null; }

# Candidate pids: server processes by name plus whatever listens on the world/realm ports
SERVER_PIDS=$( { pgrep -x "$WORLD_PROCS|$REALM_PROCS" 2>/dev/null
  ss -ltnpH "( sport = :$WORLD_PORT or sport = :$REALM_PORT )" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2; } | sort -u)

SERVER_NAME=""
SERVER_EXPANSION=""
for pid in $SERVER_PIDS; do
  exe=$(pid_exe "$pid")
  read -r name expansion <<< "$(classify_server "$exe")"
  [ -z "$name" ] && continue
  # A world server decides the expansion; a realm server only if no world server is found
  if [[ "$(basename "$exe")" =~ ^($WORLD_PROCS)$ ]] || [ -z "$SERVER_NAME" ]; then
    SERVER_NAME=$name
    SERVER_EXPANSION=$expansion
  fi
done

world_up=false; realm_up=false
port_open $WORLD_PORT && world_up=true
port_open $REALM_PORT && realm_up=true

if [ -n "$SERVER_NAME" ]; then
  success "$SERVER_NAME server is running ($SERVER_EXPANSION) - world port $WORLD_PORT: $world_up, realm port $REALM_PORT: $realm_up"
elif $world_up || $realm_up; then
  warn "A server is listening (world port $WORLD_PORT: $world_up, realm port $REALM_PORT: $realm_up) but its type is unknown"
else
  error "No server is running"
fi

ARG=$(echo "$1" | tr '[:upper:]' '[:lower:]')
# No client given: pick the one matching the running server
if [ -z "$ARG" ] && [ -n "$SERVER_EXPANSION" ]; then
    ARG=$SERVER_EXPANSION
    info "Using the $ARG client for $SERVER_NAME"
fi
# ARG=${1,,} # Works in Bash 4.0+

BASE_PATH_MOUNTED="/mnt/new"
BASE_PATH_DOWNLOADS="$HOME/Downloads"
BASE_PATH_MEDIA="/media/2024"

case "$ARG" in
    classic|c)
        WOW_DIR="wow_classic"
        WOW_EXEC="WoW.exe"
        ;;
    tbc)
        WOW_DIR="wow_tbc"
        WOW_EXEC="Wow.exe"
        ;;
    cata)
        WOW_DIR="cata"
        WOW_EXEC="Wow-64.exe"
        ;;
    wotlk|w)
        WOW_DIR="wow"
        WOW_EXEC="Wow.exe"
        ;;
    *)
        WOW_DIR="wow"
        WOW_EXEC="Wow.exe"
        ;;
esac

WOW_PATH_MOUNTED="$BASE_PATH_MOUNTED/$WOW_DIR/$WOW_EXEC"
WOW_PATH_DOWNLOADS="$BASE_PATH_DOWNLOADS/$WOW_DIR/$WOW_EXEC"
WOW_PATH_MEDIA="$BASE_PATH_MEDIA/$WOW_DIR/$WOW_EXEC"

# Check for executable and run
if [ -f "$WOW_PATH_MOUNTED" ]; then
    wine "$WOW_PATH_MOUNTED"
elif [ -f "$WOW_PATH_DOWNLOADS" ]; then
    wine "$WOW_PATH_DOWNLOADS"
elif [ -f "$WOW_PATH_MEDIA" ]; then
    wine "$WOW_PATH_MEDIA"
else
    echo "$WOW_EXEC not found in any of the specified locations for $WOW_DIR."
fi

