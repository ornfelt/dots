#
# ~/.bashrc
#

# If not running interactively, don't do anything
#[[ $- != *i* ]] && return

#PS1='[\u@\h \W]\$ '
#[ -f ~/.fzf.bash ] && source ~/.fzf.bash

alias ls='ls --color=auto'
alias config='/usr/bin/git --git-dir=/home/jonas/.cfg/ --work-tree=/home/jonas'
alias vim='nvim'
# alias grep='grep -ri --color'

export VISUAL=nvim;
export EDITOR=nvim;
#zsh
