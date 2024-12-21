#! /usr/bin/bash

if ! git rev-parse --verify upstream/master >/dev/null 2>&1; then
    echo "Error: 'upstream/master' does not exist. Please add it..."
    exit 1
fi

git diff upstream/master...master > diff_upstream.diff
git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff
git diff origin/new -- . ":(exclude)*.diff" ":(exclude)config.def.h" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_new.diff

