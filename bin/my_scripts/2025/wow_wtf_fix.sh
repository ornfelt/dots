#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./wow_wtf_fix.sh classic
# ./wow_wtf_fix.sh tbc
# ./wow_wtf_fix.sh wotlk
#
# Copy the classic install's WTF into benilla's / cenilla's own state folder (benilla-config /
# cenilla-config), replacing their WTF files; benilla asks which checkouts when there are several
# (Enter = all). The account-wide files come from Config.wtf's realmName account unless named:
# ./wow_wtf_fix.sh benilla
# ./wow_wtf_fix.sh cenilla
# ./wow_wtf_fix.sh benilla cenilla account=CMANGOS
# Print the bash commands instead of running them:
# ./wow_wtf_fix.sh benilla --debug

usage() {
  cat <<'HELP'
Copies the WTF Account folder of wow_addons (Code2/Wow/addons/wow_addons/<version>/WTF/Account)
into the WoW install of that version ($wow_dir / $wow_tbc_dir / $wow_classic_dir), replacing the
install's Account folder.

With benilla / cenilla it instead copies the classic install's WTF ($wow_classic_dir/WTF/Account)
into those clients' own state folder, replacing its WTF files (macros, bindings, layout, chat,
camera, addon-state, saved, saved-variables.lua, config-cache, cache.md5, wtf-import; config.toml,
cache/, AddOns/, Diagnostics/ and shots.txt are kept):
  - every account's characters: <file> -> <kind>/<Realm>-<Char>.txt (bindings converted to the clients' diff too)
  - the account-wide files (macros, bindings, SavedVariables, cache.md5) of one account: Config.wtf's
    realmName account, or account=<name>
  - the whole Account folder as it is in wtf-import/Account (for reference; the clients do not read it)
  benilla: $BENILLA_HOME when set (cenilla reads it too), else each Code2/Wow/tools/benilla* checkout's
  benilla-config (a menu when there are several, Enter = all); cenilla: Code2/Wow/tools/cenilla/cenilla-config.

Usage: wow_wtf_fix.sh [classic|tbc|wotlk]     (default: wotlk, case insensitive)
       wow_wtf_fix.sh benilla|cenilla [benilla|cenilla] [account=<name>] [--debug]
       wow_wtf_fix.sh help | --help | -h
HELP
}
for arg in "$@"; do
  case "${arg,,}" in help|--help|-h) usage; exit 0 ;; esac
done

