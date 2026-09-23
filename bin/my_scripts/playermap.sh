#!/usr/bin/env bash
#
# Dispatcher for the playermap apps (js / ts / py / php) across the supported server cores.
#
# Usage examples:
# azerothcore, javascript:
# playermap.sh acore js
#
# cmangos-tbc, python (the default language):
# playermap.sh cmangos-tbc
#
# mangoszero, typescript:
# playermap.sh mangoszero ts
#
# azerothcore, php:
# playermap.sh acore php
#
# print the command instead of running it:
# playermap.sh acore js --show-cmd
#
# help:
# playermap.sh help
# playermap.sh -h

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'

write_ok()       { echo -e "${GREEN}${1}${RESET}"; }
write_err()      { echo -e "${RED}${1}${RESET}"; }
write_warn()     { echo -e "${YELLOW}${1}${RESET}"; }
write_info()     { echo -e "${CYAN}${1}${RESET}"; }
write_info_alt() { echo -e "${MAGENTA}${1}${RESET}"; }

# Normalized server name followed by the aliases you may type for it. Single
# source of truth: both the help text and normalize_server read from this.
SERVER_GROUPS=(
  "acore       acore azerothcore"
  "tcore       tcore trinitycore"
  "cmangos     cmangos classic cmangos-classic"
  "cmangos-tbc cmangos-tbc mangos-tbc tbc"
  "vmangos     vmangos vanilla"
  "mangoszero  mangoszero mangos0 mangos-zero zero"
)

LANGUAGES=(js ts py php)
DEFAULT_LANG=py
PHP_SERVERS="acore, tcore"
PHP_PORT=8000
BASE="$HOME/Code2/Python/wander_nodes_util"
SCRIPT_NAME=$(basename "$0")

join_by_comma() {
  local joined
  joined=$(printf '%s, ' "$@")
  printf '%s' "${joined%, }"
}

show_servers() {
  local group
  local -a parts
  write_info_alt "Servers:"
  for group in "${SERVER_GROUPS[@]}"; do
    parts=($group)
    printf '  %-13s%s\n' "${parts[0]}" "$(join_by_comma "${parts[@]:1}")"
  done
}

show_usage() {
  local plain_langs
  plain_langs=$(join_by_comma js ts py)

  write_info "$SCRIPT_NAME - launch a playermap app for a WoW server core"
  echo
  write_info_alt "Usage:"
  echo "  $SCRIPT_NAME <server> [$(IFS='|'; echo "${LANGUAGES[*]}")] [--show-cmd]"
  echo "  $SCRIPT_NAME help | -h"
  echo
  show_servers
  echo
  write_info_alt "Languages:"
  printf '  %-13s%s\n' "$plain_langs" "(default: $DEFAULT_LANG)"
  printf '  %-13s%s\n' "php" "only for: $PHP_SERVERS"
  echo
  write_info_alt "Options:"
  echo "  --show-cmd   print the command that would be run, then exit"
  echo "  -h, help     show this help"
  echo
  write_info_alt "Examples:"
  echo "  $SCRIPT_NAME acore js"
  echo "  $SCRIPT_NAME cmangos-tbc"
  echo "  $SCRIPT_NAME mangoszero ts"
  echo "  $SCRIPT_NAME acore php"
  echo "  $SCRIPT_NAME acore js --show-cmd"
}

usage_and_exit() {
  write_err "$1"
  echo
  show_usage
  exit 1
}

normalize_server() {
  local want group alias
  local -a parts
  want=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  for group in "${SERVER_GROUPS[@]}"; do
    parts=($group)
    for alias in "${parts[@]:1}"; do
      if [[ $alias == "$want" ]]; then
        printf '%s' "${parts[0]}"
        return 0
      fi
    done
  done
  return 1
}

show_cmd=0
positional=()

for arg in "$@"; do
  case "$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')" in
    help|--help|-h|-help|/?|-\?)
      show_usage
      exit 0
      ;;
    --show-cmd|--showcmd)
      show_cmd=1
      ;;
    -*)
      usage_and_exit "Unknown option '$arg'"
      ;;
    *)
      positional+=("$arg")
      ;;
  esac
done

if (( ${#positional[@]} > 2 )); then
  usage_and_exit "Unknown argument(s): ${positional[*]:2}"
fi

srv="${positional[0]:-}"
lang=$(printf '%s' "${positional[1]:-$DEFAULT_LANG}" | tr '[:upper:]' '[:lower:]')

# No server given - show what is on offer before asking for one
if [[ -z $srv ]]; then
  if [[ -t 0 ]]; then
    show_servers
    echo
    read -r -p "Server: " srv
  fi
  [[ -n $srv ]] || usage_and_exit "No server given."
fi

if ! norm=$(normalize_server "$srv"); then
  usage_and_exit "Unknown server '$srv'"
fi

case "$lang" in
  js|ts|py|php) ;;
  *) usage_and_exit "Unknown language '$lang'" ;;
esac

# Work out where to run and what to run, so --show-cmd can print it verbatim
if [[ $lang == php ]]; then
  if [[ $norm != acore && $norm != tcore ]]; then
    usage_and_exit "php playermap is only supported for: $PHP_SERVERS"
  fi

  run_dir="$BASE/${norm}_map/playermap"
  ip=$(ip addr show | grep -v 'inet6' \
      | grep -v 'inet 127' \
      | grep 'inet ' \
      | head -n1 \
      | awk '{print $2}' \
      | cut -d/ -f1)
  run_argv=(php -S "${ip}:${PHP_PORT}")
else
  if [[ $norm == acore || $norm == tcore ]]; then
    js_dir=js_map; ts_dir=ts_map; py_script=app.py
  else
    js_dir=js_map_tbc; ts_dir=ts_map_tbc; py_script=app_cmangos.py
  fi

  case "$lang" in
    js) run_dir="$BASE/$js_dir"; run_argv=(npm run dev) ;;
    ts) run_dir="$BASE/$ts_dir"; run_argv=(npm run dev:watch) ;;
    py) run_dir="$BASE/py_map";  run_argv=(/usr/bin/python3 "$py_script") ;;
  esac
fi

run_cmd="${run_argv[*]}"

if (( show_cmd )); then
  [[ -d $run_dir ]] || write_warn "Note: directory does not exist: $run_dir"
  write_info "Equivalent bash command:"
  echo "# $SCRIPT_NAME $norm $lang"
  echo "export SELECTED_SERVER='$norm'"
  echo "cd '$run_dir'"
  echo "$run_cmd"
  exit 0
fi

if [[ ! -d $run_dir ]]; then
  write_err "Directory not found: $run_dir"
  exit 1
fi

export SELECTED_SERVER="$norm"

write_ok "Launching $norm playermap ($lang) in $run_dir"
write_info "Running: $run_cmd"
cd "$run_dir" || exit 1
exec "${run_argv[@]}"
