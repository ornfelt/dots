#!/usr/bin/env bash

set -euo pipefail

# Colors + log helpers
c_ok="\033[32m"   # green
c_err="\033[31m"  # red
c_warn="\033[33m" # darkyellow-ish
c_info="\033[36m" # cyan
c_info_alt="\033[35m" # magenta
c_reset="\033[0m"

tee_ok()   { echo -e "${c_ok}$*${c_reset}" | tee -a "$target_log"; }
tee_err()  { echo -e "${c_err}$*${c_reset}" | tee -a "$target_log"; }
tee_warn() { echo -e "${c_warn}$*${c_reset}" | tee -a "$target_log"; }
tee_info() { echo -e "${c_info}$*${c_reset}" | tee -a "$target_log"; }

# Hard-coded dirs to compare

#dir1="/media2/my_files/my_docs"
#dir2="/media/my_files/my_docs"

#dir1="/home/jonas/Downloads/yt/test/dir1"
#dir2="/home/jonas/Downloads/yt/test/dir2"

#dir1="/media2/Movies"
#dir2="/media/Movies"

#dir1="/media2/2025/mpq"
#dir2="/media/2025/mpq"

#dir1="/media2/my_files"
#dir2="/media/my_files"

#dir1="/media2/2024"
#dir2="/media/2024"

#dir1="/media2/2025"
#dir2="/media/2025"

dir1="/media2"
dir2="/media"

# Log file
target_log="diff_check.log"

#IGNORE_PATH_FILTERS=false
IGNORE_PATH_FILTERS=true

# Paths that cause "starts with" skip
IGNORE_PREFIXES=(
  "\$RECYCLE.BIN/"
  "2024/wow/"
  ".Trash-1000/"
  "System Volume Information/"
)

# Paths that cause "contains" skip
IGNORE_CONTAINS=(
  "node_modules/"
  "llama2.c/.git"
  "llama3.2.c/.git"
  "torchless/.git"
  "llama2.c/build"
  "llama3.2.c/build"
  "torchless/build"
  "__pycache__/"
  ".git/",
  "build/",
)

# Paths that cause "equals" skip
IGNORE_EQUALS=(
  #"Movies"
  #"recordings"
  "Magician Launcher.app"
  "Magician Launcher.exe"
  "RootCA.crt"
  "Program.puml"
  "SamsungPortableSSD_Setup_Mac_1.0.pkg"
  "SamsungPortableSSD_Setup_Win_1.0.exe"
  "Samsung Portable SSD SW for Android.txt"
)

# Whitelisted paths: these are expected differences and will be printed in a
# non-bad color (cyan) instead of red.  Matches exact path or anything under it.
WHITELIST_PATHS=(
  "Install Western Digital Software for Mac.dmg"
  "Install Western Digital Software for Windows.exe"
  "Movies/Series/Anime/Boku No Hero Academia - My Hero Academia"
  "Movies/Series/Anime/Kimetsu no Yaiba - Demon Slayer"
  "Movies/Series/Anime/made_in_abyss"
  "Movies/Series/Anime/Naruto"
  "Movies/Series/Anime/Re Zero - kara Hajimeru Isekai Seikatsu - Starting Life in Another World"
  "Movies/Series/Anime/Shingeki no Kyojin - Attack on Titan"
  "Movies/Series/Anime/Vinland Saga"
  "my_files/my_docs/ai/models/llama3.2.c/data"
  "my_files/my_docs/ai/models/llama3.2.c/out/cs"
  "my_files/my_docs/ai/models/llama3.2.c/pcre.h"
  "my_files/my_docs/ai/models/llama3.2.c/run.exe"
  "my_files/my_docs/ai/models/llama3.2.c/run.obj"
  "my_files/my_docs/ai/models/llama3.2.c/win.obj"
  "my_files/my_docs/ai/models/llama3.2.c/out/Llama3.2-3B.bin"
  "my_files/my_docs/ai/models/llama3.2.c/out/Llama3.2-3B-Instruct.bin"
  "my_files/my_docs/ai/models/torchless"
  "p"
  "p2"
)