# --- benilla / cenilla: the classic install's WTF into the clients' own state folders ---

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
CLIENT_WOW_ENV="wow_classic_dir"
TOOLS_ROOT="${code_root_dir:-$HOME}/Code2/Wow/tools"
# A benilla checkout is a benilla* dir holding the client crate (benilla.sh's rule)
BENILLA_PATTERN="benilla*"
BENILLA_MANIFEST="crates/benilla/Cargo.toml"
CENILLA_REPO_NAME="cenilla"
declare -A STATE_DIR_NAMES=([benilla]=benilla-config [cenilla]=cenilla-config)
# Both clients take their state folder from it when it is set
STATE_HOME_VAR="BENILLA_HOME"
WTF_DIR_NAME="WTF"
ACCOUNT_DIR_NAME="Account"
CONFIG_WTF="Config.wtf"
SAVED_VARIABLES_DIR="SavedVariables"
SAVED_VARIABLES_EXT=".lua"
SAVED_DIR="saved"
WTF_IMPORT_DIR="wtf-import"
# The state folder's WTF equivalents, removed before the copy
STATE_WTF_ITEMS=(macros bindings layout chat camera addon-state "$SAVED_DIR" config-cache saved-variables.lua cache.md5 "$WTF_IMPORT_DIR")
# A character's WTF files: <dir>/<Realm>-<Char><ext> in the state folder
CHARACTER_FILE_NAMES=(macros-cache.txt layout-cache.txt chat-cache.txt camera-settings.txt AddOns.txt config-cache.wtf bindings-cache.wtf)
declare -A CHARACTER_FILE_PLACES=(
  [macros-cache.txt]="macros .txt"
  [layout-cache.txt]="layout .txt"
  [chat-cache.txt]="chat .txt"
  [camera-settings.txt]="camera .txt"
  [AddOns.txt]="addon-state .txt"
  [config-cache.wtf]="config-cache .wtf"
  [bindings-cache.wtf]="bindings .wtf"
)
# The chosen account's account-wide WTF files
ACCOUNT_FILE_NAMES=(macros-cache.txt config-cache.wtf bindings-cache.wtf SavedVariables.lua cache.md5)
declare -A ACCOUNT_FILE_PLACES=(
  [macros-cache.txt]="macros/account.txt"
  [config-cache.wtf]="config-cache/account.wtf"
  [bindings-cache.wtf]="bindings/account.wtf"
  [SavedVariables.lua]="saved-variables.lua"
  [cache.md5]="cache.md5"
)
# A bindings-cache.wtf is also written as the diff the clients load a set from, beside it
BINDINGS_WTF="bindings-cache.wtf"
BINDINGS_DIFF_EXT=".txt"
BINDINGS_DIFF_HEADER="# benilla key bindings - diff vs defaults (from bindings-cache.wtf by wow_wtf_fix)"
UNKNOWN_TOKEN="unknown"
# A bindings-cache.wtf as the clients' diff file (bindings::store::from_cache without the
# defaults): its lines applied in order (a key bound again moves, an empty command unbinds), the
# key names the clients' loader turns into their character mapped (normalize_binding_key), then
# grouped by command; a command the file leaves unbound keeps the clients' default keys
BINDINGS_DIFF_AWK=$(cat <<'AWK'
BEGIN {
  n = split("LEFTBRACKET [ RIGHTBRACKET ] SLASH / BACKSLASH \\ SEMICOLON ; APOSTROPHE ' COMMA , PERIOD . TILDE ` PLUS = MINUS -", a, " ")
  for (i = 1; i < n; i += 2) alias[a[i]] = a[i + 1]
  count = 0
}
{
  sub(/\r$/, "")
  if (toupper(substr($0, 1, 5)) != "BIND ") next
  rest = substr($0, 6)
  p = index(rest, " ")
  if (p) { key = substr(rest, 1, p - 1); cmd = substr(rest, p + 1) } else { key = rest; cmd = "" }
  if (toupper(key) in alias) key = alias[toupper(key)]
  key = toupper(key)
  if (key == "") next
  for (i = 1; i <= count; i++) {
    if (keys[i] == key) {
      for (j = i; j < count; j++) { keys[j] = keys[j + 1]; cmds[j] = cmds[j + 1] }
      count--
      break
    }
  }
  if (cmd != "") { count++; keys[count] = key; cmds[count] = toupper(cmd) }
}
END {
  print header
  groups = 0
  for (i = 1; i <= count; i++) {
    if (!(cmds[i] in group)) { groups++; group[cmds[i]] = groups; names[groups] = cmds[i]; list[groups] = "" }
    list[group[cmds[i]]] = list[group[cmds[i]]] " " keys[i]
  }
  for (g = 1; g <= groups; g++) print "bind " names[g] list[g]
}
AWK
)
debug_mode=false
stat_files=0
stat_bindings=0
stat_characters=0

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

