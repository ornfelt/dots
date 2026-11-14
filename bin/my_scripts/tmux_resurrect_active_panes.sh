#!/usr/bin/env bash
# tmux_resurrect_active_panes.sh - post-restore-all hook for tmux-resurrect
# (@resurrect-hook-post-restore-all in ~/.tmux.conf).
#
# resurrect's restore.sh selects each window's active pane with a bare pane index
# (select-pane -t 3), which tmux resolves against the pane the restore runs in, so
# only the current window got its active pane back ("can't find pane: 3" for the
# rest). This selects them again with full session:window.pane targets; -Z keeps a
# zoomed window zoomed (on the right pane).
#
# Usage examples:
# what the hook runs, after a restore:
# tmux_resurrect_active_panes.sh
#
# a specific save file, or a resurrect dir (its "last" file):
# tmux_resurrect_active_panes.sh ~/.local/share/tmux/resurrect/last
# tmux_resurrect_active_panes.sh --path ~/.local/share/tmux/resurrect
#
# print the tmux commands instead of running them:
# tmux_resurrect_active_panes.sh --show-cmd

RESET='\033[0m'
RED='\033[31m'
CYAN='\033[36m'

write_err()  { echo -e "${RED}${1}${RESET}" >&2; }
write_info() { echo -e "${CYAN}${1}${RESET}"; }

LAST_FILE=last
show_cmd=0
path=""

while [ $# -gt 0 ]; do
    case "$1" in
        --show-cmd) show_cmd=1 ;;
        -p|--path) shift; path="$1" ;;
        -h|--help) sed -n '2,20s/^# \{0,1\}//p' "$0"; exit 0 ;;
        *) path="$1" ;;
    esac
    shift
done

# The save file: as resurrect's helpers.sh finds its dir
if [ -z "$path" ]; then
    path=$(tmux show-option -gqv @resurrect-dir 2>/dev/null)
    path=$(printf '%s' "$path" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g")
    if [ -z "$path" ]; then
        if [ -d "$HOME/.tmux/resurrect" ]; then
            path="$HOME/.tmux/resurrect"
        else
            path="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
        fi
    fi
fi
[ -d "$path" ] && path="$path/$LAST_FILE"
if [ ! -f "$path" ]; then
    write_err "No resurrect save file: $path"
    exit 1
fi

# pane lines: session, window, ..., pane index (6), ..., pane_active (9; 8 in older
# saves without the pane title field)
targets=$(awk -F'\t' '$1 == "pane" && $(NF >= 11 ? 9 : 8) == 1 { print $2 ":" $3 "." $6 }' "$path")

if [ "$show_cmd" = 1 ]; then
    write_info "# $0 $path"
    printf '%s\n' "$targets" | while IFS= read -r target; do
        [ -n "$target" ] && printf 'tmux select-pane -Z -t %q\n' "$target"
    done
    exit 0
fi

printf '%s\n' "$targets" | while IFS= read -r target; do
    [ -n "$target" ] && tmux select-pane -Z -t "$target" 2>/dev/null
done
exit 0
