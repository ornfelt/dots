#!/usr/bin/env bash
set -euo pipefail

# Syncs one account's WTF files into the other accounts of the same install (one account per
# server), keeping each target's own realm folder name.
#
# Usage:
# ./wow_wtf_sync.sh                          # classic: VMANGOS -> CMANGOS, MANGOSZERO
# ./wow_wtf_sync.sh classic                  # the same
# ./wow_wtf_sync.sh classic mangoszero       # MANGOSZERO -> VMANGOS, CMANGOS
# ./wow_wtf_sync.sh classic --from cmangos --to vmangos
# ./wow_wtf_sync.sh wotlk                    # ACORE -> TCORE
# ./wow_wtf_sync.sh wotlk tcore              # TCORE -> ACORE
# ./wow_wtf_sync.sh classic --wow-dir /media2/2024/wow_classic   # another install (or as positional dir)
# ./wow_wtf_sync.sh classic --debug          # print the equivalent bash commands, change nothing
#
# Names are case insensitive: vmangos / vm, cmangos / cm, mangoszero / zero / mz, acore / ac /
# azerothcore, tcore / tc / trinitycore (or the account folder's own name).
#
# Each target account folder is emptied, then gets the source's account files (macros, bindings,
# SavedVariables, ...) and the source's realm folder under the target's own realm name (CMANGOS
# keeps "MaNGOS", MANGOSZERO "MaNGOS Zero Server #1", ...). Any other realm folder in the source
# (an old realm name) is skipped. The source is not changed.

RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'; GRAY=$'\e[90m'; RESET=$'\e[0m'
info() { echo "${CYAN}$*${RESET}"; }
ok()   { echo "${GREEN}$*${RESET}"; }
warn() { echo "${YELLOW}WARNING: $*${RESET}" >&2; }
err()  { echo "${RED}ERROR: $*${RESET}" >&2; }
faint() { echo "${GRAY}$*${RESET}"; }

usage() { sed -n '/^# Usage:/,/^# (an old realm name)/p' "$0" | sed 's/^# \{0,1\}//'; }

# ---- arguments

ver=""
from=""
to=""
wowRoot=""
debug=false

while [[ $# -gt 0 ]]; do
  case "${1,,}" in
    help|-h|--help) usage; exit 0 ;;
    -f|--from) from="${2:?--from needs an account}"; shift 2 ;;
    -t|--to) to="${2:?--to needs an account (comma separated for several)}"; shift 2 ;;
    -d|--wow-dir) wowRoot="${2:?--wow-dir needs a directory}"; shift 2 ;;
    --debug|--dry-run) debug=true; shift ;;
    -*) err "Unknown option '$1'"; usage; exit 1 ;;
    *)
      if [[ -z "$ver" && "${1,,}" =~ ^(classic|vanilla|wotlk)$ ]]; then ver="${1,,}"
      elif [[ -d "$1" && -z "$wowRoot" ]]; then wowRoot="$1"
      elif [[ -z "$from" ]]; then from="$1"
      else err "Unexpected argument '$1'"; usage; exit 1
      fi
      shift ;;
  esac
done
ver="${ver:-classic}"
[[ "$ver" == vanilla ]] && ver=classic

# ---- accounts per install: account folder -> realm folder

declare -A realm
case "$ver" in
  classic)
    wowEnv="wow_classic_dir"
    accounts=(VMANGOS CMANGOS MANGOSZERO)
    realm=([VMANGOS]="vmangos" [CMANGOS]="MaNGOS" [MANGOSZERO]="MaNGOS Zero Server #1")
    defaultFrom="VMANGOS"
    ;;
  wotlk)
    wowEnv="wow_dir"
    accounts=(ACORE TCORE)
    realm=([ACORE]="AzerothCore" [TCORE]="Trinity")
    defaultFrom="ACORE"
    ;;
esac