should_skip_path_old() {
  local path="$1"

  # If filtering disabled, never skip
  if [[ "$IGNORE_PATH_FILTERS" != true ]]; then
    return 1
  fi

  # starts with prefixes
  for p in "${IGNORE_PREFIXES[@]}"; do
    if [[ "$path" == "$p"* ]]; then
      return 0
    fi
  done

  # contains substrings
  for p in "${IGNORE_CONTAINS[@]}"; do
    if [[ "$path" == *"$p"* ]]; then
      return 0
    fi
  done

  # equals specific names
  for p in "${IGNORE_EQUALS[@]}"; do
    if [[ "$path" == "$p" ]]; then
      return 0
    fi
  done

  return 1
}
# py/cs prunes IGNORE_EQUALS during traversal (for example: os.walk never
# descends into it). This should replicate it.
should_skip_path() {
  local path="$1"

  # If filtering disabled, never skip
  if [[ "$IGNORE_PATH_FILTERS" != true ]]; then
    return 1
  fi

  # starts with prefixes
  for p in "${IGNORE_PREFIXES[@]}"; do
    # If prefix ends with "/", also skip the directory name itself (without "/")
    if [[ "$p" == */ ]]; then
      local p_dir="${p%/}"
      if [[ "$path" == "$p_dir" || "$path" == "$p"* ]]; then
        return 0
      fi
    else
      if [[ "$path" == "$p"* ]]; then
        return 0
      fi
    fi
  done

  # contains substrings
  for p in "${IGNORE_CONTAINS[@]}"; do
    if [[ "$path" == *"$p"* ]]; then
      return 0
    fi
  done

  # equals specific names (and anything under them)
  for p in "${IGNORE_EQUALS[@]}"; do
    if [[ "$path" == "$p" || "$path" == "$p/"* ]]; then
      return 0
    fi
  done

  return 1
}

# Check if a path matches any whitelisted entry (exact or child of)
is_whitelisted() {
  local path="$1"
  for w in "${WHITELIST_PATHS[@]}"; do
    if [[ "$path" == "$w" || "$path" == "$w/"* ]]; then
      return 0
    fi
  done
  return 1
}

# for measuring runtime
script_start_ms=$(date +%s%3N)

# Start / truncate the log and print header
: > "$target_log"
tee_info "Comparison started at $(date)"
tee_info "Comparing $dir1 <-> $dir2"

# Create temporary files for listings
tmp1=$(mktemp)
tmp2=$(mktemp)

# Ensure cleanup on exit
#trap 'rm -f "$tmp1" "$tmp2"' EXIT

# timing: find phase
find_start_ms=$(date +%s%3N)

# Generate sorted relative paths for each directory
find "$dir1" -printf '%P\n' | sort > "$tmp1"
find "$dir2" -printf '%P\n' | sort > "$tmp2"

find_end_ms=$(date +%s%3N)
find_elapsed_ms=$((find_end_ms - find_start_ms))
find_elapsed_sec=$((find_elapsed_ms / 1000))
find_elapsed_rem_ms=$((find_elapsed_ms % 1000))

printf "\n${c_info}Listing phase (find) took %d.%03d seconds (%d ms)${c_reset}\n" \
  "$find_elapsed_sec" "$find_elapsed_rem_ms" "$find_elapsed_ms" | tee -a "$target_log"

echo | tee -a "$target_log"

# Compute missing entries
missing_in_2=$(comm -23 "$tmp1" "$tmp2")
missing_in_1=$(comm -13 "$tmp1" "$tmp2")

