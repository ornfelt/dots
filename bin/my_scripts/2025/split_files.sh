#!/bin/bash

# Hardcoded input path
input_dir="/media2/my_files/my_docs/img/pin/Anime"
#input_dir="/media2/my_files/my_docs/img/pin/Anime Art"
#input_dir="/media2/my_files/my_docs/img/pin/Appa"
#input_dir="/media2/my_files/my_docs/img/pin/Archer"
#input_dir="/media2/my_files/my_docs/img/pin/Assassin’s"
#input_dir="/media2/my_files/my_docs/img/pin/Avatar"
#input_dir="/media2/my_files/my_docs/img/pin/Druid"
#input_dir="/media2/my_files/my_docs/img/pin/Fantasy art"
#input_dir="/media2/my_files/my_docs/img/pin/Monsters"
#input_dir="/media2/my_files/my_docs/img/pin/Pokemon"
#input_dir="/media2/my_files/my_docs/img/pin/priest"
#input_dir="/media2/my_files/my_docs/img/pin/Programming"
#input_dir="/media2/my_files/my_docs/img/pin/Shooter"
#input_dir="/media2/my_files/my_docs/img/pin/Star wars"
#input_dir="/media2/my_files/my_docs/img/pin/Warcraft art"
#input_dir="/media2/my_files/my_docs/img/pin/Wizardry"
#input_dir="/media2/my_files/my_docs/img/wow/imgur_tbc"
#input_dir="/media2/my_files/my_docs/img/wow/imgur_vanilla"
#input_dir="/media2/my_files/my_docs/img/wow/imgur_wotlk"

chunk_size=50

# Get sorted list of regular files
mapfile -t files < <(find "$input_dir" -maxdepth 1 -type f | sort)

total_files=${#files[@]}

# If total files <= chunk size, do nothing
if (( total_files <= chunk_size )); then
  echo "Only $total_files files. No need to split."
  exit 0
fi

# Calculate number of needed directories
num_dirs=$(( (total_files + chunk_size - 1) / chunk_size ))

echo "Total files: $total_files"
echo "Creating $num_dirs directories..."

for (( i=0; i<num_dirs; i++ )); do
  dir="$input_dir/$((i + 1))"
  mkdir -p "$dir"

  start=$((i * chunk_size))
  end=$((start + chunk_size - 1))
  if (( end >= total_files )); then
    end=$((total_files - 1))
  fi

  echo "Moving files ${start} to ${end} into $dir"
  for (( j=start; j<=end; j++ )); do
    mv "${files[j]}" "$dir/"
  done
done

echo "Done."

