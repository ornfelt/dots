#!/usr/bin/env bash
#
# Dispatcher for the mpq file server (py / js) across the extracted mpq dirs of each expansion.
# Before launching it brings the chosen mpq dir up to date: the server scripts and index.html are
# copied from {my_notes_path}/scripts/wow/file_server when they differ, any legacy cors_server.js/py
# is removed, and exp.txt is created if missing (an exp.txt with the wrong value is an error).
#
# Usage examples:
# wotlk, python (both defaults):
# mpq_server.sh
#
# tbc, python:
# mpq_server.sh tbc
#
# classic, javascript:
# mpq_server.sh classic js
#
# wotlk, javascript (expansion and language may come in any order):
# mpq_server.sh js
#
# only listen on localhost (127.0.0.1), not on the network ip (default is both):
# mpq_server.sh tbc js --localhost
#
# print the commands instead of running them:
# mpq_server.sh tbc js --show-cmd
#
# help:
# mpq_server.sh help
# mpq_server.sh -h

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

# Normalized expansion name, the env var holding its mpq dir, then the aliases
# you may type for it. Single source of truth for the help text and lookups.
EXP_GROUPS=(
  "wotlk   wow_mpq_dir         wotlk wrath"
  "tbc     wow_tbc_mpq_dir     tbc bc"
  "classic wow_classic_mpq_dir classic vanilla"
)

LANGUAGES=(py js)
DEFAULT_EXP=wotlk
DEFAULT_LANG=py
SERVER_NAME=mpq_server
EXP_FILE=exp.txt
SOURCE_SUBDIR="scripts/wow/file_server"
SYNC_FILES=("$SERVER_NAME.py" "$SERVER_NAME.js" index.html)
LEGACY_FILES=(cors_server.py cors_server.js)
SCRIPT_NAME=$(basename "$0")

join_by_comma() {
  local joined
  joined=$(printf '%s, ' "$@")
  printf '%s' "${joined%, }"
}

show_expansions() {
  local group
  local -a parts
  write_info_alt "Expansions:"
  for group in "${EXP_GROUPS[@]}"; do
    parts=($group)
    printf '  %-9s%-22s%s\n' "${parts[0]}" "\$${parts[1]}" "$(join_by_comma "${parts[@]:2}")"
  done
}

show_usage() {
  write_info "$SCRIPT_NAME - sync and launch the mpq file server for a WoW expansion"
  echo
  write_info_alt "Usage:"
  echo "  $SCRIPT_NAME [expansion] [$(IFS='|'; echo "${LANGUAGES[*]}")] [--localhost] [--show-cmd]"
  echo "  $SCRIPT_NAME help | -h"
  echo
  show_expansions
  printf '  %-9s%s\n' "" "(default: $DEFAULT_EXP)"
  echo
  write_info_alt "Languages:"
  printf '  %-9s%s\n' "$(join_by_comma "${LANGUAGES[@]}")" "(default: $DEFAULT_LANG)"
  echo
  write_info_alt "Synced from \$my_notes_path/$SOURCE_SUBDIR:"
  echo "  $(join_by_comma "${SYNC_FILES[@]}")"
  echo
  write_info_alt "Options:"
  echo "  --localhost  only listen on 127.0.0.1 (default: all interfaces, i.e. also the network ip)"
  echo "  --show-cmd   print the commands that would be run, then exit"
  echo "  -h, help     show this help"
  echo
  write_info_alt "Examples:"
  echo "  $SCRIPT_NAME"
  echo "  $SCRIPT_NAME tbc"
  echo "  $SCRIPT_NAME classic js"
  echo "  $SCRIPT_NAME js"
  echo "  $SCRIPT_NAME tbc js --localhost"
  echo "  $SCRIPT_NAME tbc js --show-cmd"
}

usage_and_exit() {
  write_err "$1"
  echo
  show_usage
  exit 1
}

# Prints "<normalized> <env var>" for an expansion alias
lookup_exp() {
  local want group alias
  local -a parts
  want=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  for group in "${EXP_GROUPS[@]}"; do
    parts=($group)
    for alias in "${parts[@]:2}"; do
      if [[ $alias == "$want" ]]; then
        printf '%s %s' "${parts[0]}" "${parts[1]}"
        return 0
      fi
    done
  done
  return 1
}

show_cmd=0
localhost=0
exp_arg=""
lang=""

for arg in "$@"; do
  lower=$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    help|--help|-h|-help|/?|-\?)
      show_usage
      exit 0
      ;;
    --show-cmd|--showcmd)
      show_cmd=1
      ;;
    --localhost|-localhost)
      localhost=1
      ;;
    -*)
      usage_and_exit "Unknown option '$arg'"
      ;;
    py|js)
      [[ -z $lang ]] || usage_and_exit "Language given twice: '$lang' and '$lower'"
      lang=$lower
      ;;
    *)
      lookup_exp "$arg" >/dev/null || usage_and_exit "Unknown argument '$arg'"
      [[ -z $exp_arg ]] || usage_and_exit "Expansion given twice: '$exp_arg' and '$arg'"
      exp_arg=$arg
      ;;
  esac
