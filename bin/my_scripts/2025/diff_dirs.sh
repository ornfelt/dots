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

# Start / truncate the log and print header
echo "Comparison started at $(date)" | tee "$target_log"

echo "Comparing $dir1 <-> $dir2" | tee -a "$target_log"

# Create temporary files for listings
tmp1=$(mktemp)
tmp2=$(mktemp)

# Ensure cleanup on exit
#trap 'rm -f "$tmp1" "$tmp2"' EXIT

# Generate sorted relative paths for each directory
find "$dir1" -printf '%P\n' | sort > "$tmp1"
find "$dir2" -printf '%P\n' | sort > "$tmp2"

echo | tee -a "$target_log"

# Compute missing entries
missing_in_2=$(comm -23 "$tmp1" "$tmp2")
missing_in_1=$(comm -13 "$tmp1" "$tmp2")

# Print summary and detailed lists
if [[ -z "$missing_in_2" && -z "$missing_in_1" ]]; then
  echo "[ok] Both directories contain the same files and directories." | tee -a "$target_log"
else
  if [[ -n "$missing_in_2" ]]; then
    echo "Entries in $dir1 missing in $dir2:" | tee -a "$target_log"
    #echo "$missing_in_2" | tee -a "$target_log"

    # Smarter way of printing by only printing top-level missing paths by
    # checking each new path against previously seen paths... If it's a subpath
    # of something already printed (e.g., a/b/c.txt under a/), it's skipped.
    echo "$missing_in_2" | awk '
    {
        for (i in paths) {
            if (index($0, paths[i]) == 1 && length($0) > length(paths[i]) && substr($0, length(paths[i])+1, 1) == "/") next
        }
        paths[++count] = $0
        print
    }
    ' | tee -a "$target_log"

  fi
  if [[ -n "$missing_in_1" ]]; then
    echo "Entries in $dir2 missing in $dir1:" | tee -a "$target_log"
    #echo "$missing_in_1" | tee -a "$target_log"

    echo "$missing_in_1" | awk '
    {
        for (i in paths) {
            if (index($0, paths[i]) == 1 && length($0) > length(paths[i]) && substr($0, length(paths[i])+1, 1) == "/") next
        }
        paths[++count] = $0
        print
    }
    ' | tee -a "$target_log"

  fi
fi

