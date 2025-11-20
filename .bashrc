#
# ~/.bashrc
#

# If not running interactively, don't do anything
#[[ $- != *i* ]] && return

#PS1='[\u@\h \W]\$ '
#[ -f ~/.fzf.bash ] && source ~/.fzf.bash

alias ls='ls --color=auto'
alias vim='nvim'
alias lua='lua5.4'
alias python='python3'
#alias config='/usr/bin/git --git-dir=/home/jonas/.cfg/ --work-tree=/home/jonas'
# alias grep='grep -ri --color'

export VISUAL=nvim;
export EDITOR=nvim;
#zsh

export PROMPT_COMMAND="pwd > /tmp/whereami"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export PATH="${PATH}:${HOME}/.local/bin/"
export PATH="${PATH}:${HOME}/.local/bin/my_scripts"
#export PATH="${PATH}:${HOME}/.local/lib/"
export PATH="${PATH}:/sbin"
export PATH="${PATH}:${HOME}/Code/f#/FsAutoComplete/src/FsAutoComplete/bin/Release/net6.0"
export PATH="${PATH}:$HOME/Downloads/lsp/jdtls/bin"
export PATH="${PATH}:$HOME/Downloads/lsp/lua/bin"
export OMNISHARP_PATH="/usr/lib/omnisharp-roslyn/"
export my_notes_path="$HOME/Documents/my_notes"
export code_root_dir="$HOME"
#export PATH="${PATH}:$HOME/.fzf/bin"

export CMAKE_POLICY_VERSION_MINIMUM=3.5

#if command -v syndaemon &> /dev/null; then
#    # Disable touchpad while typing
#    #syndaemon -i 1.0 -K -R -d
#    # Disable clicks while typing
#    syndaemon -i 1.0 -t -K -R -d
#fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