done

read -r exp env_var <<< "$(lookup_exp "${exp_arg:-$DEFAULT_EXP}")"
lang=${lang:-$DEFAULT_LANG}

if [[ -z ${my_notes_path:-} ]]; then
  write_err "Environment variable 'my_notes_path' is not set. Exiting."
  exit 1
fi
source_dir="$my_notes_path/$SOURCE_SUBDIR"

mpq_dir="${!env_var:-}"
if [[ -z $mpq_dir ]]; then
  write_err "Environment variable '$env_var' ($exp mpq dir) is not set. Exiting."
  exit 1
fi
if [[ ! -d $mpq_dir ]]; then
  write_err "Directory '$mpq_dir' (from env variable '$env_var') does not exist. Exiting."
  exit 1
fi

# Work out what needs doing first, so --show-cmd can print it instead of doing it
to_copy=()
for file in "${SYNC_FILES[@]}"; do
  if [[ ! -f $source_dir/$file ]]; then
    write_err "Source file not found: $source_dir/$file"
    exit 1
  fi
  cmp -s "$source_dir/$file" "$mpq_dir/$file" || to_copy+=("$file")
done

to_remove=()
for file in "${LEGACY_FILES[@]}"; do
  [[ -e $mpq_dir/$file ]] && to_remove+=("$file")
done

exp_path="$mpq_dir/$EXP_FILE"
create_exp=0
if [[ -f $exp_path ]]; then
  # Trimmed, so a trailing newline or CRLF from Windows still matches
  found_exp=$(tr -d '[:space:]' < "$exp_path")
  if [[ -z $found_exp ]]; then
    create_exp=1
  elif [[ $found_exp != "$exp" ]]; then
    write_err "'$exp_path' says '$found_exp', expected '$exp'."
    write_err "Check that env variable '$env_var' points at the $exp mpq dir. Exiting."
    exit 1
  fi
else
  create_exp=1
fi

case "$lang" in
  py) run_argv=(/usr/bin/python3 "$SERVER_NAME.py") ;;
  js) run_argv=(node "$SERVER_NAME.js") ;;
esac
(( localhost )) && run_argv+=(--localhost)
run_cmd="${run_argv[*]}"

if (( show_cmd )); then
  write_info "Equivalent bash command:"
  echo "# $SCRIPT_NAME $exp $lang$( (( localhost )) && echo ' --localhost')"
  for file in "${to_copy[@]}"; do
    echo "cp -f '$source_dir/$file' '$mpq_dir/$file'"
  done
  for file in "${to_remove[@]}"; do
    echo "rm -f '$mpq_dir/$file'"
  done
  (( create_exp )) && echo "printf '%s\n' '$exp' > '$exp_path'"
  echo "cd '$mpq_dir'"
  echo "$run_cmd"
  exit 0
fi

write_info "Syncing $exp mpq dir: $mpq_dir"

for file in "${SYNC_FILES[@]}"; do
  if [[ " ${to_copy[*]} " != *" $file "* ]]; then
    write_ok "  up to date: $file"
    continue
  fi
  if [[ -f $mpq_dir/$file ]]; then state=updated; else state=copied; fi
  cp -f "$source_dir/$file" "$mpq_dir/$file" || { write_err "Failed to copy $file. Exiting."; exit 1; }
  write_warn "  $state: $file"
done

for file in "${to_remove[@]}"; do
  rm -f "$mpq_dir/$file" || { write_err "Failed to remove $file. Exiting."; exit 1; }
  write_warn "  removed legacy: $file"
done

if (( create_exp )); then
  printf '%s\n' "$exp" > "$exp_path" || { write_err "Failed to write $exp_path. Exiting."; exit 1; }
  write_warn "  created: $EXP_FILE ($exp)"
else
  write_ok "  $EXP_FILE ok: $exp"
fi

[[ -f $mpq_dir/file_paths.txt ]] || write_warn "Note: 'file_paths.txt' does not exist in '$mpq_dir'. Run print_files.sh to generate it."
if [[ $lang == js && ! -d $mpq_dir/node_modules ]]; then
  write_warn "Note: 'node_modules' does not exist in '$mpq_dir'. Run 'npm install express cors' there."
fi

write_ok "Launching $exp $SERVER_NAME ($lang) in $mpq_dir"
write_info "Running: $run_cmd"
cd "$mpq_dir" || exit 1
exec "${run_argv[@]}"
