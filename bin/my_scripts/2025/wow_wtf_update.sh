#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./wow_wtf_update.sh tbc
#
# benilla's / cenilla's own WTF files (benilla-config / cenilla-config) into wow_addons' classic
# Account folder, the reverse of 'wow_wtf_fix benilla'; benilla asks which checkout when several
# have a benilla-config (Enter = the last one benilla.sh used):
# ./wow_wtf_update.sh benilla
# ./wow_wtf_update.sh benilla dir=benilla-gfx account=CMANGOS
# ./wow_wtf_update.sh cenilla --debug      (prints the bash commands instead of running them)

usage() {
  cat <<'HELP'
Copies the WoW install's WTF Account folder and Config.wtf (as <host>_Config.wtf) of that version
($wow_dir / $wow_tbc_dir / $wow_classic_dir) into wow_addons
(Code2/Wow/addons/wow_addons/<version>/WTF), replacing its Account folder.

With benilla / cenilla it instead copies that client's own WTF files (its benilla-config /
cenilla-config) into wow_addons' classic Account folder, the reverse of 'wow_wtf_fix benilla':
  - each <kind>/<Realm>-<Char> file into Account/<account>/<Realm>/<Char>/ (the realm and character
    names, flattened in the file names, are found in that Account folder, else the install's); bindings
    from the clients' real-format .wtf files
  - the account-wide files (macros, bindings, SavedVariables, cache.md5) into Config.wtf's realmName
    account, or account=<name>
  Every other file in the Account folder is kept; Config.wtf is not touched (the clients keep config.toml).
  benilla: $BENILLA_HOME when set (cenilla reads it too), else dir=<checkout>, else the only
  Code2/Wow/tools/benilla* checkout with a benilla-config, else a menu (Enter = the last one used);
  cenilla: Code2/Wow/tools/cenilla/cenilla-config.

Usage: wow_wtf_update.sh [classic|tbc|wotlk]  (default: wotlk, case insensitive)
       wow_wtf_update.sh benilla|cenilla [dir=<checkout>] [account=<name>] [--debug]
       wow_wtf_update.sh help | --help | -h
HELP
}
for arg in "$@"; do
  case "${arg,,}" in help|--help|-h) usage; exit 0 ;; esac
done

# --- benilla / cenilla: the clients' own WTF files into wow_addons' classic Account folder ---

write_info() { printf '\033[36m%s\033[0m\n' "$1"; } # Cyan
write_ok()   { printf '\033[32m%s\033[0m\n' "$1"; } # Green
write_warn() { printf '\033[33m%s\033[0m\n' "$1"; } # Yellow
write_err()  { printf '\033[31m%s\033[0m\n' "$1" >&2; } # Red
write_cmd()  { printf '\033[34m%s\033[0m\n' "$1"; } # Blue

