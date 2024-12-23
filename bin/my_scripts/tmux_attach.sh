#!/usr/bin/env bash

#urxvt -e bash -c 'tmux attach || tmux; zsh'
$1 -e bash -c 'tmux attach -t sess || tmux new -s sess; zsh'

