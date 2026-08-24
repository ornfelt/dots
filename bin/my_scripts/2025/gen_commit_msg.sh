#!/usr/bin/env bash

if [ -z "$code_root_dir" ]; then
    echo "Environment variable 'code_root_dir' is not set."
    exit 1
fi

#python "$code_root_dir/Code2/General/utils/ai/git_commit_msg/gen_commit_msg.py"
# Forward all script arguments to python
python "$code_root_dir/Code2/General/utils/ai/git_commit_msg/gen_commit_msg.py" "$@"

