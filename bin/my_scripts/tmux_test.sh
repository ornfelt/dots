#! /usr/bin/bash

###
# Test without variables
###
#if [ "$(tmux display-message -p '#{pane_at_right}')" -eq 0 ] && ! tmux list-panes -F '#F' | grep -q 'Z'; then
#    tmux select-pane -R
#else
#    tmux send-keys M-h
#fi

###
# Test with variables
###
is_zoomed=$(tmux list-panes -F '#F' | grep -q 'Z' && echo 1 || echo 0)
echo "DEBUG: is_zoomed=$is_zoomed"

###
# Test top pane
###
#pane_at_top=$(tmux display-message -p '#{pane_at_top}')
#echo "DEBUG: pane_at_top=$pane_at_top"
#
#if [ "$pane_at_top" -eq 0 ] && [ "$is_zoomed" -eq 0 ]; then
#    echo "DEBUG: Selecting pane above"
#    tmux select-pane -U
#else
#    #echo "DEBUG: Sending keys M-k"
#    #tmux send-keys M-k
#    echo "DEBUG: Sending keys Ctrl-w followed by k"
#    tmux send-keys C-w k
#fi

###
# Test bottom pane
###
pane_at_bottom=$(tmux display-message -p '#{pane_at_bottom}')
echo "DEBUG: pane_at_bottom=$pane_at_bottom"

if [ "$pane_at_bottom" -eq 0 ] && [ "$is_zoomed" -eq 0 ]; then
    echo "DEBUG: Selecting pane below"
    tmux select-pane -D
else
    #echo "DEBUG: Sending keys M-j"
    #tmux send-keys M-j
    echo "DEBUG: Sending keys Ctrl-w followed by j"
    tmux send-keys C-w j
fi