# An account name as given (alias or folder name, any case) -> the account key.
account_of() {
  case "${1,,}" in
    vmangos|vm) echo VMANGOS ;;
    cmangos|cm|mangos-classic) echo CMANGOS ;;
    mangoszero|zero|mz|mangos-zero) echo MANGOSZERO ;;
    acore|ac|azerothcore) echo ACORE ;;
    tcore|tc|trinitycore|trinity) echo TCORE ;;
    *) return 1 ;;
  esac
}

from="${from:-$defaultFrom}"
src=$(account_of "$from") && [[ -n "${realm[$src]+x}" ]] || { err "Unknown $ver account '$from' (${accounts[*]})"; exit 1; }

targets=()
if [[ -n "$to" ]]; then
  IFS=',' read -ra wanted <<< "$to"
  for t in "${wanted[@]}"; do
    acct=$(account_of "$t") && [[ -n "${realm[$acct]+x}" ]] || { err "Unknown $ver account '$t' (${accounts[*]})"; exit 1; }
    [[ "$acct" == "$src" ]] && { err "'$t' is the source account"; exit 1; }
    targets+=("$acct")
  done
else
  for acct in "${accounts[@]}"; do [[ "$acct" != "$src" ]] && targets+=("$acct"); done
fi

# ---- paths

if [[ -z "$wowRoot" ]]; then
  wowRoot="${!wowEnv:-}"
  [[ -n "$wowRoot" ]] || { err "Environment variable '$wowEnv' not set (or give --wow-dir)"; exit 1; }
fi
accountRoot="$wowRoot/WTF/Account"
[[ -d "$accountRoot" ]] || { err "Account directory not found: $accountRoot"; exit 1; }

# A folder under a parent, matched case insensitively (the client is, Linux is not).
find_dir() {
  local parent="$1" name="$2" d
  for d in "$parent"/*/; do
    d="${d%/}"
    local base="${d##*/}"
    [[ "${base,,}" == "${name,,}" ]] && { echo "$d"; return 0; }
  done
  return 1
}

srcDir=$(find_dir "$accountRoot" "$src") || { err "Source account folder not found: $accountRoot/$src"; exit 1; }
srcRealm=$(find_dir "$srcDir" "${realm[$src]}") || { err "Source realm folder not found: $srcDir/${realm[$src]}"; exit 1; }

if pgrep -f "$wowRoot/" >/dev/null 2>&1; then
  warn "a client of $wowRoot is running: it writes its WTF files at logout and exit, over what is synced now"
fi

# Runs a command, or with --debug prints it as a bash line.
run() {
  if $debug; then
    local q=() a
    for a in "$@"; do q+=("$(printf '%q' "$a")"); done
    echo "${q[*]}"
  else
    "$@"
  fi
}

info "Install: $wowRoot ($ver)"
info "From:    $src (realm '${realm[$src]}'): $srcDir"
$debug && faint "--debug: the commands are printed, nothing is changed"

# ---- sync

for tgt in "${targets[@]}"; do
  tgtDir=$(find_dir "$accountRoot" "$tgt") || tgtDir="$accountRoot/$tgt"
  echo
  info "== $src -> $tgt (realm '${realm[$tgt]}'): $tgtDir"
  run mkdir -p "$tgtDir"
  # empty the target, dot files included
  run find "$tgtDir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

  shopt -s dotglob nullglob
  for entry in "$srcDir"/*; do
    name="${entry##*/}"
    if [[ -d "$entry" && "$entry" != "$srcRealm" && "${name,,}" != "savedvariables" ]]; then
      warn "skipped '$name' in $src: not its realm '${realm[$src]}' (an old realm folder?)"
      continue
    fi
    if [[ "$entry" == "$srcRealm" ]]; then
      run cp -a "$entry" "$tgtDir/${realm[$tgt]}"
      ok "  realm '${realm[$src]}' -> '${realm[$tgt]}'"
    else
      run cp -a "$entry" "$tgtDir/"
      faint "  $name"
    fi
  done
  shopt -u dotglob nullglob
done

echo
ok "Done: $src -> ${targets[*]}"
