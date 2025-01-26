#If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
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
# alias zshconfig="mate $HOME/.zshrc"
# alias ohmyzsh="mate $HOME/.oh-my-zsh"

#dotfiles
#alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

#Config aliases
alias zshconf='nvim $HOME/.zshrc'
alias i3conf='nvim $HOME/.config/i3/config'

#General Aliases
alias jnb='jupyter notebook $HOME/Dev/Notebooks'
alias dev='cd $HOME/Dev'
#alias cat='bat'
#alias emacs='emacsclient -nw'
alias neofetch='neofetch --color_blocks off'
alias grootfetch='neofetch --w3m $HOME/.config/neofetch/groot.jpg'
alias tuxfetch='neofetch --ascii_distro tux'
alias diskspace='ncdu'
alias cb='clipboard'
alias tb='nc termbin.com 9999'
alias doomsync='$HOME/.emacs.d/bin/doom sync && systemctl restart emacs --user'
alias vim='nvim'
alias lua='lua5.4'
alias python='python3'
alias xup='xrdb $HOME/.Xresources'
# alias grep='grep -rin --color'
alias vd='python -m visidata'
alias lf='$HOME/.local/bin/lfub'
alias .scripts='cd $HOME/.local/bin/my_scripts; ls'
alias .cnf='cd $HOME/.config; ls'
alias .cnfa='cd $HOME/.config/awesome; ls'
alias .cnfd='cd $HOME/.config/dwm; ls'
alias .cnfdb='cd $HOME/.config/dwmblocks; ls'
alias .cnfh='cd $HOME/.config/hypr; ls'
alias .cnfi='cd $HOME/.config/i3; ls'
alias .cnfp='cd $HOME/.config/picom; ls'
alias .cnfn='cd $HOME/.config/nvim; ls'
alias .cnfw='cd $HOME/.config/wezterm; ls'
alias .cnfl='cd $HOME/.config/lf; ls'
alias .cnfr='cd $HOME/.config/ranger; ls'
alias .cnfs='cd $HOME/.config/st; ls'
alias .cnfy='cd $HOME/.config/yazi; ls'
alias .pics='cd $HOME/Pictures; ls'
alias .docs='cd $HOME/Documents; ls'
alias .down='cd $HOME/Downloads; ls'
alias .cdc='cd $code_root_dir; ls'
alias .cdn='cd $HOME/Documents/my_notes; ls'
alias .cdp='cd $HOME/Documents/windows_dots; ls'
alias .dots='cd $HOME/Downloads/dotfiles; ls'
alias .ioq3='$HOME/Code2/C/ioq3/build/release-linux-x86_64/ioquake3.x86_64 +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0'
alias .ioq32='$HOME/Code2/C/ioq3/build/release-linux-x86_64_golden/ioquake3.x86_64 +set sv_pure 0 +set vm_game 0 +set vm_cgame 0 +set vm_ui 0'
alias .stk='$HOME/Code2/C++/stk-code/build/bin/supertuxkart'
alias .openjk='$HOME/.local/share/openjk/JediAcademy/openjk.x86_64'
alias .openjk_sp='$HOME/.local/share/openjk/JediAcademy/openjk_sp.x86_64'
alias .openjo_sp='$HOME/.local/share/openjk/JediOutcast/openjo_sp.x86_64'
alias .japp='$HOME/.local/share/openjk/JediAcademy/openjk.x86_64 +set fs_game "japlus"'
alias .acore='cd $HOME/acore/bin; pwd; ls'
alias .acore_update='cd $HOME/Code2/C++/AzerothCore-wotlk-with-NPCBots && git pull && cd modules/mod-eluna && git pull && cd ../..'
alias .tcore='cd $HOME/tcore/bin; pwd; ls'
alias .tcore_update='cd $HOME/Code2/C++/Trinitycore-3.3.5-with-NPCBots && git pull'
alias .cmangos='cd $HOME/cmangos/run/bin; ls'
alias .cmangos_update='cd $HOME/Code2/C++/mangos-classic && git pull && cd src/modules/PlayerBots && git pull && cd ../../..'
alias .cmangos_tbc='cd $HOME/cmangos-tbc/run/bin; pwd; ls'
alias .cmangos_tbc_update='cd $HOME/Code2/C++/mangos-tbc && git pull && cd src/modules/PlayerBots && git pull && cd ../../..'
alias .vmangos='cd $HOME/vmangos/bin; pwd; ls'
alias .vmangos_update='cd $HOME/Code2/C++/core && git pull; pwd; ls'
alias .mangoszero='cd $HOME/mangoszero/run/bin; pwd; ls'
alias .mangoszero_update='cd $HOME/Code2/C++/server && git pull; pwd; ls'
alias .wow='sh $HOME/.local/bin/my_scripts/wow.sh'
alias .llama="$HOME/.local/bin/my_scripts/llama.sh"
alias .git_push="$HOME/.local/bin/my_scripts/git_push.sh"
alias .git_pull="$HOME/.local/bin/my_scripts/git_pull.sh"

playermap ()
{
    if [ -n "$1" ]; then
        echo "Launching tcore playermap: php -S localhost:8000"
        #cd $HOME/Code2/Python/wander_nodes_util/tcore_map/playermap && php -S localhost:8000;
        cd $HOME/Code2/Python/wander_nodes_util/tcore_map/playermap && php -S $(ip addr show | grep -v 'inet6' | grep -v 'inet 127' | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d/ -f1):8000;
    else
        echo "Launching acore playermap: php -S localhost:8000"
        cd $HOME/Code2/Python/wander_nodes_util/acore_map/playermap && php -S $(ip addr show | grep -v 'inet6' | grep -v 'inet 127' | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d/ -f1):8000;
    fi
}
alias .playermap='playermap'

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
  export NVM_DIR=$HOME/.nvm
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

mkcdir ()
{
    mkdir -p -- "$1" &&
       cd -P -- "$1"
}

# fzf
if command -v fzf >/dev/null 2>&1; then
    fzf_version=$(fzf --version | awk '{print $1}')
    fzf_major_version=$(echo "$fzf_version" | awk -F. '{print $1}')
    fzf_minor_version=$(echo "$fzf_version" | awk -F. '{print $2}')

    if [ "$fzf_minor_version" -lt 48 ]; then
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    else
        [ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
    fi
else
    echo "fzf is not installed"
fi
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_CTRL_T_COMMAND='find . -type f -name ".*" -o -type f -name "*"'

precmd() { eval "$PROMPT_COMMAND" }
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
export wow_dir="/mnt/new/wow"
export wow_classic_dir="/mnt/new/wow_classic"
export wow_tbc_dir="/mnt/new/wow_tbc"
export wow_cata_dir="/mnt/new/cata"
#export PATH="${PATH}:$HOME/.fzf/bin"

export LANG=en_US.UTF-8
export LANGUAGE=en
export LC_ALL=en_US.UTF-8 

alias f='fuzzyfind'
bindkey '^ ' autosuggest-accept
LS_COLORS+=':ow=01;33'
$HOME/.local/bin/my_scripts/hello.sh

source $HOME/.bash_profile
#if [ -f "$HOME/.cargo/env" ]; then
#    source "$HOME/.cargo/env"
#fi

