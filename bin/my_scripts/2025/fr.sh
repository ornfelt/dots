
#!/usr/bin/env bash

if [ -z "$my_notes_path" ]; then
    echo "Environment variable 'my_notes_path' is not set."
    exit 1
fi

"$my_notes_path/scripts/replace/find_replace.sh" "$@"
# only doing above should be enough, but below will also handle exit-code forwarding
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "find_replace.sh failed with exit code $exit_code."
fi

exit $exit_code
