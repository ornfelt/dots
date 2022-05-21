#! /usr/bin/env zsh
mv ~/.zsh_history ~/.zsh_history_bad
strings -eS ~/.zsh_history_bad > ~/.zsh_history
fc -r ~/.zsh_history
rm ~/.zsh_history_bad
