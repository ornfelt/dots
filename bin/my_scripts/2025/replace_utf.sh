#!/bin/bash

# Note: I used below script to fix azerothcore / trinity core db files
# (exported on arch via mariadb) to be able to import on debian. the scripts
# are saved in the db (debian) dirs but I don't need to run them again...
# for example: /media/my_files/my_docs/db_bkp/acore_250703_deb/replace_utf.sh

# Iterate over each .sql file in the current directory
for file in *.sql; do
    if [[ -f "$file" ]]; then  # Check if it's a file (and not a directory)
        echo "Processing $file"

        # Perform the sed replacements
        sed -i 's/utf8mb3_uca1400_ai_ci/utf8_general_ci/g' "$file"
        sed -i 's/utf8mb4_uca1400_ai_ci/utf8mb4_general_ci/g' "$file"

        echo "Finished processing $file"
    else
        echo "No .sql files found in the current directory."
    fi
done
