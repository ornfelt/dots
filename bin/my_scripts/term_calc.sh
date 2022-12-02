#!/bin/bash
#$1 -e bash -c 'tmux attach || tmux' &
#$1 -e bash -c 'python3'

session="calc"

# Check if the session exists, discarding output
# We can check $? for the exit status (zero for success, non-zero for failure)
tmux has-session -t $session 2>/dev/null

if [ $? != 0 ]; then
	# Set up your session
	tmux new -d -s calc && tmux send-keys -t calc.0 "python3" Enter
fi

$1 -e bash -c 'tmux a -t calc; zsh'
