#!/usr/bin/env bash

if [ -z "$my_notes_path" ]; then
    echo "Environment variable 'my_notes_path' is not set."
    exit 1
fi

#python "$my_notes_path/scripts/build.py"
# Forward all script arguments to python
python "$my_notes_path/scripts/build.py" "$@"