copy_state_file() {
  # copy_state_file <source> <destination>
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

write_binding_diff() {
  # write_binding_diff <bindings-cache.wtf> <diff file>
  if $debug_mode; then
    write_cmd "# write $(printf '%q' "$2") (the diff of $(printf '%q' "$1"))"
  else
    mkdir -p -- "$(dirname -- "$2")"
    awk -v header="$BINDINGS_DIFF_HEADER" "$BINDINGS_DIFF_AWK" "$1" >"$2"
  fi
  stat_bindings=$((stat_bindings + 1))
}

copy_wtf_file() {
  # copy_wtf_file <source> <destination> - a WTF file into the state folder, a bindings-cache.wtf also as its diff
  copy_state_file "$1" "$2"
  if [[ "$(basename -- "$1")" == "$BINDINGS_WTF" ]]; then
    write_binding_diff "$1" "${2%.*}$BINDINGS_DIFF_EXT"
  fi
}

copy_saved_variables() {
  # copy_saved_variables <source dir> <destination dir> - the addons' <Addon>.lua (not the .bak copies)
  local file
  if [[ ! -d "$1" ]]; then return 0; fi
  for file in "$1"/*"$SAVED_VARIABLES_EXT"; do
    if [[ -f "$file" ]]; then copy_state_file "$file" "$2/$(basename -- "$file")"; fi
  done
}

resolve_source_account() {
  # resolve_source_account <account root> <wtf dir> <requested> - prints the account whose
  # account-wide files are copied: account=<name>, else the one holding Config.wtf's realmName
  # realm, else the only one
  local root="$1" wtf="$2" requested="$3" dir sub name realm="" names="" count=0 only=""
  for dir in "$root"/*/; do
    name="$(basename -- "$dir")"
    names+="${names:+, }$name"; count=$((count + 1)); only="$name"
    if [[ -n "$requested" && "${name,,}" == "${requested,,}" ]]; then printf '%s\n' "$name"; return 0; fi
  done
  if [[ -n "$requested" ]]; then write_err "No account $requested in $root (accounts: $names)."; exit 1; fi

  if [[ -f "$wtf/$CONFIG_WTF" ]]; then
    realm="$(sed -n 's/^[[:space:]]*SET[[:space:]]\{1,\}realmName[[:space:]]\{1,\}"\([^"]*\)".*/\1/Ip' "$wtf/$CONFIG_WTF" | head -n 1 || true)"
  fi
  if [[ -n "$realm" ]]; then
    for dir in "$root"/*/; do
      for sub in "$dir"*/; do
        if [[ "$(basename -- "$sub")" == "$realm" ]]; then basename -- "$dir"; return 0; fi
      done
    done
  fi
  if (( count == 1 )); then printf '%s\n' "$only"; return 0; fi
  write_err "No account holds $CONFIG_WTF's realmName realm ($realm) - pass account=<name> (accounts: $names)."
  exit 1
}

select_benilla_checkouts() {
  # Sets picked_checkouts: the only benilla checkout, else the picked ones (Enter = all)
  local dir checkouts=() i answer token branch
  for dir in "$TOOLS_ROOT"/$BENILLA_PATTERN; do
    if [[ -f "$dir/$BENILLA_MANIFEST" ]]; then checkouts+=("$dir"); fi
  done
  if (( ${#checkouts[@]} == 0 )); then write_err "No benilla checkout ($BENILLA_PATTERN holding $BENILLA_MANIFEST) under $TOOLS_ROOT."; exit 1; fi
  picked_checkouts=("${checkouts[@]}")
  if (( ${#checkouts[@]} == 1 )); then return 0; fi

  write_info "benilla checkouts under $TOOLS_ROOT:"
  for i in "${!checkouts[@]}"; do
    branch="$(git -C "${checkouts[$i]}" branch --show-current 2>/dev/null || true)"
    printf '  %d) %-22s %s\n' "$((i + 1))" "$(basename -- "${checkouts[$i]}")" "$branch"
  done
  if [[ ! -t 0 ]]; then write_warn "No terminal to ask - copying into all of them."; return 0; fi
  read -r -p "Copy into which? (Enter = all, or numbers like 1,3): " answer || answer=""
  if [[ -z "${answer//[[:space:],]/}" ]]; then return 0; fi

  picked_checkouts=()
  for token in ${answer//,/ }; do
    if [[ ! "$token" =~ ^[0-9]+$ ]] || (( 10#$token < 1 || 10#$token > ${#checkouts[@]} )); then
      write_err "Not a checkout number: $token (1-${#checkouts[@]})."
      exit 1
    fi
    if ! in_list "${checkouts[$((10#$token - 1))]}" "${picked_checkouts[@]}"; then
      picked_checkouts+=("${checkouts[$((10#$token - 1))]}")
    fi
  done
}

get_client_targets() {
  # Sets client_targets: the state folders to copy into; $BENILLA_HOME for both clients when set
  local home="${!STATE_HOME_VAR:-}" checkout
  client_targets=()
  if [[ -n "$home" ]]; then
    write_info "\$$STATE_HOME_VAR is set - both clients use $home."
    client_targets=("$home")
    return 0
  fi
  if in_list benilla "${clients[@]}"; then
    select_benilla_checkouts
    for checkout in "${picked_checkouts[@]}"; do client_targets+=("$checkout/${STATE_DIR_NAMES[benilla]}"); done
  fi
  if in_list cenilla "${clients[@]}"; then
    if [[ ! -d "$TOOLS_ROOT/$CENILLA_REPO_NAME" ]]; then write_err "cenilla repo not found: $TOOLS_ROOT/$CENILLA_REPO_NAME"; exit 1; fi
    client_targets+=("$TOOLS_ROOT/$CENILLA_REPO_NAME/${STATE_DIR_NAMES[cenilla]}")
  fi
}

copy_wtf_into() {
  # copy_wtf_into <state dir> <account root> <account> - replaces the state folder's WTF files
  # with the install's (see usage)
  local state="$1" root="$2" main="$3" item path account realm character key name dir ext
  local -A owners=()
  stat_files=0; stat_bindings=0; stat_characters=0
  write_info "-> $state"
  for item in "${STATE_WTF_ITEMS[@]}"; do
    path="$state/$item"
    if [[ -e "$path" ]]; then
      if $debug_mode; then write_cmd "rm -rf -- $(printf '%q' "$path")"; else rm -rf -- "$path"; fi
    fi
  done

  for account in "$root"/*/; do
    account="${account%/}"
    for realm in "$account"/*/; do
      realm="${realm%/}"
      if [[ "$(basename -- "$realm")" == "$SAVED_VARIABLES_DIR" ]]; then continue; fi
      for character in "$realm"/*/; do
        character="${character%/}"
        key="$(file_token "$(basename -- "$realm")")-$(file_token "$(basename -- "$character")")"
        if [[ -n "${owners[$key]:-}" ]]; then write_warn "  $key is in ${owners[$key]} and $(basename -- "$account") - $(basename -- "$account")'s files win."; fi
        owners[$key]="$(basename -- "$account")"
        for name in "${CHARACTER_FILE_NAMES[@]}"; do
          if [[ ! -f "$character/$name" ]]; then continue; fi
          read -r dir ext <<<"${CHARACTER_FILE_PLACES[$name]}"
          copy_wtf_file "$character/$name" "$state/$dir/$key$ext"
        done
        copy_saved_variables "$character/$SAVED_VARIABLES_DIR" "$state/$SAVED_DIR/$key"
        stat_characters=$((stat_characters + 1))
      done
    done
  done

  for name in "${ACCOUNT_FILE_NAMES[@]}"; do
    if [[ -f "$root/$main/$name" ]]; then copy_wtf_file "$root/$main/$name" "$state/${ACCOUNT_FILE_PLACES[$name]}"; fi
  done
  copy_saved_variables "$root/$main/$SAVED_VARIABLES_DIR" "$state/$SAVED_DIR"

  if $debug_mode; then
    write_cmd "mkdir -p -- $(printf '%q' "$state/$WTF_IMPORT_DIR") && cp -r -- $(printf '%q' "$root") $(printf '%q' "$state/$WTF_IMPORT_DIR/")"
  else
    mkdir -p -- "$state/$WTF_IMPORT_DIR"
    cp -r -- "$root" "$state/$WTF_IMPORT_DIR/"
  fi
  write_ok "  $stat_characters characters, $stat_files files, $stat_bindings binding sets converted; account-wide files from $main; $ACCOUNT_DIR_NAME as it is in $WTF_IMPORT_DIR/$ACCOUNT_DIR_NAME"
}

clients=()
requested_account=""
client_version=""
other_args=()
for arg in "$@"; do
  token="${arg,,}"
  if in_list "$token" "${CLIENT_NAMES[@]}"; then
    if ! in_list "$token" "${clients[@]}"; then clients+=("$token"); fi
  elif in_list "$token" "${DEBUG_TOKENS[@]}"; then debug_mode=true
  elif [[ "$token" == "$ACCOUNT_ARG"* ]]; then requested_account="${arg:${#ACCOUNT_ARG}}"
  elif in_list "$token" "${VERSION_NAMES[@]}"; then client_version="$token"
  else other_args+=("$arg")
  fi
done
if (( ${#clients[@]} > 0 )); then
  shopt -s nullglob
  if (( ${#other_args[@]} > 0 )); then write_err "Unknown arg: ${other_args[*]} - see 'wow_wtf_fix.sh help'."; exit 1; fi
  if [[ -n "$client_version" && "$client_version" != "$CLIENT_VERSION" ]]; then
    write_err "benilla / cenilla are $CLIENT_VERSION (1.12.1) clients, not $client_version."
    exit 1
  fi

  client_wow_root="${!CLIENT_WOW_ENV:-}"
  if [[ -z "$client_wow_root" ]]; then write_err "\$$CLIENT_WOW_ENV is not set - set it to the classic install."; exit 1; fi
  client_wtf="$client_wow_root/$WTF_DIR_NAME"
  client_account_root="$client_wtf/$ACCOUNT_DIR_NAME"
  if [[ ! -d "$client_account_root" ]]; then
    write_err "No WTF Account folder in the classic install: $client_account_root (\$$CLIENT_WOW_ENV)."
    exit 1
  fi
  main_account="$(resolve_source_account "$client_account_root" "$client_wtf" "$requested_account")"
  debug_note=""
  if $debug_mode; then debug_note=" - debug: printing the commands only"; fi
  write_info "Copying $client_account_root into $(printf '%s / ' "${clients[@]}" | sed 's| / $||') (account-wide files from $main_account)$debug_note"
  get_client_targets
  declare -A done_targets=()
  for target in "${client_targets[@]}"; do
    if [[ -n "${done_targets[$target]:-}" ]]; then continue; fi
    done_targets[$target]=1
    copy_wtf_into "$target" "$client_account_root" "$main_account"
  done
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

