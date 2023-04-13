#If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/jonas/.oh-my-zsh"
export VISUAL=nvim
export EDITOR=nvim
export TESSDATA_PREFIX=/usr/local/share/tessdata

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="clean"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	archlinux
	extract
	z
	vi-mode
	colorize
	zsh-syntax-highlighting
	zsh-autosuggestions
	)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"


# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#dotfiles
#alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

#Config aliases
alias zshconf='nvim ~/.zshrc'
alias i3conf='nvim ~/.config/i3/config'

#General Aliases
alias jnb='jupyter notebook ~/Dev/Notebooks'
alias dev='cd ~/Dev'
#alias cat='bat'
#alias emacs='emacsclient -nw'
alias neofetch='neofetch --color_blocks off'
alias grootfetch='neofetch --w3m /home/jonas/.config/neofetch/groot.jpg'
alias tuxfetch='neofetch --ascii_distro tux'
alias diskspace='ncdu'
alias cb='clipboard'
alias tb='nc termbin.com 9999'
alias doomsync='~/.emacs.d/bin/doom sync && systemctl restart emacs --user'
alias vim='nvim'
alias xup='xrdb ~/.Xresources'
# alias grep='grep -rin --color'
alias vd='python -m visidata'
alias scripts='cd ~/.local/bin/my_scripts; ls'
alias .cnf='cd ~/.config; ls'
alias .cnfa='cd ~/.config/awesome; ls'
alias .cnfd='cd ~/.config/dwm; ls'
alias .cnfdb='cd ~/.config/dwmblocks; ls'
alias .cnfp='cd ~/.config/polybar; ls'
alias .cnfh='cd ~/.config/hypr; ls'
alias .pics='cd ~/Pictures; ls'
alias .docs='cd ~/Documents; ls'
alias .down='cd ~/Downloads; ls'
alias .dots='cd ~/Downloads/dotfiles; ls'
alias .ioq3='/home/jonas/Code/C/ioq3/build/release-linux-x86_64/ioquake3.x86_64 +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0'
alias .ioq32='/home/jonas/Code/C/ioq3/build/release-linux-x86_64_golden/ioquake3.x86_64 +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0'
alias .stk3='/home/jonas/Code/C/supertuxkart/stk-code/cmake_build_50/bin/supertuxkart'
alias lf='/home/jonas/.local/bin/lfub'

# use the vi navigation keys in menu completion
#bindkey -M menuselect 'h' vi-backward-char
#bindkey -M menuselect 'k' vi-up-line-or-history
#bindkey -M menuselect 'l' vi-forward-char
#bindkey -M menuselect 'j' vi-down-line-or-history


#neofetch --color_blocks off
#curl wttr.in/Skopje\?0 2> /dev/null
unsetopt BEEP

#nvm 
lazynvm() {
  unset -f nvm node npm npx
  export NVM_DIR=~/.nvm
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
  if [ -f "$NVM_DIR/bash_completion" ]; then
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
  fi
}

nvm() {
  lazynvm 
  nvm $@
}
 
node() {
  lazynvm
  node $@
}
 
npm() {
  lazynvm
  npm $@
}

npx() {
  lazynvm
  npx $@
}

fuzzyfind(){
	# If in tmux
	if [ -z "$TMUX" ]; then
		fzf
	else
		fzf-tmux -p
	fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

precmd() { eval "$PROMPT_COMMAND" }
export PROMPT_COMMAND="pwd > /tmp/whereami"
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export PATH="${PATH}:${HOME}/.local/bin/"
export PATH="${PATH}:${HOME}/.local/bin/my_scripts"
export LANG=en_US.UTF-8
export LANGUAGE=en
export LC_ALL=en_US.UTF-8 
#export ALPHAVANTAGE_API_KEY=AOUX3DK05GCWDMZ9

alias f='fuzzyfind'
bindkey '^ ' autosuggest-accept
LS_COLORS+=':ow=01;33'
~/.local/bin/my_scripts/hello.sh