# Print summary and detailed lists
#if [[ -z "$missing_in_2" && -z "$missing_in_1" ]]; then
#  echo "[ok] Both directories contain the same files and directories." | tee -a "$target_log"
#else
#  if [[ -n "$missing_in_2" ]]; then
#    echo "Entries in $dir1 missing in $dir2:" | tee -a "$target_log"
#    #echo "$missing_in_2" | tee -a "$target_log"
#
#    # Smarter way of printing by only printing top-level missing paths by
#    # checking each new path against previously seen paths... If it's a subpath
#    # of something already printed (e.g., a/b/c.txt under a/), it's skipped.
#    echo "$missing_in_2" | awk '
#    {
#        for (i in paths) {
#            if (index($0, paths[i]) == 1 && length($0) > length(paths[i]) && substr($0, length(paths[i])+1, 1) == "/") next
#        }
#        paths[++count] = $0
#        print
#    }
#    ' | tee -a "$target_log"
#
#  fi
#  if [[ -n "$missing_in_1" ]]; then
#    echo "Entries in $dir2 missing in $dir1:" | tee -a "$target_log"
#    #echo "$missing_in_1" | tee -a "$target_log"
#
#    echo "$missing_in_1" | awk '
#    {
#        for (i in paths) {
#            if (index($0, paths[i]) == 1 && length($0) > length(paths[i]) && substr($0, length(paths[i])+1, 1) == "/") next
#        }
#        paths[++count] = $0
#        print
#    }
#    ' | tee -a "$target_log"
#
#  fi
#fi

# Counters for summary
count_unexpected=0
count_whitelisted=0

# Print summary and detailed lists - and respect should_skip_path
if [[ -z "$missing_in_2" && -z "$missing_in_1" ]]; then
  tee_ok "[ok] Both directories contain the same files and directories."
else
  if [[ -n "$missing_in_2" ]]; then
    tee_warn "Entries in $dir1 missing in $dir2:"

    # Filter with should_skip_path, then run your "top-level only" awk
    filtered=$(echo "$missing_in_2" \
    | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if should_skip_path "$line"; then
          continue
        fi
        printf '%s\n' "$line"
      done \
    | awk '
      {
          for (i in paths) {
              if (index($0, paths[i]) == 1 &&
                  length($0) > length(paths[i]) &&
                  substr($0, length(paths[i])+1, 1) == "/") next
          }
          paths[++count] = $0
          print
      }
    ')

    if [[ -n "$filtered" ]]; then
      while IFS= read -r entry; do
        if is_whitelisted "$entry"; then
          tee_info "  $entry  (whitelisted)"
          ((count_whitelisted++)) || true
        else
          tee_err "  $entry"
          ((count_unexpected++)) || true
        fi
      done <<< "$filtered"
    fi
  fi

  if [[ -n "$missing_in_1" ]]; then
    tee_warn "Entries in $dir2 missing in $dir1:"

    filtered=$(echo "$missing_in_1" \
    | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if should_skip_path "$line"; then
          continue
        fi
        printf '%s\n' "$line"
      done \
    | awk '
      {
          for (i in paths) {
              if (index($0, paths[i]) == 1 &&
                  length($0) > length(paths[i]) &&
                  substr($0, length(paths[i])+1, 1) == "/") next
          }
          paths[++count] = $0
          print
      }
    ')

    if [[ -n "$filtered" ]]; then
      while IFS= read -r entry; do
        if is_whitelisted "$entry"; then
          tee_info "  $entry  (whitelisted)"
          ((count_whitelisted++)) || true
        else
          tee_err "  $entry"
          ((count_unexpected++)) || true
        fi
      done <<< "$filtered"
    fi
  fi
fi

# Print difference summary
echo | tee -a "$target_log"
if (( count_unexpected == 0 && count_whitelisted == 0 )); then
  tee_ok "[ok] No differences found."
elif (( count_unexpected == 0 )); then
  tee_ok "[ok] All differences are whitelisted ($count_whitelisted whitelisted)."
else
  tee_err "[!!] $count_unexpected unexpected difference(s) found ($count_whitelisted whitelisted)."
fi

# print total runtime
script_end_ms=$(date +%s%3N)
script_elapsed_ms=$((script_end_ms - script_start_ms))
script_elapsed_sec=$((script_elapsed_ms / 1000))
script_elapsed_rem_ms=$((script_elapsed_ms % 1000))

printf "\n${c_info}Total runtime: %d.%03d seconds (%d ms)${c_reset}\n" \
  "$script_elapsed_sec" "$script_elapsed_rem_ms" "$script_elapsed_ms" | tee -a "$target_log"

