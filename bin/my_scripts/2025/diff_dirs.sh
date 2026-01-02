#!/usr/bin/env bash

set -euo pipefail

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
  "llama2.c/build"
  "llama3.2.c/.git"
  "llama3.2.c/build"
  "__pycache__/"
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

# for measuring runtime
script_start_ms=$(date +%s%3N)

# Start / truncate the log and print header
echo "Comparison started at $(date)" | tee "$target_log"

echo "Comparing $dir1 <-> $dir2" | tee -a "$target_log"

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

printf "\nListing phase (find) took %d.%03d seconds (%d ms)\n" \
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

# Print summary and detailed lists - and respect should_skip_path
if [[ -z "$missing_in_2" && -z "$missing_in_1" ]]; then
  echo "[ok] Both directories contain the same files and directories." | tee -a "$target_log"
else
  if [[ -n "$missing_in_2" ]]; then
    echo "Entries in $dir1 missing in $dir2:" | tee -a "$target_log"

    # Filter with should_skip_path, then run your "top-level only" awk
    echo "$missing_in_2" \
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
    ' | tee -a "$target_log"
  fi

  if [[ -n "$missing_in_1" ]]; then
    echo "Entries in $dir2 missing in $dir1:" | tee -a "$target_log"

    echo "$missing_in_1" \
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
    ' | tee -a "$target_log"
  fi
fi

# print total runtime
script_end_ms=$(date +%s%3N)
script_elapsed_ms=$((script_end_ms - script_start_ms))
script_elapsed_sec=$((script_elapsed_ms / 1000))
script_elapsed_rem_ms=$((script_elapsed_ms % 1000))

printf "\nTotal runtime: %d.%03d seconds (%d ms)\n" \
  "$script_elapsed_sec" "$script_elapsed_rem_ms" "$script_elapsed_ms" | tee -a "$target_log"