CLIENT_NAMES=(benilla cenilla)
CLIENT_VERSION="classic"
VERSION_NAMES=(classic tbc wotlk)
DEBUG_TOKENS=(--debug -debug debug)
ACCOUNT_ARG="account="
DIR_ARG="dir="
CLIENT_WOW_ENV="wow_classic_dir"
TOOLS_ROOT="${code_root_dir:-$HOME}/Code2/Wow/tools"
ADDONS_WTF_DIR="${code_root_dir:-$HOME}/Code2/Wow/addons/wow_addons/$CLIENT_VERSION/WTF"
# A benilla checkout is a benilla* dir holding the client crate (benilla.sh's rule)
BENILLA_PATTERN="benilla*"
BENILLA_PREFIX="benilla-"
BENILLA_MANIFEST="crates/benilla/Cargo.toml"
CENILLA_REPO_NAME="cenilla"
declare -A STATE_DIR_NAMES=([benilla]=benilla-config [cenilla]=cenilla-config)
# Both clients take their state folder from it when it is set
STATE_HOME_VAR="BENILLA_HOME"
# The checkout benilla.sh ran last (its menu's default)
LAST_CHECKOUT_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/benilla/last-dir"
WTF_DIR_NAME="WTF"
ACCOUNT_DIR_NAME="Account"
CONFIG_WTF="Config.wtf"
SAVED_VARIABLES_DIR="SavedVariables"
SAVED_VARIABLES_EXT=".lua"
SAVED_DIR="saved"
# A per-character kind's folder in the state folder, its file extension there and its WTF file
CHARACTER_KINDS=(macros layout chat camera addon-state config-cache bindings)
declare -A CHARACTER_KIND_FILES=(
  [macros]=".txt macros-cache.txt"
  [layout]=".txt layout-cache.txt"
  [chat]=".txt chat-cache.txt"
  [camera]=".txt camera-settings.txt"
  [addon-state]=".txt AddOns.txt"
  [config-cache]=".wtf config-cache.wtf"
  [bindings]=".wtf bindings-cache.wtf"
)
# The account-wide files of the state folder and their WTF file
ACCOUNT_FILE_NAMES=(macros/account.txt config-cache/account.wtf bindings/account.wtf saved-variables.lua cache.md5)
declare -A ACCOUNT_FILE_TARGETS=(
  [macros/account.txt]="macros-cache.txt"
  [config-cache/account.wtf]="config-cache.wtf"
  [bindings/account.wtf]="bindings-cache.wtf"
  [saved-variables.lua]="SavedVariables.lua"
  [cache.md5]="cache.md5"
)
# The base name of a kind's account-wide file, not a character's
ACCOUNT_FILE_BASE="account"
# A character file's base name: <Realm>-<Char>, the names flattened to letters, digits and _
CHARACTER_KEY_SEPARATOR="-"
UNKNOWN_TOKEN="unknown"
debug_mode=false
stat_files=0
stat_skipped=0
declare -A realm_accounts=() realm_names=() character_names=() touched_characters=()

in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do if [[ "$item" == "$needle" ]]; then return 0; fi; done
  return 1
}

file_token() {
  # A realm / character name as the clients put it in a file name (local_state::file_token)
  local token
  token="$(printf '%s' "$1" | sed 's/[^[:alnum:]]/_/g')"
  printf '%s' "${token:-$UNKNOWN_TOKEN}"
}

copy_wtf_file() {
  # copy_wtf_file <source> <destination>
  local parent
  parent="$(dirname -- "$2")"
  if $debug_mode; then
    write_cmd "mkdir -p -- $(printf '%q' "$parent") && cp -- $(printf '%q' "$1") $(printf '%q' "$2")"
  else
    mkdir -p -- "$parent"
    cp -- "$1" "$2"
  fi
  stat_files=$((stat_files + 1))
}

copy_saved_variables() {
  # copy_saved_variables <source dir> <destination dir> - the addons' <Addon>.lua
  local file
  if [[ ! -d "$1" ]]; then return 0; fi
  for file in "$1"/*"$SAVED_VARIABLES_EXT"; do
    if [[ -f "$file" ]]; then copy_wtf_file "$file" "$2/$(basename -- "$file")"; fi
  done
}

index_realms() {
  # index_realms <account roots...> - fills realm_accounts / realm_names (by realm token) and
  # character_names (by "<realm token>-<character token>"), the first root that has a realm winning
  local root account realm character token
  for root in "$@"; do
    for account in "$root"/*/; do
      account="${account%/}"
      for realm in "$account"/*/; do
        realm="${realm%/}"
        if [[ "$(basename -- "$realm")" == "$SAVED_VARIABLES_DIR" ]]; then continue; fi
        token="$(file_token "$(basename -- "$realm")")"
        if [[ -n "${realm_accounts[$token]:-}" ]]; then continue; fi
        realm_accounts[$token]="$(basename -- "$account")"
        realm_names[$token]="$(basename -- "$realm")"
        for character in "$realm"/*/; do
          character="$(basename -- "${character%/}")"
          character_names["$token$CHARACTER_KEY_SEPARATOR$(file_token "$character")"]="$character"
        done
      done
    done
  done
}

