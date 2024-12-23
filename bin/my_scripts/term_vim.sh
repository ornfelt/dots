#!/usr/bin/env bash

export DISPLAY=:0

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <terminal> <file_path>"
    exit 1
fi

terminal="$1"
file_path="$2"

"$terminal" -e bash -c "nvim \"$file_path\"; exec zsh"

