#!/usr/bin/env bash

# allow path as first argument, else use current
if [ -n "$1" ]; then
  cd "$1" 2>/dev/null || exit 1
fi

# Must be inside git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 1
fi

branch=$(git symbolic-ref --short HEAD 2>/dev/null) || exit 1

git_status=$(git status --porcelain -b 2>/dev/null) || exit 1
first_line=${git_status%%$'\n'*}

# Any lines after the first?
lines=$(printf '%s\n' "$git_status" | wc -l)
has_changes=false
if [ "$lines" -gt 1 ]; then
  has_changes=true
fi

color='colour2'

# Remote state overrides
case "$first_line" in
  *diverged*)
    color='colour5' # magenta-ish
    ;;
  *behind*)
    color='colour1' # red
    ;;
  *ahead*)
    #color='colour12' # cyan-ish
    color='colour6' # cyan-ish
    ;;
esac

if [ "$has_changes" = true ]; then
  color='colour11'
fi

printf ' #[fg=%s]%s' "$color" "$branch"