resolve_character_dir() {
  # resolve_character_dir <key> <account root> - prints a <Realm>-<Char> file key's character
  # folder in the Account folder; fails on an unknown realm
  local key="$1" realm_token character_token
  realm_token="${key%%"$CHARACTER_KEY_SEPARATOR"*}"
  character_token="${key#*"$CHARACTER_KEY_SEPARATOR"}"
  if [[ "$realm_token" == "$key" || -z "${realm_accounts[$realm_token]:-}" ]]; then return 1; fi
  printf '%s\n' "$2/${realm_accounts[$realm_token]}/${realm_names[$realm_token]}/${character_names[$key]:-$character_token}"
}

resolve_target_account() {
  # resolve_target_account <wtf dir> <requested> <account roots...> - prints the account the
  # account-wide files go into: account=<name>, else the one holding Config.wtf's realmName realm,
  # else the only one
  local wtf="$1" requested="$2" root dir sub name realm="" names="" only=""
  local -A seen=()
  shift 2
  for root in "$@"; do
    for dir in "$root"/*/; do
      name="$(basename -- "$dir")"
      if [[ -n "${seen[$name]:-}" ]]; then continue; fi
      seen[$name]=1; names+="${names:+, }$name"; only="$name"
      if [[ -n "$requested" && "${name,,}" == "${requested,,}" ]]; then printf '%s\n' "$name"; return 0; fi
    done
  done
  if [[ -n "$requested" ]]; then write_err "No account $requested (accounts: $names)."; exit 1; fi

  if [[ -f "$wtf/$CONFIG_WTF" ]]; then
    realm="$(sed -n 's/^[[:space:]]*SET[[:space:]]\{1,\}realmName[[:space:]]\{1,\}"\([^"]*\)".*/\1/Ip' "$wtf/$CONFIG_WTF" | head -n 1 || true)"
  fi
  if [[ -n "$realm" ]]; then
    for root in "$@"; do
      for dir in "$root"/*/; do
        for sub in "$dir"*/; do
          if [[ "$(basename -- "$sub")" == "$realm" ]]; then basename -- "$dir"; return 0; fi
        done
      done
    done
  fi
  if (( ${#seen[@]} == 1 )); then printf '%s\n' "$only"; return 0; fi
  write_err "No account holds $CONFIG_WTF's realmName realm ($realm) - pass account=<name> (accounts: $names)."
  exit 1
}

select_benilla_state_dir() {
  # select_benilla_state_dir <requested> - prints the benilla checkout's state folder to read:
  # dir=<checkout> (its name, the name without benilla-, or a path), else the only checkout with
  # one, else a menu (Enter = the last used); the menu goes to stderr, the answer comes from the
  # terminal
  local requested="$1" dir checkouts=() names="" i last="" default="" mark branch answer prompt
  for dir in "$TOOLS_ROOT"/$BENILLA_PATTERN; do
    if [[ -f "$dir/$BENILLA_MANIFEST" && -d "$dir/${STATE_DIR_NAMES[benilla]}" ]]; then
      checkouts+=("$dir"); names+="${names:+, }$(basename -- "$dir")"
    fi
  done
  if [[ -n "$requested" ]]; then
    if [[ -d "$requested" ]]; then printf '%s\n' "$(cd -- "$requested" && pwd)/${STATE_DIR_NAMES[benilla]}"; return 0; fi
    for dir in "${checkouts[@]}"; do
      if [[ "$(basename -- "$dir")" == "$requested" || "$(basename -- "$dir")" == "$BENILLA_PREFIX$requested" ]]; then
        printf '%s\n' "$dir/${STATE_DIR_NAMES[benilla]}"; return 0
      fi
    done
    write_err "No benilla checkout with a ${STATE_DIR_NAMES[benilla]} matches $requested (have: $names)."
    exit 1
  fi
  if (( ${#checkouts[@]} == 0 )); then write_err "No benilla checkout under $TOOLS_ROOT has a ${STATE_DIR_NAMES[benilla]}."; exit 1; fi
  if (( ${#checkouts[@]} == 1 )); then printf '%s\n' "${checkouts[0]}/${STATE_DIR_NAMES[benilla]}"; return 0; fi

  if [[ -f "$LAST_CHECKOUT_FILE" ]]; then last="$(head -n 1 -- "$LAST_CHECKOUT_FILE" 2>/dev/null || true)"; fi
  write_info "benilla checkouts with a ${STATE_DIR_NAMES[benilla]} under $TOOLS_ROOT:" >&2
  for i in "${!checkouts[@]}"; do
    mark=" "
    if [[ -n "$last" && "$(cd -- "${checkouts[$i]}" && pwd)" == "$last" ]]; then default="$i"; mark="*"; fi
    branch="$(git -C "${checkouts[$i]}" branch --show-current 2>/dev/null || true)"
    printf '%s %d) %-22s %s\n' "$mark" "$((i + 1))" "$(basename -- "${checkouts[$i]}")" "$branch" >&2
  done
  if [[ ! -t 0 ]]; then write_err "Several checkouts and no terminal to pick one - pass dir=<checkout>."; exit 1; fi
  prompt="Read from which? (1-${#checkouts[@]}"
  if [[ -n "$default" ]]; then prompt+=", Enter = $(basename -- "${checkouts[$default]}")"; fi
  read -r -p "$prompt): " answer </dev/tty || answer=""
  answer="${answer//[[:space:]]/}"
  if [[ -z "$answer" && -n "$default" ]]; then printf '%s\n' "${checkouts[$default]}/${STATE_DIR_NAMES[benilla]}"; return 0; fi
  if [[ "$answer" =~ ^[0-9]+$ ]] && (( 10#$answer >= 1 && 10#$answer <= ${#checkouts[@]} )); then
    printf '%s\n' "${checkouts[$((10#$answer - 1))]}/${STATE_DIR_NAMES[benilla]}"; return 0
  fi
  write_err "Not a checkout number: $answer"
  exit 1
}

copy_state_into_account() {
  # copy_state_into_account <state dir> <account root> <account> - overlays the Account folder
  # with the state folder's WTF files (see usage)
  local state="$1" root="$2" main="$3" kind ext wtf_name file key target name dir
  for kind in "${CHARACTER_KINDS[@]}"; do
    read -r ext wtf_name <<<"${CHARACTER_KIND_FILES[$kind]}"
    for file in "$state/$kind"/*"$ext"; do
      if [[ ! -f "$file" ]]; then continue; fi
      key="$(basename -- "$file" "$ext")"
      if [[ "$key" == "$ACCOUNT_FILE_BASE" ]]; then continue; fi
      if ! target="$(resolve_character_dir "$key" "$root")"; then
        write_warn "  no realm for $kind/$(basename -- "$file") in the Account folders - skipped"
        stat_skipped=$((stat_skipped + 1)); continue
      fi
      copy_wtf_file "$file" "$target/$wtf_name"
      touched_characters[$target]=1
    done
  done
  for dir in "$state/$SAVED_DIR"/*/; do
    dir="${dir%/}"
    if ! target="$(resolve_character_dir "$(basename -- "$dir")" "$root")"; then
      write_warn "  no realm for $SAVED_DIR/$(basename -- "$dir") in the Account folders - skipped"
      stat_skipped=$((stat_skipped + 1)); continue
    fi
    copy_saved_variables "$dir" "$target/$SAVED_VARIABLES_DIR"
    touched_characters[$target]=1
  done

  for name in "${ACCOUNT_FILE_NAMES[@]}"; do
    if [[ -f "$state/$name" ]]; then copy_wtf_file "$state/$name" "$root/$main/${ACCOUNT_FILE_TARGETS[$name]}"; fi
  done
  copy_saved_variables "$state/$SAVED_DIR" "$root/$main/$SAVED_VARIABLES_DIR"
}

clients=()
requested_account=""
requested_dir=""
client_version=""
other_args=()
for arg in "$@"; do
  token="${arg,,}"
  if in_list "$token" "${CLIENT_NAMES[@]}"; then
    if ! in_list "$token" "${clients[@]}"; then clients+=("$token"); fi
  elif in_list "$token" "${DEBUG_TOKENS[@]}"; then debug_mode=true
  elif [[ "$token" == "$ACCOUNT_ARG"* ]]; then requested_account="${arg:${#ACCOUNT_ARG}}"
  elif [[ "$token" == "$DIR_ARG"* ]]; then requested_dir="${arg:${#DIR_ARG}}"
  elif in_list "$token" "${VERSION_NAMES[@]}"; then client_version="$token"
  else other_args+=("$arg")
  fi
done
if (( ${#clients[@]} > 0 )); then
  shopt -s nullglob
  if (( ${#other_args[@]} > 0 )); then write_err "Unknown arg: ${other_args[*]} - see 'wow_wtf_update.sh help'."; exit 1; fi
  if (( ${#clients[@]} > 1 )); then write_err "Name one client to copy from: benilla or cenilla."; exit 1; fi
  if [[ -n "$client_version" && "$client_version" != "$CLIENT_VERSION" ]]; then
    write_err "benilla / cenilla are $CLIENT_VERSION (1.12.1) clients, not $client_version."
    exit 1
  fi
  client="${clients[0]}"
  if [[ -n "$requested_dir" && "$client" != benilla ]]; then write_warn "dir= picks a benilla checkout - ignoring it."; fi

  state_home="${!STATE_HOME_VAR:-}"
  if [[ -n "$state_home" ]]; then
    write_info "\$$STATE_HOME_VAR is set - reading $state_home."
    state_dir="$state_home"
  elif [[ "$client" == benilla ]]; then
    state_dir="$(select_benilla_state_dir "$requested_dir")"
  else
    state_dir="$TOOLS_ROOT/$CENILLA_REPO_NAME/${STATE_DIR_NAMES[cenilla]}"
  fi
  if [[ ! -d "$state_dir" ]]; then write_err "No $client state folder: $state_dir"; exit 1; fi
  if [[ ! -d "$ADDONS_WTF_DIR" ]]; then write_err "Destination directory not found: $ADDONS_WTF_DIR"; exit 1; fi

  # The names come from the destination's Account folder, else the install's
  account_root="$ADDONS_WTF_DIR/$ACCOUNT_DIR_NAME"
  account_roots=("$account_root")
  config_wtf_dir="$ADDONS_WTF_DIR"
  install_root="${!CLIENT_WOW_ENV:-}"
  if [[ -n "$install_root" ]]; then
    account_roots+=("$install_root/$WTF_DIR_NAME/$ACCOUNT_DIR_NAME")
    config_wtf_dir="$install_root/$WTF_DIR_NAME"
  fi
  index_realms "${account_roots[@]}"
  main_account="$(resolve_target_account "$config_wtf_dir" "$requested_account" "${account_roots[@]}")"

  debug_note=""
  if $debug_mode; then debug_note=" - debug: printing the commands only"; fi
  write_info "Copying $state_dir into $account_root (account-wide files into $main_account)$debug_note"
  copy_state_into_account "$state_dir" "$account_root" "$main_account"
  skipped_note=""
  if (( stat_skipped > 0 )); then skipped_note=", $stat_skipped skipped (unknown realm)"; fi
  write_ok "${#touched_characters[@]} characters, $stat_files files$skipped_note; account-wide files into $main_account"
  write_ok "Done."
  exit 0
fi

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

