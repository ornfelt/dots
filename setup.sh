#!/bin/bash

# {my_notes_path}/linux/setup_notes.txt

# Colors (ANSI escape codes)
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DARKGRAY='\033[90m'

# Logging helpers
# %b makes printf interpret \033 escapes properly
#log_ok()    { printf "%b[ok]%b %b\n"   "$CYAN"   "$RESET" "$*"; }
#log_warn()  { printf "%b[warn]%b %b\n" "$YELLOW" "$RESET" "$*"; }
#log_err()   { printf "%b[err]%b %b\n"  "$RED"    "$RESET" "$*"; }
#log_info()  { printf "%b[i]%b %b\n"    "$DARKGRAY" "$RESET" "$*"; }
#log_step()  { printf "\n%b==>%b %b\n"  "$BLUE"   "$RESET" "$*"; }
#log_sep() { log_info "--------------------------------------------------------"; }
#log_q() { printf "\n%b[q]%b %b\n" "$MAGENTA" "$RESET" "$*"; }
# color the entire line
log_ok()    { printf "%b[ok] %b%b\n"   "$CYAN"    "$*" "$RESET"; }
log_warn()  { printf "%b[warn] %b%b\n" "$YELLOW"  "$*" "$RESET"; }
log_err()   { printf "%b[err] %b%b\n"  "$RED"     "$*" "$RESET"; }
log_info()  { printf "%b[i] %b%b\n"    "$DARKGRAY" "$*" "$RESET"; }
log_step()  { printf "\n%b==> %b%b\n"  "$BLUE"    "$*" "$RESET"; }
log_q()     { printf "\n%b[q] %b%b\n"  "$MAGENTA" "$*" "$RESET"; }

say()       { printf "%b\n" "$*"; }
die()       { log_err "$*"; exit 1; }

log_step "Setting up config files!"

CURRENT_DIR="$PWD"

# Setup required dirs
mkdir -p "$HOME/.config/" || die "Failed to create ~/.config"
mkdir -p $HOME/.config/wezterm
mkdir -p $HOME/.config/gtk-3.0
mkdir -p $HOME/.local/bin/
mkdir -p $HOME/Documents $HOME/Downloads $HOME/Pictures/Wallpapers
mkdir -p $HOME/Code/c $HOME/Code/c++ $HOME/Code/c# $HOME/Code/go $HOME/Code/ml $HOME/Code/js $HOME/Code/python $HOME/Code/rust $HOME/Code2/C $HOME/Code2/C++ $HOME/Code2/C# $HOME/Code2/General $HOME/Code2/Go $HOME/Code2/Javascript $HOME/Code2/Lua $HOME/Code2/Sql $HOME/Code2/Python $HOME/Code2/Wow/tools

# Copy stuff
cp -r .config/awesome/ $HOME/.config/
cp -r .config/cava/ $HOME/.config/
cp -r .config/conky/ $HOME/.config/
cp -r .config/dmenu/ $HOME/.config/
cp -r .config/dwm/ $HOME/.config/
cp -r .config/dwmblocks/ $HOME/.config/
cp -r .config/eww/ $HOME/.config/
cp -r .config/hypr/ $HOME/.config/
cp -r .config/i3/ $HOME/.config/
cp -r .config/kitty/ $HOME/.config/
cp -r .config/lf/ $HOME/.config/
cp -r .config/neofetch/ $HOME/.config/
cp -r .config/nvim/ $HOME/.config/
cp -r .config/picom/ $HOME/.config/
cp -r .config/pip/ $HOME/.config/
cp -r .config/polybar/ $HOME/.config/
cp -r .config/ranger/ $HOME/.config/
cp -r .config/rofi/ $HOME/.config/
cp -r .config/st/ $HOME/.config/
cp -r .config/zathura/ $HOME/.config/
cp -r .config/zsh/ $HOME/.config/
cp .config/mimeapps.list $HOME/.config/
cp .config/gtk-3.0/bookmarks $HOME/.config/gtk-3.0/

#cp -r .config/yazi/ $HOME/.config/
mkdir -p "$HOME/.config/yazi"
for entry in .config/yazi/*; do
    # Only copy files
    if [ -f "$entry" ]; then
        cp "$entry" "$HOME/.config/yazi/"
    fi
done  

cp -r .dwm/ $HOME/
cp -r bin/cron $HOME/.local/bin/
cp -r bin/dwm_keybinds $HOME/.local/bin/
cp -r bin/i3-used-keybinds $HOME/.local/bin/
cp -r bin/my_scripts $HOME/.local/bin/
cp -r bin/statusbar $HOME/.local/bin/
cp -r bin/widgets $HOME/.local/bin/
cp -r bin/xyz $HOME/.local/bin/
cp bin/lfub $HOME/.local/bin/
cp bin/lf-select $HOME/.local/bin/
cp bin/greenclip $HOME/.local/bin/ 2>/dev/null

cp -r installation/ $HOME/Documents/
cp Screenshots/space.jpg $HOME/Pictures/Wallpapers/

cp .bashrc $HOME/.bashrc
cp .tmux.conf $HOME/.tmux.conf
cp .wezterm.lua $HOME/.wezterm.lua
if [[ -f "$HOME/.xinitrc" ]]; then
  sudo chown "$USER:$USER" "$HOME/.xinitrc"
  log_ok "chown ~/.xinitrc"
else
  log_warn "No ~/.xinitrc to chown, skipping."
fi
cp .xinitrc $HOME/.xinitrc
sudo chown "$USER:$USER" "$HOME/.xinitrc"
cp .Xresources $HOME/.Xresources
cp .Xresources_cat $HOME/.Xresources_cat
cp .zshrc $HOME/.zshrc

# Update alacritty, preserving custom font size (if any)
DEFAULT_FONT_SIZE="7.0"
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
YML_FILE="$ALACRITTY_CONFIG_DIR/alacritty.yml"
TOML_FILE="$ALACRITTY_CONFIG_DIR/alacritty.toml"

# Check for config directory and YAML file
if [[ -d "$ALACRITTY_CONFIG_DIR" && -f "$YML_FILE" ]]; then
    CURRENT_FONT_SIZE=$(grep -oP 'size:\s*\K[0-9.]+' "$YML_FILE")
else
    log_warn "Alacritty config directory or alacritty.yml not found, skipping font-size sync."
    CURRENT_FONT_SIZE=""
fi

update_font_size() {
  local file=$1
  local new_size=$2
  #[[ $file == *.toml ]] && sed -i "s/size = .*/size = $new_size/" "$file" || sed -i "s/size: .*/size: $new_size/" "$file"
  if [ "${file##*.}" = "toml" ]; then
      sed -i "s/size = .*/size = $new_size/" "$file"
  else
      sed -i "s/size: .*/size: $new_size/" "$file"
  fi
}
if [ -n "$CURRENT_FONT_SIZE" ] && [ "$CURRENT_FONT_SIZE" != "$DEFAULT_FONT_SIZE" ]; then
  log_info "Current font size is $CURRENT_FONT_SIZE. Syncing into repo alacritty config before copy."
  update_font_size ".config/alacritty/alacritty.yml" "$CURRENT_FONT_SIZE"
  update_font_size ".config/alacritty/alacritty.toml" "$CURRENT_FONT_SIZE"
fi

cp -r ".config/alacritty" "$HOME/.config/"

if [ -n "$CURRENT_FONT_SIZE" ] && [ "$CURRENT_FONT_SIZE" != "$DEFAULT_FONT_SIZE" ]; then
  log_info "Reverting repo alacritty font size back to default ($DEFAULT_FONT_SIZE)."
  update_font_size ".config/alacritty/alacritty.yml" "$DEFAULT_FONT_SIZE"
  update_font_size ".config/alacritty/alacritty.toml" "$DEFAULT_FONT_SIZE"
fi

if [ ! -f $HOME/.bash_profile ]; then
    cp -r .bash_profile $HOME/.bash_profile
    log_ok ".bash_profile installed."
else
    log_ok ".bash_profile already exists."
fi

USE_OH_MY_ZSH=false

# oh-my-zsh
if $USE_OH_MY_ZSH; then
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        log_ok "oh-my-zsh already installed."
    fi

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/.git" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        log_ok "zsh-autosuggestions installed."
    else
        log_ok "zsh-autosuggestions already installed."
    fi

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/.git" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
        log_ok "zsh-syntax-highlighting installed."
    else
        log_ok "zsh-syntax-highlighting already installed."
    fi
else
    if [ ! -d "$HOME/.zsh/zsh-autosuggestions/.git" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"
        log_ok "zsh-autosuggestions installed."
    else
        log_ok "zsh-autosuggestions already installed."
    fi

    if [ ! -d "$HOME/.zsh/zsh-syntax-highlighting/.git" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/zsh-syntax-highlighting"
        log_ok "zsh-syntax-highlighting installed."
    else
        log_ok "zsh-syntax-highlighting already installed."
    fi

    if [ ! -d "$HOME/.zsh/zsh-completions/.git" ]; then
        git clone https://github.com/zsh-users/zsh-completions "$HOME/.zsh/zsh-completions"
        log_ok "zsh-completions installed."
    else
        log_ok "zsh-completions already installed."
    fi

    if [ ! -d "$HOME/.zsh/zsh-system-clipboard/.git" ]; then
        git clone https://github.com/kutsan/zsh-system-clipboard "$HOME/.zsh/zsh-system-clipboard"
        log_ok "zsh-system-clipboard installed."
    else
        log_ok "zsh-system-clipboard already installed."
    fi

    if [ ! -d "$HOME/.zsh/zsh-vi-mode/.git" ]; then
        git clone https://github.com/jeffreytse/zsh-vi-mode "$HOME/.zsh/zsh-vi-mode"
        log_ok "zsh-vi-mode installed."
    else
        log_ok "zsh-vi-mode already installed."
    fi
fi

original_dir=$(pwd)
cd "$HOME/Downloads" || die "Failed to cd to $HOME/Downloads"

# polybar-themes
if [ ! -d "$HOME/Downloads/polybar-themes" ]; then
    log_step "Installing polybar-themes"
    git clone --depth=1 https://github.com/adi1090x/polybar-themes.git
    cd polybar-themes
    chmod +x setup.sh
    ./setup.sh
    cd "$original_dir"
else
    log_ok "polybar-themes already cloned."
fi

# gruvbox-dark-gtk theme
if [ ! -d "$HOME/.themes/gruvbox-dark-gtk" ]; then
    log_step "Installing gruvbox-dark-gtk theme"
    git clone https://github.com/jmattheis/gruvbox-dark-gtk "$HOME/.themes/gruvbox-dark-gtk"
    log_info "Set gruvbox-dark theme through lxappearance (should appear through dmenu)."
else
    log_ok "gruvbox-dark-gtk theme already installed."
fi

# fzf
if [ ! -d "$HOME/.fzf" ]; then
    log_step "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install"
else
    log_ok "fzf already installed."
fi

# packer.nvim (old)
#if [ ! -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim/.git" ]; then
#    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
#    mv $HOME/.config/nvim/init.lua $HOME/.config/nvim/temp.lua
#    mv $HOME/.config/nvim/install.lua $HOME/.config/nvim/init.lua
#    echo "Packer installed! Now open vim and do :PackerInstall and then move temp.lua to init.lua in $HOME/.config/nvim"
#else
#    echo "[ok] packer already installed."
#fi

# wezterm session manager
if [ ! -d "$HOME/.config/wezterm/wezterm-session-manager" ]; then
    log_step "Installing wezterm-session-manager"
    git clone https://github.com/danielcopper/wezterm-session-manager.git $HOME/.config/wezterm/wezterm-session-manager
    log_ok "wezterm-session-manager installed!"
else
    log_ok "wezterm-session-manager already installed."
fi

# tmux-resurrect plugin
if [ ! -d "$HOME/.tmux/plugins" ]; then
    mkdir -p "$HOME/.tmux/plugins" || die "Failed to create $HOME/.tmux/plugins"
fi
if [ ! -d "$HOME/.tmux/plugins/tmux-resurrect/.git" ]; then
    log_step "Installing tmux-resurrect"
    git clone --recurse-submodules -j8 https://github.com/tmux-plugins/tmux-resurrect "$HOME/.tmux/plugins/tmux-resurrect"
    log_ok "tmux-resurrect installed!"
else
    log_ok "tmux-resurrect already installed."
fi

# Copy tmux session (resurrect) file if none exist
TMUX_TARGET_DIR="$HOME/.local/share/tmux/resurrect"
SESSION_DIR="$CURRENT_DIR/tmux_session"
TMUX_SOURCE_FILE=$(find "$SESSION_DIR" -maxdepth 1 -type f -name "*.txt" -print -quit)
if [ -z "$TMUX_SOURCE_FILE" ]; then
    log_warn "No session file found in $SESSION_DIR. Skipping copy."
else
    # Check if the target directory exists
    if [[ ! -d "$TMUX_TARGET_DIR" ]]; then
        log_info "Directory $TMUX_TARGET_DIR does not exist. Creating it."
        mkdir -p "$TMUX_TARGET_DIR" || die "Failed to create $TMUX_TARGET_DIR"
    fi
    # Check if there are any .txt files in the directory
    if ! find "$TMUX_TARGET_DIR" -type f -name "*.txt" | read; then
        log_info "No session files found in $TMUX_TARGET_DIR. Copying $(basename "$TMUX_SOURCE_FILE")."
        cp "$TMUX_SOURCE_FILE" "$TMUX_TARGET_DIR"
        # Create or update the 'last' symlink to point to the new session file.
        TARGET_SESSION_PATH="$TMUX_TARGET_DIR/$(basename "$TMUX_SOURCE_FILE")"
        ln -sf "$TARGET_SESSION_PATH" "$TMUX_TARGET_DIR/last"
        log_ok "Created symlink 'last' -> '$TARGET_SESSION_PATH'"
    else
        log_ok "Directory $TMUX_TARGET_DIR contains session files already."
    fi
fi

# yazi plugins
ADD_YAZI_PLUGINS=false
PLUGIN_DIR="$HOME/.config/yazi/plugins"
if [ "$ADD_YAZI_PLUGINS" = true ]; then
    if command -v yazi &>/dev/null && command -v ya &>/dev/null; then
        if [ ! -d "$PLUGIN_DIR" ]; then
            log_step "Installing yazi plugins"
            log_info "yazi plugins dir missing. Creating it and installing plugins..."
            mkdir -p "$PLUGIN_DIR" || die "Failed to create $PLUGIN_DIR"

            ya pack -a lpnh/fg
            ya pack -a dedukun/bookmarks
            # ya pkg add immediately downloads and installs the plugin from the registry.
            # However, it does not modify the persistent plugin config (plugins.toml).
            #ya pkg add yazi-rs/plugins:smart-enter
            ya pack -a yazi-rs/plugins:smart-enter

            # Run install once after all packs are added
            ya pack -i
            log_ok "yazi plugins installed!"
        else
            log_ok "yazi plugins dir already exists."
        fi
    else
        log_warn "yazi or ya command not found, skipping yazi plugin installation."
    fi
else
    if [ ! -d "$PLUGIN_DIR" ]; then
        cat <<EOF
yazi plugins dir missing. You should run the following:
  rm $HOME/.config/yazi/package.toml
  ya pkg add lpnh/fg
  ya pkg add dedukun/bookmarks
  ya pkg add yazi-rs/plugins:smart-enter
  ya pkg install
EOF
        # alternative print
        #printf "yazi plugins dir missing. You should run the following commands:\n"
        #printf "  rm $HOME/.config/yazi/package.toml\n"
        #printf "  ya pkg add lpnh/fg\n"
        #printf "  ya pkg add dedukun/bookmarks\n"
        #printf "  ya pkg add yazi-rs/plugins:smart-enter\n"
        #printf "  ya pkg install\n"
    else
        log_ok "yazi plugins installed already."
    fi
fi

# jetbrains nerd fonts
check_font_exists() {
    if ls $HOME/.local/share/fonts/*JetBrainsMonoNerdFont*.ttf 1> /dev/null 2>&1 || ls $HOME/.fonts/*JetBrainsMonoNerdFont*.ttf 1> /dev/null 2>&1; then
        return 0 # Font exists
    else
        return 1 # Font does NOT exist
    fi
}

# Download and install
install_jetbrains_mono() {
    log_step "JetBrains Mono font"
    log_info "Downloading JetBrains Mono font..."
    cd $HOME/Downloads && wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
    
    log_info "Installing JetBrains Mono font..."
    mkdir -p $HOME/.local/share/fonts/ && unzip JetBrainsMono.zip -d $HOME/.local/share/fonts/
    
    log_info "Updating font cache..."
    fc-cache -fv
    log_ok "JetBrains Mono installed."
}

# Install fonts on debian only since arch uses the package: ttf-jetbrains-mono-nerd
if grep -qEi 'debian|raspbian' /etc/os-release; then
    if ! check_font_exists; then
        install_jetbrains_mono
    else
        log_ok "JetBrains Mono font already installed."
    fi
else
    log_warn "Non-debian OS detected. Install via: sudo pacman -S ttf-jetbrains-mono-nerd"
fi

# Variable to control whether to skip prompts and proceed directly
justDoIt=false
# Variable to control whether to only inform about missing repos / builds etc.
justInform=false

# Helper function
print_and_cd_to_dir() {
    local dir_path=$1
    local print_prefix=$2

    log_step "$print_prefix projects in $dir_path"
    cd "$dir_path" || die "Failed to cd to $dir_path"
}

clone_repo_if_missing() {
    local repo_dir=$1
    local repo_url=$2
    local branch=$3
    local parent_dir="."

    my_repo_dirs=("my_notes" "utils" "my_js" "my_cplusplus" "my_lua" "wc" "my_wow" "my_sql" "my_c")

    log_info "Checking repo: $repo_dir"

    if printf '%s\n' "${my_repo_dirs[@]}" | grep -q "^$repo_dir$"; then
    #if [[ "${repo_dir,,}" == "my_notes" || "${repo_dir,,}" == "utils" ]]; then
        if [ -z "$GITHUB_TOKEN" ]; then
            log_warn "GITHUB_TOKEN is not set. Skipping $repo_dir..."
            return 1
        fi
    fi

    # Case insensitive check
    if find "$parent_dir" -maxdepth 1 -type d -iname "$(basename "$repo_dir")" | grep -iq "$(basename "$repo_dir")$"; then
        log_ok "$repo_dir already cloned."
        return 0
    else
        if $justInform; then
            log_warn "$repo_dir NOT cloned."
            return 0
        fi

        log_info "Cloning $repo_dir from $repo_url"

        # Clone based on specific cases
        local clone_cmd="git clone --recurse-submodules"

        if [[ "${repo_dir,,}" == "trinitycore" || "${repo_dir,,}" == "simc" ]]; then
            clone_cmd="$clone_cmd --single-branch --depth 1"
        fi

        if [ -n "$branch" ]; then
            clone_cmd="$clone_cmd -b $branch"
        fi

        # Check if the lowercase repo_dir exists in the my_repo_dirs array
        #if [[ "${repo_dir,,}" == "my_notes" || "${repo_dir,,}" == "utils" ]]; then
        if printf '%s\n' "${my_repo_dirs[@]}" | grep -q "^$repo_dir$"; then
            repo_url="${repo_url/https:\/\//https:\/\/$GITHUB_TOKEN@}"
        fi

        clone_cmd="$clone_cmd $repo_url $repo_dir"

        #eval "$clone_cmd"
        #log_ok "Cloned $repo_dir"
        #return $?
        # check success/failure
        if eval "$clone_cmd"; then
            log_ok "Cloned $repo_dir"
            return 0
        else
            log_err "Failed to clone $repo_dir"
            return 1
        fi
    fi
}

# Clone projects (unless they already exist)
clone_projects() {
    printf "\n***** Cloning projects! *****\n\n"

    print_and_cd_to_dir "$HOME/Documents" "Cloning"
    clone_repo_if_missing "my_notes" "https://github.com/archornf/my_notes"
    clone_repo_if_missing "windows_dots" "https://github.com/ornfelt/windows_dots"

    print_and_cd_to_dir "$HOME/Code/c" "Cloning"
    clone_repo_if_missing "neovim" "https://github.com/neovim/neovim"

    print_and_cd_to_dir "$HOME/Code/c++" "Cloning"

    clone_repo_if_missing "openmw" "https://github.com/OpenMW/openmw"
    clone_repo_if_missing "OpenJK" "https://github.com/JACoders/OpenJK"
    clone_repo_if_missing "JediKnightGalaxies" "https://github.com/JKGDevs/JediKnightGalaxies"
    clone_repo_if_missing "jk2mv" "https://github.com/mvdevs/jk2mv"
    clone_repo_if_missing "Unvanquished" "https://github.com/Unvanquished/Unvanquished"

    # Copy via hdd instead of cloning these:
    #clone_repo_if_missing "re3" "https://github.com/halpz/re3"
    #clone_repo_if_missing "re3_vice" "https://github.com/halpz/re3" "miami"
    #cd /media2/2025
    #cp -r re3 ~/Code/c++
    #cp -r re3_vice ~/Code/c++
    MEDIA_PATHS=("/media" "/media2")
    MEDIA_PATH=""

    # Find existing dir
    for path in "${MEDIA_PATHS[@]}"; do
        if [ -d "$path/2025/re3" ]; then
            MEDIA_PATH="$path"
            log_ok "Found mounted hard drive at: $MEDIA_PATH"
            break
        fi
    done

    # Check if MEDIA_PATH was set
    if [ -z "$MEDIA_PATH" ]; then
        log_warn "The hard drive is not mounted. Can't copy re3 dirs."
    else
        TARGET_DIR="$HOME/Code/c++"
        SOURCE_DIR="$MEDIA_PATH/2025"

        if [ ! -d "$TARGET_DIR/re3" ] && [ -d "$SOURCE_DIR/re3" ]; then
            log_info "Copying re3 to $TARGET_DIR..."
            cp -r "$SOURCE_DIR/re3" "$TARGET_DIR"
        else
            log_ok "Skipping re3 copy (already exists or source missing)."
        fi

        if [ ! -d "$TARGET_DIR/re3_vice" ] && [ -d "$SOURCE_DIR/re3_vice" ]; then
            log_info "Copying re3_vice to $TARGET_DIR..."
            cp -r "$SOURCE_DIR/re3_vice" "$TARGET_DIR"
        else
            log_warn "Skipping re3_vice copy (already exists or source missing)."
        fi
    fi

    clone_repo_if_missing "reone" "https://github.com/seedhartha/reone"

    print_and_cd_to_dir "$HOME/Code/ml" "Cloning"
    clone_repo_if_missing "llama.cpp" "https://github.com/ggml-org/llama.cpp"
    clone_repo_if_missing "ollama" "https://github.com/ollama/ollama"
    clone_repo_if_missing "llama2.c" "https://github.com/ornfelt/llama2.c"
    clone_repo_if_missing "llama3.2.c" "https://github.com/ornfelt/llama3.2.c"

    print_and_cd_to_dir "$HOME/Code/js" "Cloning"
    clone_repo_if_missing "KotOR.js" "https://github.com/KobaltBlu/KotOR.js"

    print_and_cd_to_dir "$HOME/Code/rust" "Cloning"
    clone_repo_if_missing "eww" "https://github.com/elkowar/eww"
    clone_repo_if_missing "swww" "https://github.com/LGFae/swww"

    print_and_cd_to_dir "$HOME/Code2/C" "Cloning"
    clone_repo_if_missing "my_c" "https://github.com/ornfelt/my_c"
    clone_repo_if_missing "ioq3" "https://github.com/ornfelt/ioq3"
    clone_repo_if_missing "picom-animations" "https://github.com/ornfelt/picom-animations"

    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "stk-code" "https://github.com/ornfelt/stk-code"
    if [ ! -d "stk-assets" ]; then
        if $justInform; then
            log_info "$repo_dir NOT cloned."
        else
            svn co https://svn.code.sf.net/p/supertuxkart/code/stk-assets stk-assets
            log_ok "stk-assets cloned."
        fi
    else
        log_ok "stk-assets already cloned."
    fi
    clone_repo_if_missing "small_games" "https://github.com/ornfelt/small_games" "linux"
    clone_repo_if_missing "AzerothCore-wotlk-with-NPCBots" "https://github.com/rewow/AzerothCore-wotlk-with-NPCBots"
    ACORE_DIR="AzerothCore-wotlk-with-NPCBots"
    MODULES_DIR="$ACORE_DIR/modules"
    if [ -d "$MODULES_DIR" ]; then
        cd "$MODULES_DIR"

        if [ -f /etc/arch-release ]; then
            log_info "Arch Linux detected, checking out 'linux' branch..."
            git checkout linux || die "Failed to checkout linux branch"
        fi

        clone_repo_if_missing "mod-eluna" "https://github.com/azerothcore/mod-eluna"

        cd ..

        log_info "Fetching latest non-merge commit from AzerothCore..."

        ACORE_COMMIT=$(git log --no-merges --grep='Merge branch' --invert-grep -1 --format="%H")
        ACORE_DATE=$(git show -s --format=%ci "$ACORE_COMMIT")
        log_ok "Latest non-merge AzerothCore commit: $ACORE_COMMIT ($ACORE_DATE)"

        cd "modules/mod-eluna" || die "Failed to cd to modules/mod-eluna"

        log_info "Checking latest mod-eluna commit..."
        ELUNA_LATEST_COMMIT=$(git rev-parse HEAD)
        ELUNA_LATEST_DATE=$(git show -s --format=%ci "$ELUNA_LATEST_COMMIT")
        log_ok "Latest mod-eluna commit: $ELUNA_LATEST_COMMIT ($ELUNA_LATEST_DATE)"

        if [[ "$ELUNA_LATEST_DATE" < "$ACORE_DATE" ]]; then
            log_ok "mod-eluna is already older than AzerothCore. No checkout needed."
        else
            log_info "Searching for a mod-eluna commit before $ACORE_DATE..."
            ELUNA_TARGET_COMMIT=$(git log --before="$ACORE_DATE" -1 --format="%H")
            if [ -n "$ELUNA_TARGET_COMMIT" ]; then
                log_info "Checking out mod-eluna commit $ELUNA_TARGET_COMMIT"
                git checkout "$ELUNA_TARGET_COMMIT" || die "Failed to checkout commit"
                log_ok "Checked out $ELUNA_TARGET_COMMIT"
            else
                log_warn "No earlier mod-eluna commit found before $ACORE_DATE"
            fi
        fi

        cd ../../..
    else
        log_warn "Directory $MODULES_DIR does NOT exist."
    fi

    clone_repo_if_missing "Trinitycore-3.3.5-with-NPCBots" "https://github.com/rewow/Trinitycore-3.3.5-with-NPCBots" "npcbots_3.3.5"
    clone_repo_if_missing "simc" "https://github.com/ornfelt/simc"
    clone_repo_if_missing "simc_wotlk" "https://github.com/ornfelt/simc_wotlk"
    clone_repo_if_missing "OpenJKDF2" "https://github.com/ornfelt/OpenJKDF2" "linux"
    clone_repo_if_missing "devilutionX" "https://github.com/ornfelt/devilutionX"
    clone_repo_if_missing "crispy-doom" "https://github.com/ornfelt/crispy-doom"
    clone_repo_if_missing "dhewm3" "https://github.com/ornfelt/dhewm3"

    clone_repo_if_missing "my_cplusplus" "https://github.com/ornfelt/my_cplusplus"
    clone_repo_if_missing "japp" "https://github.com/ornfelt/japp"
    clone_repo_if_missing "mangos-classic" "https://github.com/ornfelt/mangos-classic"
    clone_repo_if_missing "core" "https://github.com/ornfelt/core"
    clone_repo_if_missing "server" "https://github.com/ornfelt/server"
    clone_repo_if_missing "mangos-tbc" "https://github.com/ornfelt/mangos-tbc"

    print_and_cd_to_dir "$HOME/Code2/General" "Cloning"
    clone_repo_if_missing "Svea-Examples" "https://github.com/ornfelt/Svea-Examples"
    clone_repo_if_missing "1brc" "https://github.com/ornfelt/1brc"
    clone_repo_if_missing "utils" "https://github.com/ornfelt/utils"

    print_and_cd_to_dir "$HOME/Code2/Go" "Cloning"
    clone_repo_if_missing "wotlk-sim" "https://github.com/ornfelt/wotlk-sim"
    clone_repo_if_missing "OpenDiablo2" "https://github.com/ornfelt/OpenDiablo2"

    print_and_cd_to_dir "$HOME/Code2/Javascript" "Cloning"
    clone_repo_if_missing "my_js" "https://github.com/ornfelt/my_js"

    print_and_cd_to_dir "$HOME/Code2/Lua" "Cloning"
    clone_repo_if_missing "my_lua" "https://github.com/ornfelt/my_lua"

    print_and_cd_to_dir "$HOME/Code2/Sql" "Cloning"
    clone_repo_if_missing "my_sql" "https://github.com/ornfelt/my_sql"

    print_and_cd_to_dir "$HOME/Code2/Python" "Cloning"
    clone_repo_if_missing "wander_nodes_util" "https://github.com/ornfelt/wander_nodes_util"

    print_and_cd_to_dir "$HOME/Code2/Wow/tools" "Cloning"
    clone_repo_if_missing "mpq" "https://github.com/Gophercraft/mpq"
    clone_repo_if_missing "StormLib" "https://github.com/ladislav-zezula/StormLib"
    clone_repo_if_missing "BLPConverter" "https://github.com/ornfelt/BLPConverter"
    clone_repo_if_missing "spelunker" "https://github.com/wowserhq/spelunker"
    clone_repo_if_missing "wowser" "https://github.com/ornfelt/wowser"
    clone_repo_if_missing "wowmapview" "https://github.com/ornfelt/wowmapview" "linux"
    clone_repo_if_missing "wowmapviewer" "https://github.com/ornfelt/wowmapviewer" "linux"
    clone_repo_if_missing "WebWoWViewer" "https://github.com/ornfelt/WebWoWViewer" "new"
    clone_repo_if_missing "wc" "https://github.com/ornfelt/wc"
    clone_repo_if_missing "my_wow" "https://github.com/ornfelt/my_wow"

    architecture=$(uname -m)
    #if grep -q -i 'raspbian\|raspberry pi os' /etc/os-release; then
    if [[ "$architecture" == arm* ]] || [[ "$architecture" == aarch64* ]]; then
        clone_repo_if_missing "WebWoWViewercpp" "https://github.com/ornfelt/WebWoWViewercpp" "linux"
    else
        clone_repo_if_missing "WebWoWViewercpp" "https://github.com/ornfelt/WebWoWViewercpp" "linux"
    fi
}

if $justDoIt; then
    clone_projects
else
    if $justInform; then
        log_q "Do you want to check cloned projects? (yes/y)"
    else
        log_q "Do you want to proceed with cloning projects? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        clone_projects
    else
        log_info "Skipping clone_projects."
    fi
fi

# Function to install if binary doesn't exist
install_if_missing() {
    local binary=$1
    local directory=$2
    local binary_path="$HOME/.config/$directory/$binary"

    log_sep

    #if ! command -v $binary &> /dev/null; then
    # Check if the binary exists instead of the command
    if [ ! -f "$binary_path" ]; then
        log_info "$binary NOT found."
        if $justInform; then
            return 0
        fi

        log_step "Installing: $binary"

        if [ "$binary" == "clipmenu" ]; then
            cd "$HOME/.config/$binary" || die "Failed to cd to $HOME/.config/$binary"
        else
            cd "$HOME/.config/$directory" || die "Failed to cd to $HOME/.config/$directory"
        fi

        if [ "$binary" == "dwmblocks" ]; then
            # if blocks.h is missing, try to seed it from blocks.def.h
            if [[ ! -f "blocks.h" ]]; then
                if [[ -f "blocks.def.h" ]]; then
                    log_info "blocks.h missing; copying blocks.def.h -> blocks.h"
                    cp blocks.def.h blocks.h
                else
                    log_warn "blocks.def.h also missing; skipping dwmblocks compile."
                    cd - >/dev/null
                    return 0
                fi
            fi

            if [[ -f "blocks.h" ]]; then
                log_info "Compiling dwmblocks"
                ./compile.sh
            else
                log_warn "blocks.h still not found; compilation skipped."
            fi

        else
            sudo make clean install
        fi

        #cd - || exit # Return to previous directory
        cd - >/dev/null || die "Failed to cd back"
    else
        log_ok "$binary exists, skipping installation."
    fi
}

ask_for_compile() {
    local dir_name=$1

    #read -p "Compile $dir_name? (yes/y to confirm): " user_input
    #if [[ "$user_input" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    log_q "Compile $dir_name? (yes/y)"
    read -r user_input
    user_input=$(printf "%s" "$user_input" | awk '{print tolower($0)}')

    if [ "$user_input" = "yes" ] || [ "$user_input" = "y" ]; then
        log_ok "Proceeding with compilation of $dir_name..."
    else
        log_warn "Skipping compilation of $dir_name."
        return 1 # False
    fi
}

check_dir() {
    local dir_name=$1
    local dir_type=${2:-build} # Default to build

    log_sep

    # Capture the actual directory name, preserving its case
    #local actual_dir_name=$(find . -maxdepth 1 -type d -iname "${dir_name}" -exec basename {} \; | head -n 1)
    # Use loop instead to get rid of find basename terminated by signal 13...
    actual_dir_name=""
    while IFS= read -r path; do
        actual_dir_name=$(basename "$path")
        break
    done < <(find . -maxdepth 1 -type d -iname "${dir_name}")
    
    if [[ -n "$actual_dir_name" ]]; then
        local target_dir="./${actual_dir_name}/${dir_type}"

        # Check if the directory exists based on the dir_type pattern
        if [[ "$dir_type" == "build*" ]]; then
            # Use find and grep to check for the existence of matching directories
            if find "./${actual_dir_name}" -maxdepth 1 -type d -name "${dir_type}" | grep -q .; then
                log_ok "${target_dir} already compiled."
                return 1 # Return false
            else
                if $justInform; then
                    log_warn "${target_dir} NOT compiled."
                    return 1
                fi

                if ! ask_for_compile "$dir_name"; then
                    return 1
                fi
    
                log_info "Entering ${actual_dir_name}..."
                cd "./${actual_dir_name}"
                sleep 1
                return 0 # Return true
            fi
        else
            if [ -d "$target_dir" ]; then
                log_ok "${target_dir} already compiled."
                return 1 # Return false
            else
                if $justInform; then
                    log_warn "${target_dir} NOT compiled."
                    return 1
                fi

                if ! ask_for_compile "$dir_name"; then
                    return 1
                fi

                if [[ "$dir_type" == *"build"* ]]; then
                    log_info "Creating and entering ${target_dir}..."
                    mkdir -p "$target_dir" && cd "$target_dir"
                else
                    log_info "Entering ${actual_dir_name}..."
                    cd "./${actual_dir_name}"
                fi
                sleep 1
                return 0 # Return true
            fi
        fi
    else
        log_warn "Directory $dir_name does NOT exist."
        return 1 # Return false
    fi
}

check_file() {
    local dir_name=$1
    local file_path=$2

    log_sep

    # Capture the actual directory name, preserving its case
    #local actual_dir_name=$(find . -maxdepth 1 -type d -iname "$dir_name" -exec basename {} \; | head -n 1)
    # Use loop instead to get rid of find basename terminated by signal 13...
    actual_dir_name=""
    while IFS= read -r path; do
        actual_dir_name=$(basename "$path")
        break
    done < <(find . -maxdepth 1 -type d -iname "${dir_name}")

    local full_file_path="./${actual_dir_name}/${file_path}"

    #if [ -f "$full_file_path" ]; then
    # Check case-insensitively if the file exists
    if find "$(dirname "$full_file_path")" -maxdepth 1 -type f -iname "$(basename "$full_file_path")" 2>/dev/null | grep -iq "$(basename "$full_file_path")$" >/dev/null 2>&1; then
        log_ok "${dir_name} already compiled."
        return 1 # Return false
    else
        log_warn "File ${file_path} in ${dir_name} does NOT exist."
        if $justInform; then
            log_warn "${dir_name} NOT compiled."
            return 1
        fi

        if ! ask_for_compile "$dir_name"; then
            return 1
        fi

        log_info "Entering ${actual_dir_name}..."
        cd "./${actual_dir_name}"
        return 0 # Return true
    fi
}

change_ownership_if_exists() {
    local dir=$1
    local CURRENT_USER=$(whoami)

    if [ -d "$dir" ]; then
        # Get owner of dir
        local DIR_OWNER=$(stat -c '%U' "$dir")
        if [ "$DIR_OWNER" != "$CURRENT_USER" ]; then
            sudo chown -R $USER:$USER "$dir"
            log_ok "Changed ownership of $dir to $USER"
        else
            log_ok "Ownership of $dir is already set to $CURRENT_USER, skipping chown"
        fi
    else
        log_warn "Directory $dir does NOT exist, skipping."
    fi
}

fix_ownerships() {
    local CURRENT_USER=$(whoami)
    local NPM_PREFIX=$(npm config get prefix)

    sudo mkdir -p "$NPM_PREFIX/lib/node_modules" || die "Failed to mkdir $NPM_PREFIX/lib/node_modules"

    # Check ownership and change only if necessary
    #for dir in "$NPM_PREFIX/lib/node_modules" "$NPM_PREFIX/bin" "$NPM_PREFIX/share"; do
    for dir in "$NPM_PREFIX/lib/node_modules"; do
        if [ -d "$dir" ]; then
            # Get owner of dir
            local DIR_OWNER=$(stat -c '%U' "$dir")
            if [ "$DIR_OWNER" != "$CURRENT_USER" ]; then
                sudo chown -R "$CURRENT_USER" "$dir" || log_err "Failed to chown $dir"
                if sudo chown -R "$CURRENT_USER" "$dir"; then
                    log_ok "Changed ownership of $dir to $CURRENT_USER"
                else
                    log_err "Failed to chown $dir"
                fi
            else
                log_ok "Ownership of $dir is already set to $CURRENT_USER, skipping chown"
            fi
        fi
    done

    directories=(
        "$HOME/Code/c++/openmw"
        "$HOME/Code/c++/OpenJK"
        "$HOME/Code/c++/JediKnightGalaxies"
        "$HOME/Code/c++/jk2mv"
        "$HOME/Code/c++/reone"
        "$HOME/Code2/C++/simc"
        "$HOME/Code2/C++/mangos-classic"
        "$HOME/Code2/C++/mangos-tbc"
        "$HOME/Code2/C++/core"
        "$HOME/Code2/C++/server"
        "$HOME/Code2/Wow/tools/BLPConverter"
        "$HOME/Code2/Wow/tools/StormLib"
        "$HOME/.local/share/openjk"
        "$HOME/cmangos"
        "$HOME/cmangos-tbc"
        "$HOME/vmangos"
        "$HOME/mangoszero"
        "$HOME/acore"
        "$HOME/tcore"
    )

    for dir in "${directories[@]}"; do
        change_ownership_if_exists "$dir"
    done
}

# Compile projects (unless already done)
compile_projects() {
    log_step "Compiling projects!"

    architecture=$(uname -m)
    log_info "Identified architecture: $architecture"
    fix_ownerships

    log_step "Compiling projects in $HOME/.config..."

    install_if_missing dwm dwm
    install_if_missing dwmblocks dwmblocks
    install_if_missing dmenu dmenu
    install_if_missing st st
    # Compile clipmenu for debian-based
    if grep -qEi 'debian|raspbian' /etc/os-release; then
        clipmenu_dir="$HOME/.config/clipmenu"
        if [ ! -d "$clipmenu_dir" ]; then
            log_info "Directory $clipmenu_dir does not exist. Cloning clipmenu..."
            git clone https://github.com/cdown/clipmenu "$clipmenu_dir"
        fi
        install_if_missing clipmenu "clipmenu/src"
    fi

    export CMAKE_POLICY_VERSION_MINIMUM=3.5

    print_and_cd_to_dir "$HOME/Code/c" "Compiling"

    #if grep -q -E "Debian|Raspbian" /etc/os-release; then
    #    if check_dir "neovim"; then
    #        cd ..
    #        if dpkg -l | grep -qw "neovim"; then
    #            sudo apt remove neovim -y
    #        fi
    #        git checkout stable
    #        #make CMAKE_BUILD_TYPE=RelWithDebInfo
    #        make CMAKE_BUILD_TYPE=Release
    #        sudo make install
    #        cd ..
    #    fi
    #else
    #    OS_ID=$(grep "^ID=" /etc/os-release | cut -d'=' -f2)
    #    echo "Skipping neovim check (only for Debian or Raspbian architectures). Found os: $OS_ID"
    #fi

    # Note: If the shell has issues with '++', you might need to quote or
    # escape it...
    print_and_cd_to_dir "$HOME/Code/c++" "Compiling"

    if check_dir "openmw"; then
        # Check MyGUI version
        if [ -f /etc/arch-release ]; then
            # For Arch Linux using pacman
            mygui_version=$(pacman -Q mygui 2>/dev/null | awk '{print $2}')
        elif [ -f /etc/debian_version ]; then
            # For Debian based systems using dpkg
            mygui_version=$(dpkg -l | grep mygui | awk '{print $3}')
        else
            die "Unsupported Linux distribution."
        fi

        if [ ! -z "$mygui_version" ]; then
            log_info "MyGUI version detected: $mygui_version"

            #if [ -f /etc/debian_version ]; then
            if [[ "$mygui_version" == "3.4.2"* ]]; then
                log_info "MyGUI version is 3.4.2 -> checking out compatible commit"
                git checkout 1c2f92cac9
            elif [[ "$mygui_version" == "3.4.1"* ]]; then
                log_info "MyGUI version is 3.4.1 -> checking out compatible commit"
                git checkout abb71eeb
            else
                log_info "MyGUI version is: $mygui_version"
            fi
            #fi

            #export CXXFLAGS="-fpermissive"
            #cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            cmake .. -DCMAKE_BUILD_TYPE=Release
            make -j$(nproc)
            sudo make install
            
            # Note: If you are having undefined reference errors while
            # compiling, its possible that you have previously installed a
            # different openscenegraph version than what openmw depends on.
            # To remove it, try:
            # removes just package
            #apt-get remove <yourOSGversion>
            #or 
            # removes configurations as well
            #apt-get remove --purge <yourOSGversion>

            #cd ...
            #cd ../..
        else
            log_warn "MyGUI is not installed or not found."
        fi
        cd "$HOME/Code/c++"
    fi

    if check_dir "OpenJK"; then
        sed -i '/option(BuildJK2SPEngine /s/OFF)/ON)/; /option(BuildJK2SPGame /s/OFF)/ON)/; /option(BuildJK2SPRdVanilla /s/OFF)/ON)/' ../CMakeLists.txt
        cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local/share/openjk -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
        make -j$(nproc)
        sudo make install
        cd "$HOME/Code/c++"
    fi

    # Compile if NOT arm arch
    if ! [[ "$architecture" == arm* ]] && ! [[ "$architecture" == aarch64* ]]; then
        if check_dir "JediKnightGalaxies"; then
            cmake -DCMAKE_INSTALL_PREFIX=$HOME/Downloads/ja_data -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
            make -j$(nproc)
            sudo make install
            cd "$HOME/Code/c++"
        fi

        if check_dir "jk2mv" "build_new"; then
            cmake .. CMAKE_BUILD_TYPE=Release
            make -j$(nproc)
            sudo make install
            cd "$HOME/Code/c++"
        fi

        if check_dir "Unvanquished"; then
            cd .. && ./download-paks build/pkg && cd -
            cmake .. -DCMAKE_BUILD_TYPE=Release
            make -j$(nproc)
            cd "$HOME/Code/c++"
        fi
    fi

    # re3
    if check_dir "re3"; then
        cd ..
        if [[ "$architecture" == arm* ]] || [[ "$architecture" == aarch64* ]]; then
            log_info "ARM detected: building premake5 from source"
            cd $HOME/Downloads
            git clone --recurse-submodules https://github.com/premake/premake-core
            cd premake-core
            make -f Bootstrap.mak linux
            cd bin/release
            # Verify that it's built for ARM64:
            file premake5
            sudo mv premake5 /usr/local/bin
            premake5 --version
            cd "$HOME/Code/c++/re3"
            premake5 --with-librw gmake
            cd build && make help
            make config=release_linux-arm64-librw_gl3_glfw-oal
        else
            ./premake5Linux --with-librw gmake2
            cd build && make help
            make config=release_linux-amd64-librw_gl3_glfw-oal
        fi
        cd "$HOME/Code/c++"
    fi

    if check_dir "re3_vice"; then
        cd ..
        if [[ "$architecture" == arm* ]] || [[ "$architecture" == aarch64* ]]; then
            premake5 --with-librw gmake
            cd build && make help
            make config=release_linux-arm64-librw_gl3_glfw-oal
        else
            ./premake5Linux --with-librw gmake2
            cd build && make help
            make config=release_linux-amd64-librw_gl3_glfw-oal
        fi
        cd "$HOME/Code/c++"
    fi

    #if check_dir "reone"; then
    #    cd ..
    #    cmake -B build -S . -DCMAKE_BUILD_TYPE=RelWithDebInfo
    #    cd build && make -j$(nproc)
    #    sudo make install
    #    cd "$HOME/Code/c++"
    #fi

    print_and_cd_to_dir "$HOME/Code/ml" "Compiling"

    # https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#cpu-build
    if check_dir "llama.cpp" "build"; then
        cmake .. -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        cd "$HOME/Code/ml"
    fi

    # make
    #if check_file "llama2.c" "run"; then
    #    make run
    #    #make runfast
    #    cd "$HOME/Code/ml"
    #fi
    # cmake
    if check_dir "llama2.c" "build"; then
        #cmake ../ -DCMAKE_BUILD_TYPE=Debug
        cmake ../ -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        cd "$HOME/Code/ml"
    fi

    # make
    #if check_file "llama3.2.c" "run"; then
    #    make run
    #    #make runfast
    #    cd "$HOME/Code/ml"
    #fi
    # cmake
    if check_dir "llama3.2.c" "build"; then
        #cmake ../ -DCMAKE_BUILD_TYPE=Debug
        cmake ../ -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        cd "$HOME/Code/ml"
    fi

    print_and_cd_to_dir "$HOME/Code/js" "Compiling"

    # Print npm/node info
    npm_version=$(npm --version)
    node_version=$(node --version)
    log_info "npm version: ${npm_version:-unknown}"
    log_info "node version: ${node_version:-unknown}"
    for i in {3..1}; do
        log_info "Proceeding with compilation in $i..."
        sleep 1
    done

    # skip for now
    COMPILE_KOTOR_JS=false
    if [ "$COMPILE_KOTOR_JS" = true ]; then
        if check_dir "KotOR.js" "node_modules"; then
            npm install
            #npm run webpack:dev-watch
            npm run webpack:dev -- --no-watch # No watch to exit after compile
            cd "$HOME/Code/js"
        fi
    fi

    print_and_cd_to_dir "$HOME/Code/rust" "Compiling"

    if ! command -v rustc &>/dev/null; then
        log_warn "rustc is not installed. Skipping rust projects..."
    else
        # Only compile if rust version is > 1.63
        #rust_version=$(rustc --version | awk '{print $2}') # Also works...
        rust_version=$(rustc --version | grep -oP 'rustc \K[^\s]+')
        major_version=$(echo "$rust_version" | cut -d'.' -f1)
        minor_version=$(echo "$rust_version" | cut -d'.' -f2)
        log_info "Rust version: $rust_version"
        log_info "major: $major_version"
        log_info "minor: $minor_version"

        if grep -qEi 'arch' /etc/os-release; then
            if command -v eww &>/dev/null; then
                log_ok "eww is already installed"
            elif check_dir "eww" "target"; then
                if [ "$major_version" -gt 1 ] || { [ "$major_version" -eq 1 ] && [ "$minor_version" -gt 63 ]; }; then
                    log_info "rustc version is above 1.63"
                    cargo build --release --no-default-features --features x11
                    cd target/release
                    chmod +x ./eww
                else
                    cd ..
                    log_warn "rustc version is 1.63 or below. Skipping rust project..."
                fi
                cd "$HOME/Code/rust"
            fi

            if command -v swww &>/dev/null; then
                log_ok "swww is already installed"
            elif check_dir "swww" "target"; then
                if [ "$major_version" -gt 1 ] || { [ "$major_version" -eq 1 ] && [ "$minor_version" -gt 63 ]; }; then
                    log_info "rustc version is above 1.63"
                    cargo build --release
                else
                    cd ..
                    log_warn "rustc version is 1.63 or below. Skipping rust project..."
                fi
                cd "$HOME/Code/rust"
            fi
        else
            OS_ID=$(grep "^ID=" /etc/os-release | cut -d'=' -f2)
            log_info "Skipping compilation of eww and swww (only for Arch). Found os: $OS_ID"
        fi
    fi

    print_and_cd_to_dir "$HOME/Code2/C" "Compiling"

    if check_dir "ioq3"; then
        cd ..
        if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
            log_info "Building ioq3 via make"
            make
            #make -j"$(nproc)"
        elif [[ -f CMakeLists.txt ]]; then
            log_info "Building ioq3 via cmake"
            cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
            cmake --build build -j"$(nproc)"
        else
            log_warn "No Makefile or CMakeLists.txt found in $(pwd)"
        fi

        cd "$HOME/Code2/C"
    fi

    # Do this manually instead since picom needs to be uninstalled and thus can't be running
    #if check_file "picom-animations" "bin/picom-trans"; then
    #    meson --buildtype=release . build
    #    ninja -C build
    #    sudo cp build/src/picom /usr/bin/
    #fi
    #cd "$HOME/Code2/C"

    print_and_cd_to_dir "$HOME/Code2/C++" "Compiling"

    if check_dir "stk-code"; then
        cmake .. -DCMAKE_BUILD_TYPE=Release -DNO_SHADERC=on
        make -j$(nproc)
        cd "$HOME/Code2/C++"
    fi

    cd "$HOME/Code2/C++/small_games"
    if check_file "Craft" "craft"; then
        cmake . && make -j$(nproc)
        gcc -std=c99 -O3 -fPIC -shared -o world -I src -I deps/noise deps/noise/noise.c src/world.c
        cd "$HOME/Code2/C++/small_games"
    fi

    if check_file "BirdGame" "main"; then
        # sudo apt-get install libsdl2-mixer-dev
        g++ -std=c++17 -g *.cpp -o main -lSDL2main -lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer
        cp -r BirdGame/graphics ./
    fi

    cd "$HOME/Code2/C++/small_games/CPP_FightingGame"
    if check_file "FightingGameProject" "CPPFightingGame"; then
        cmake . && make -j$(nproc)
    fi

    cd "$HOME/Code2/C++/small_games"
    if check_dir "space-shooter"; then
        cd ..
        make linux
        #make linux-release
    fi

    cd "$HOME/Code2/C++/small_games"
    if check_dir "pacman"; then
        cmake .. && cmake --build .
    fi
    cd "$HOME/Code2/C++"

    if check_dir "AzerothCore-wotlk-with-NPCBots"; then
        #cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug
        cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
        #cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        make install
        cd "$HOME/Code2/C++"
    fi

    if check_dir "Trinitycore-3.3.5-with-NPCBots"; then
        #cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug
        cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
        #cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        make install
        cd "$HOME/Code2/C++"
    fi

    if check_dir "simc"; then
        cmake ../ -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        sudo make install
        cd "$HOME/Code2/C++"
    fi

    if check_dir "OpenJKDF2" "build*"; then
        if ! python3 -c "import cogapp" &> /dev/null; then
            log_warn "Python package 'cogapp' is required to compile OpenJKDF2 (pip install cogapp)."
        else
            export CC=clang
            export CXX=clang++
            source build_linux64.sh
        fi
        cd "$HOME/Code2/C++"
    fi

    if check_dir "devilutionX" "build*"; then
        if grep -qEi 'debian|raspbian' /etc/os-release; then
            log_info "Debian/Raspbian detected: rebuilding smpq via devilutionX tools"
            sudo apt remove smpq -y
            cd tools
            source build_and_install_smpq.sh
            sudo cp /usr/local/bin/smpq /usr/bin/smpq
            cd ..
        fi
        if [[ "$architecture" == arm* ]] || [[ "$architecture" == aarch64* ]]; then
            source Packaging/nix/debian-cross-aarch64-prep.sh
            cmake -S. -Bbuild-aarch64-rel \
            -DCMAKE_TOOLCHAIN_FILE=../CMake/platforms/aarch64-linux-gnu.toolchain.cmake \
            -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCPACK=ON \
            -DDEVILUTIONX_SYSTEM_LIBFMT=OFF
            cmake --build build-aarch64-rel -j $(getconf _NPROCESSORS_ONLN) --target package
        else
            cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release
            cmake --build build -j $(getconf _NPROCESSORS_ONLN)
        fi
        cd "$HOME/Code2/C++"
    fi

    if check_file "crispy-doom" "src/crispy-doom"; then
        autoreconf -fiv
        ./configure
        make -j$(nproc)
        cd "$HOME/Code2/C++"
    fi

    if check_dir "dhewm3"; then
        cmake ../neo/
        make -j$(nproc)
        cd "$HOME/Code2/C++"
    fi

    if check_file "japp" "uix86_64.so"; then
        scons
        cd "$HOME/Code2/C++"
    fi

    if check_dir "mangos-classic"; then
        cmake .. -DCMAKE_INSTALL_PREFIX=~/cmangos/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON
        make -j$(nproc)
        sudo make install
        cd "$HOME/Code2/C++"
    fi

    # Note, on arch this requires:
    # mkdir libace && cd libace
    # curl -L -O https://aur.archlinux.org/cgit/aur.git/snapshot/ace.tar.gz
    # tar -xvzf ace.tar.gz
    # makepkg -si
    # cd .. && rm -rf libace
    # See:
    # https://github.com/vmangos/wiki/wiki/Compiling-on-Linux
    # Or, better:
    # yay -S ace
    if check_dir "core"; then
        # Fix CXX version
        VMANGOS_CMAKE_FILE="$HOME/Code2/C++/core/CMakeLists.txt"
        CHANGE_VMANGOS_CXX_VERSION=false
        if [ "$CHANGE_VMANGOS_CXX_VERSION" = true ]; then
        #if [ -f /etc/os-release ] && grep -qi '^ID=arch' /etc/os-release; then
            # Note the space after CMAKE_CXX_STANDARD (needed to not match CMAKE_CXX_STANDARD_REQUIRED etc.)
            occurrence_count=$(grep -c 'CMAKE_CXX_STANDARD ' "$VMANGOS_CMAKE_FILE")
            log_info "Found CMAKE_CXX_STANDARD occurrences: $occurrence_count"
            if [ "$occurrence_count" -eq 1 ]; then
                log_info "Changing C++ standard version from 14 to 17 in $VMANGOS_CMAKE_FILE"
                sed -i 's/CMAKE_CXX_STANDARD 14/CMAKE_CXX_STANDARD 17/' "$VMANGOS_CMAKE_FILE"
            fi
        fi

        #export ACE_ROOT=/usr/include/ace
        #export TBB_ROOT_DIR=/usr/include/tbb

        cmake .. -DDEBUG=0 -DSUPPORTED_CLIENT_BUILD=5875 -DUSE_EXTRACTORS=1 -DCMAKE_INSTALL_PREFIX=$HOME/vmangos
        make -j$(nproc)
        sudo make install
        cd "$HOME/Code2/C++"
    fi

    if check_dir "server"; then
        #cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=1 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run
        # skip eluna
        cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=0 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run
        make -j$(nproc)
        sudo make install
        sudo chown -R $USER:$USER $HOME/mangoszero
        cd "$HOME/Code2/C++"
    fi

    if check_dir "mangos-tbc"; then
        cmake -S .. -B ./ -DCMAKE_INSTALL_PREFIX=~/cmangos-tbc/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON -DCMAKE_BUILD_TYPE=Release
        # Debug:
        # cmake -S .. -B ./ -DCMAKE_INSTALL_PREFIX=~/cmangos-tbc/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=1 -DBUILD_PLAYERBOTS=ON -DCMAKE_BUILD_TYPE=Debug
        # with clang:
        # cmake ../mangos -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
        # see: https://github.com/cmangos/issues/wiki/Installation-Instructions
        make -j$(nproc)
        sudo make install
        sudo chown -R $USER:$USER $HOME/cmangos-tbc
        cd "$HOME/Code2/C++"
    fi

    cd my_cplusplus/Navigation
    if check_dir "Pathing"; then
        cmake .. -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
    fi
    cd "$HOME/Code2/C++"

    print_and_cd_to_dir "$HOME/Code2/Go" "Compiling"

    #if check_dir "wotlk-sim" "node_modules"; then
    if check_file "wotlk-sim" "wowsimwotlk"; then
        # Check if go version is >= 1.21.1
        GO_VERSION=$(go version 2>/dev/null)

        if [ -z "$GO_VERSION" ]; then
            die "Go is not installed."
        fi

        MAJOR_MINOR=$(echo "$GO_VERSION" | grep -oP 'go\d+\.\d+' | grep -oP '\d+\.\d+')
        IFS='.' read -r MAJOR MINOR PATCH <<< "$MAJOR_MINOR.0" # Adding .0 to handle versions without patch number

        log_info "Go version: $MAJOR_MINOR"
        log_info "Go major version: $MAJOR"
        log_info "Go minor version: $MINOR"

        if (( MAJOR < 1 )) || { (( MAJOR == 1 )) && (( MINOR < 21 )); } || { (( MAJOR == 1 )) && (( MINOR == 21 )) && (( PATCH < 1 )); }; then
            log_warn "Go version is below 1.21.1. Installing go 1.21.1..."
            # Don't install dependencies through apt since they are too old for
            # this repo...
            curl -O https://dl.google.com/go/go1.21.1.linux-amd64.tar.gz
            sudo rm -rf /usr/local/go 
            sudo rm /usr/bin/go
            sudo tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz

            log_info "Updating PATH/GOPATH in ~/.bashrc"
            echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc
            echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
            echo 'export PATH=$PATH:$GOPATH/bin' >> $HOME/.bashrc
            source $HOME/.bashrc
        else
            log_ok "Go version is 1.21.1 or higher. Continuing..."
        fi

        if grep -qEi 'debian|raspbian' /etc/os-release; then
            #sudo apt update && sudo apt upgrade
            sudo apt install protobuf-compiler
        fi

        go get -u -v google.golang.org/protobuf
        go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
        npm install

        #make setup
        #make test
        #make host
        make wowsimwotlk

        cd "$HOME/Code2/Go"
    fi

    if check_file "OpenDiablo2" "OpenDiablo2"; then
        source build.sh
        cd "$HOME/Code2/Go"
    fi

    print_and_cd_to_dir "$HOME/Code2/Javascript" "Compiling"

    cd my_js/three
    if check_dir "azeroth-web" "node_modules"; then
        npm install
    fi
    cd "$HOME/Code2/Javascript"
    cd my_js/three
    if check_dir "azeroth-web-proxy" "node_modules"; then
        npm install
    fi
    cd "$HOME/Code2/Javascript"

    print_and_cd_to_dir "$HOME/Code2/Wow/tools" "Compiling"

    #if check_file "mpq" "gophercraft_mpq_set"; then
    if check_file "mpq" "mopaq"; then
        #go build github.com/Gophercraft/mpq/cmd/gophercraft_mpq_set
        go build github.com/Gophercraft/mpq/cmd/mopaq
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "BLPConverter"; then
        cmake .. -DWITH_LIBRARY=YES
        sudo make install
        sudo cp /usr/local/lib/libblp.so /usr/lib/
        sudo ldconfig
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "StormLib"; then
        # Commit 486a7dd29f3bdf884d4be5588d9171daa5da1bae (Replaced GetLastError 
        # with SErrGetLastError) messed up the library link for wowser and 
        # azeroth-web, go back to this commit:
        git checkout b41cda40f9c3fbdb802cf63e739425cd805eecaa
        cmake .. -DBUILD_SHARED_LIBS=ON
        sudo make install
        sudo cp /usr/local/lib/libstorm.so /usr/lib/
        sudo ldconfig
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "spelunker" "node_modules"; then
        npm install
        cd packages/spelunker-api && npm install && cd -
        cd packages/spelunker-web && npm install && cd -
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "wowser" "node_modules"; then
        git checkout new
        npm install
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "wowmapview"; then
        cmake .. && make -j$(nproc)
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_file "wowmapviewer" "bin/wowmapview"; then
        #cd src/stormlib && make -f Makefile.linux
        #cd .. && make
        #cd ..
        cd src
        mkdir build && cd build
        cmake .. && make -j$(nproc)
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "WebWoWViewer" "node_modules"; then
        npm install
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_dir "WebWowViewerCpp"; then
        cmake .. && make -j$(nproc)
        cd "$HOME/Code2/Wow/tools"
    fi

    if check_file "wc" "wow"; then
        #sudo ln -s /usr/bin/ranlib /usr/bin/x86_64-linux-gnu-ranlib
        RANLIB_TARGET="/usr/bin/ranlib"
        RANLIB_LINK="/usr/bin/x86_64-linux-gnu-ranlib"

        # First check if the target exists
        if [ ! -e "$RANLIB_TARGET" ]; then
            die "$RANLIB_TARGET does not exist. Please install it."
        fi

        # Check if the symlink already exists
        if [ ! -e "$RANLIB_LINK" ]; then
            log_warn "$RANLIB_LINK not found. Creating symlink..."
            sudo ln -s "$RANLIB_TARGET" "$RANLIB_LINK"
        else
            log_ok "$RANLIB_LINK already exists. Skipping symlink creation."
        fi

        # Check if Vulkan header exists
        VULKAN_HEADER="/usr/include/vulkan/vulkan.h"
        if [ -f "$VULKAN_HEADER" ]; then
            log_ok "Found Vulkan header at $VULKAN_HEADER"
            for i in {3..1}; do
                log_info "Proceeding with wc compilation in $i..."
                sleep 1
            done
            # Do the thing
            cp config.sample config
            make lib
            make
        else
            log_warn "Vulkan header not found: $VULKAN_HEADER"
            
            # Check distro using /etc/os-release if available
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    debian|raspbian)
                        echo "Please install the Vulkan headers by running:"
                        echo "  sudo apt update && sudo apt install libvulkan-dev (and possibly sudo apt install vulkan-headers)"
                        ;;
                    arch)
                        echo "Please install the Vulkan headers by running:"
                        echo "  sudo pacman -S vulkan-headers"
                        ;;
                    *)
                        log_info "Please install Vulkan headers for your distribution."
                        ;;
                esac
            else
                log_warn "Unable to detect distribution. Please install Vulkan headers manually."
            fi
        fi

        cd "$HOME/Code2/Wow/tools"
    fi

    cd "$original_dir"
}

if $justDoIt; then
    compile_projects
else
    if $justInform; then
        log_q "Do you want to check compiled projects? (yes/y)"
    else
        log_q "Do you want to proceed with compiling projects? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        compile_projects
    fi
fi

check_pip_packages() {
    log_step "Checking pip packages!"
    requirements_path="$HOME/Documents/installation/requirements.txt"

    # Extract package names from requirements.txt, ignoring versions
    requirements_packages=$(cut -d'=' -f1 < "$requirements_path")

    # Extract installed packages names, ignoring versions
    installed_packages=$(pip freeze | cut -d'=' -f1)

    # Convert to arrays (assuming Bash 4+ for associative array support)
    declare -A reqs
    declare -A installed

    # Populate arrays
    for pkg in $requirements_packages; do reqs["$pkg"]=1; done
    for pkg in $installed_packages; do installed["$pkg"]=1; done

    # Compare: find packages in requirements.txt not installed
    log_sep
    log_info "Packages in requirements.txt but not installed:"
    for pkg in "${!reqs[@]}"; do
        if [[ ! ${installed["$pkg"]} ]]; then
            echo "$pkg"
        fi
    done

    # Compare: find installed packages not in requirements.txt
    log_sep
    log_info "Installed packages not in requirements.txt:"
    for pkg in "${!installed[@]}"; do
        if [[ ! ${reqs["$pkg"]} ]]; then
            echo "$pkg"
        fi
    done
}

install_pip_packages() {
    log_step "Installing pip packages!"
    #pip3 install -r $HOME/Documents/installation/f6295c9d66/requirements.txt
    requirements_path="$HOME/Documents/installation/f6295c9d66/requirements.txt"

    if [ ! -f "$requirements_path" ]; then
        die "requirements.txt not found: $requirements_path"
    fi

    # Read each line in requirements.txt, remove version specifications, and install
    while read -r package || [[ -n $package ]]; do
        package_name=$(echo "$package" | cut -d'=' -f1)
        log_info "pip install $package_name"
        pip3 install "$package_name"
    done < "$requirements_path"
}

# Install python packages
if $justDoIt; then
    log_step "Installing python packages..."
    install_pip_packages
else
    if $justInform; then
        log_q "Do you want to check python packages? (yes/y)"
    else
        log_q "Do you want to install python packages? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        if $justInform; then
            log_step "Checking python packages..."
            check_pip_packages
        else
            log_step "Installing python packages..."
            install_pip_packages
        fi
    else
        log_info "Skipped python packages step."
    fi
fi

# Copy game data
copy_dir_to_target() {
    SRC=$1
    DEST=$2
    BASE_NAME=$(basename "$SRC")
    ALT_DEST_MNT="/mnt/new/$BASE_NAME"
    ALT_DEST_MEDIA="/media/$BASE_NAME"

    if [ -d "$SRC" ]; then
        if [ ! -d "$DEST" ]; then

            if [ -d "$ALT_DEST_MNT" ]; then
                log_ok "$BASE_NAME already exists in /mnt/new/, skipping copy."
                return 0
            elif [ -d "$ALT_DEST_MEDIA" ]; then
                log_ok "$BASE_NAME already exists in /media/, skipping copy."
                return 0
            fi

            #$justInform && echo "Copied $SRC to $DEST" && return 0
            if $justInform; then
                log_info "Would copy $SRC -> $DEST"
                return 0
            fi

            cp -r "$SRC" "$DEST"
            log_ok "Copied $SRC -> $DEST"
        else
            log_ok "$DEST already exists, skipping copy."
        fi
    else
        log_warn "$SRC does NOT exist, skipping."
    fi
}

check_space() {
    local dir=$1

    log_info "Checking disk space for: $dir"
    if [ ! -d "$dir" ]; then
        log_warn "Directory does not exist: $dir"
        return 1
    fi

    local min_space_gb=30
    local available_space_kb=$(df "$dir" --output=avail | tail -n 1)
    local available_space_gb=$((available_space_kb / 1024 / 1024))

    if (( available_space_gb > min_space_gb )); then
        log_ok "Disk at $dir has > ${min_space_gb}GB available. Left: ${available_space_gb}GB"
        return 0
    else
        log_warn "Disk at $dir has <= ${min_space_gb}GB available. Left: ${available_space_gb}GB"
        return 1
    fi
}

copy_game_data() {
    log_step "Copying game data!"

    if [ -d "/mnt/new/other" ] || [ -d "/mnt/new/my_files" ]; then
        DOWNLOADS_DIR="/mnt/new"
    else
        DOWNLOADS_DIR="$HOME/Downloads"
    fi

    fix_ownerships

    # Create dirs
    mkdir -p $HOME/.local/share/supertuxkart/addons
    mkdir -p $HOME/.local/share/OpenJKDF2/openjkdf2
    mkdir -p $HOME/.local/share/openjk/JediOutcast/base
    mkdir -p $HOME/.local/share/openjk/japlus
    mkdir -p $HOME/acore/bin
    mkdir -p $HOME/tcore/bin
    mkdir -p $HOME/vmangos/bin
    mkdir -p $HOME/cmangos/run/bin
    mkdir -p $HOME/mangoszero/run/bin

    MEDIA_PATHS=("/media" "/media2")
    MEDIA_PATH=""

    # Find existing dir
    for path in "${MEDIA_PATHS[@]}"; do
        if [ -d "$path/2024/wow" ]; then
            MEDIA_PATH="$path"
            log_ok "Found mounted hard drive at: $MEDIA_PATH"
            break
        fi
    done

    # Check if MEDIA_PATH was set
    if [ -z "$MEDIA_PATH" ]; then
        log_warn "The hard drive is not mounted. Skipping copy of game data..."
        return 1
    fi

    # Directories to copy from 2024
    DIRS=("wow" "wow_classic" "wow_tbc" "wow_retail" "cata")

    # Check space 
    if [ "$DOWNLOADS_DIR" = "/mnt/new" ]; then
        if ! check_space "$DOWNLOADS_DIR"; then
            log_warn "Not enough space on disk ($DOWNLOADS_DIR). Skipping."
            return 1
        fi
    else
        if ! check_space "/"; then
            log_warn "Not enough space on /. Skipping."
            return 1
        fi
    fi

    log_step "Copying wow data -> $DOWNLOADS_DIR"
    for dir in "${DIRS[@]}"; do
        SRC="$MEDIA_PATH/2024/$dir"
        DEST="$DOWNLOADS_DIR/$dir"
        copy_dir_to_target "$SRC" "$DEST"
    done

    # AzerothCore
    DEST_DIR="$HOME/acore/bin"
    log_step "Copying acore files -> $DEST_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/acore/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/acore/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/acore/dbc_old" "$DEST_DIR/dbc_old"
    copy_dir_to_target "$MEDIA_PATH/2024/acore/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/acore/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/acore/vmaps" "$DEST_DIR/vmaps"

    # Handle copying individual scripts from lua_scripts
    LUA_SRC="$MEDIA_PATH/2024/acore/lua_scripts"
    #if [ -d "$LUA_SRC" ]; then
    #    mkdir -p "$DEST_DIR/lua_scripts"
    #    for script in "$LUA_SRC"/*.lua; do # Only copy lua files
    #        script_name=$(basename "$script")
    #        if [ ! -f "$DEST_DIR/lua_scripts/$script_name" ]; then
    #            cp "$script" "$DEST_DIR/lua_scripts/$script_name"
    #            echo "Copied $script -> $DEST_DIR/lua_scripts/$script_name"
    #        else
    #            echo "[ok] $DEST_DIR/lua_scripts/$script_name already exists, skipping copy."
    #        fi
    #    done
    #else
    #    echo "$LUA_SRC does NOT exist, skipping."
    #fi
    if [ -d "$LUA_SRC" ]; then
        mkdir -p "$DEST_DIR/lua_scripts"
        for item in "$LUA_SRC"/*; do
            item_name=$(basename "$item")
            if [ "$item_name" != "extensions" ]; then
                if [ -d "$item" ]; then
                    # Copy the subdirectory recursively
                    if [ ! -d "$DEST_DIR/lua_scripts/$item_name" ]; then
                        cp -r "$item" "$DEST_DIR/lua_scripts/$item_name"
                        log_info "Copied directory $item -> $DEST_DIR/lua_scripts/$item_name"
                    else
                        log_ok "Dir exists: $DEST_DIR/lua_scripts/$item_name (skipping)"
                    fi
                else
                    # Copy the file
                    if [ ! -f "$DEST_DIR/lua_scripts/$item_name" ]; then
                        cp "$item" "$DEST_DIR/lua_scripts/$item_name"
                        log_info "Copied file $item -> $DEST_DIR/lua_scripts/$item_name"
                    else
                        log_ok "File exists: $DEST_DIR/lua_scripts/$item_name (skipping)"
                    fi
                fi
            fi
        done
    else
        log_warn "$LUA_SRC does NOT exist, skipping."
    fi

    # acore_old -> local Documents dir (for navigation dll)
    ACORE_OLD_SRC="$MEDIA_PATH/2024/acore_old"
    ACORE_OLD_DEST="$HOME/Documents/local/acore/bin"

    log_step "Copying acore_old -> $ACORE_OLD_DEST"
    if [ -d "$ACORE_OLD_SRC" ]; then
        mkdir -p "$ACORE_OLD_DEST"

        # Copy all directories from source into destination (only if missing)
        for item in "$ACORE_OLD_SRC"/*; do
            [ -e "$item" ] || continue
            name="$(basename "$item")"

            if [ -d "$item" ]; then
                if [ ! -d "$ACORE_OLD_DEST/$name" ]; then
                    cp -r -- "$item" "$ACORE_OLD_DEST/$name"
                    log_info "Copied dir $name -> $ACORE_OLD_DEST/"
                else
                    log_ok "Dir exists: $ACORE_OLD_DEST/$name (skipping)"
                fi
            fi
        done
    else
        log_warn "$ACORE_OLD_SRC does NOT exist, skipping."
    fi

    # TrinityCore
    DEST_DIR="$HOME/tcore/bin"
    log_step "Copying tcore files -> $DEST_DIR"
    #cp -r "$MEDIA_PATH/2024/tcore/"* "$HOME/tcore/bin"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/dbc_old" "$DEST_DIR/dbc_old"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/vmaps" "$DEST_DIR/vmaps"
    #[ -f "$HOME/tcore/bin/TDB_full_world_335.23061_2023_06_14.sql" ] && echo "File already exists, skipping copy." || (cp "$MEDIA_PATH/2024/tcore/TDB_full_world_335.23061_2023_06_14.sql" "$HOME/tcore/bin/" && echo "Copied TDB_full_world_335.23061_2023_06_14.sql to $HOME/tcore/bin")
    # Better (easier to adjust) version:
    #FILE_NAME="TDB_full_world_335.23061_2023_06_14.sql"
    FILE_NAME="TDB_full_world_335.24111_2024_11_22.sql"
    SRC_FILE="$MEDIA_PATH/2024/tcore/$FILE_NAME"
    DEST_FILE="$HOME/tcore/bin/$FILE_NAME"
    if [ -f "$DEST_FILE" ]; then
        log_ok "TDB file already exists: $DEST_FILE (skip)"
    else
        cp "$SRC_FILE" "$DEST_FILE"
        log_info "Copied $FILE_NAME -> $HOME/tcore/bin"
    fi

    # Cmangos
    DEST_DIR="$HOME/cmangos/run/bin"
    log_step "Copying cmangos files -> $DEST_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/vmaps" "$DEST_DIR/vmaps"

    # Vmangos
    DEST_DIR="$HOME/vmangos/bin"
    log_step "Copying vmangos files -> $DEST_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/5875" "$DEST_DIR/5875"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/vmaps" "$DEST_DIR/vmaps"

    # Mangoszero
    DEST_DIR="$HOME/mangoszero/run/etc"
    log_step "Copying mangoszero files -> $DEST_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/vmaps" "$DEST_DIR/vmaps"

    # Cmangos-tbc
    DEST_DIR="$HOME/cmangos-tbc/run/bin"
    log_step "Copying cmangos-tbc files -> $DEST_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos-tbc/Buildings" "$DEST_DIR/Buildings"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos-tbc/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos-tbc/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos-tbc/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos-tbc/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos-tbc/vmaps" "$DEST_DIR/vmaps"
    
    # db backups
    #log_step "Copying db_bkp files to $HOME/Documents"
    #copy_dir_to_target "$MEDIA_PATH/2024/db_bkp" "$HOME/Documents/db_bkp"

    # Diablo
    SRC_DIABLO="$MEDIA_PATH/2024/diasurgical/devilution"
    DEST_DIR_DIABLO="$HOME/Code2/C++/devilutionX/build"
    log_step "Copying diablo files -> $DEST_DIR_DIABLO"
    if [ -d "$SRC_DIABLO" ]; then
        mkdir -p "$DEST_DIR_DIABLO"
        for file in "$SRC_DIABLO"/*; do
            file_name=$(basename "$file")
            if [ ! -f "$DEST_DIR_DIABLO/$file_name" ]; then
                cp "$file" "$DEST_DIR_DIABLO/$file_name"
                log_info "Copied $file -> $DEST_DIR_DIABLO/$file_name"
            else
                log_ok "Exists: $DEST_DIR_DIABLO/$file_name (skip)"
            fi
        done
    else
        log_warn "$SRC_DIABLO does NOT exist, skipping."
    fi

    # doom3
    log_step "Copying doom3 -> $DOWNLOADS_DIR"
    if [ ! -d "$DOWNLOADS_DIR/doom3" ]; then
        cp "$MEDIA_PATH/2024/doom3_base.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/doom3_base.zip" -d "$DOWNLOADS_DIR/doom3"
        log_info "Copied and unzipped doom3_base.zip -> $DOWNLOADS_DIR/doom3"
    else
        log_ok "$DOWNLOADS_DIR/doom3 exists, skipping."
    fi

    # doom
    log_step "Copying doom files -> $DOWNLOADS_DIR"
    if [ ! -d "$DOWNLOADS_DIR/doom" ]; then
        unzip DOOM.zip -d "$DOWNLOADS_DIR"
        cp "$MEDIA_PATH/2024/DOOM.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/DOOM.zip" -d "$DOWNLOADS_DIR/doom"
        log_info "Copied and unzipped DOOM.zip -> $DOWNLOADS_DIR/doom"
    else
        log_ok "$DOWNLOADS_DIR/doom exists, skipping."
    fi

    log_step "Copying GTA3 -> $DOWNLOADS_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/GTA3" "$DOWNLOADS_DIR/gta3"

    log_step "Copying GTA_VICE -> $DOWNLOADS_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/GTA_VICE" "$DOWNLOADS_DIR/gta_vice"

    # jo
    log_step "Copying JediOutcast files -> $HOME/.local/share/openjk/JediOutcast/base"
    if [ ! -f "$HOME/.local/share/openjk/JediOutcast/base/assets0.pk3" ]; then
        cp "$MEDIA_PATH/2024/jedi_outcast_gamedata.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/jedi_outcast_gamedata.zip" -d "$DOWNLOADS_DIR/jedi_outcast_gamedata"
        cp "$DOWNLOADS_DIR/jedi_outcast_gamedata/base"/*.pk3 "$HOME/.local/share/openjk/JediOutcast/base/"
        log_info "Copied and unzipped jedi_outcast_gamedata.zip and moved *.pk3 -> $HOME/.local/share/openjk/JediOutcast/base/"
    else
        log_ok "assets0.pk3 already exists in $HOME/.local/share/openjk/JediOutcast/base/, skipping."
    fi

    # ja
    log_step "Copying JediAcademy files -> $HOME/.local/share/openjk/JediAcademy/base"
    # Not 100% sure about JediKnightGalaxies and jk2mv...
    if [ ! -f "$HOME/.local/share/openjk/JediAcademy/base/assets0.pk3" ] && [ ! -f "$HOME/.local/share/openjk/base/assets0.pk3" ]; then
        cp "$MEDIA_PATH/2024/JK_JA_GameData.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/JK_JA_GameData.zip" -d "$DOWNLOADS_DIR/JK_JA_GameData"
        cp "$DOWNLOADS_DIR/JK_JA_GameData/base"/*.pk3 "$HOME/.local/share/openjk/JediAcademy/base"
        log_info "Copied and unzipped JK_JA_GameData.zip and moved *.pk3 -> $HOME/.local/share/openjk/JediAcademy/base"
    else
        log_ok "assets0.pk3 already exists in JediAcademy base or openjk base, skipping."
    fi

    # my_docs
    #log_step "Copying my_docs files to $HOME/Documents"
    #copy_dir_to_target "$MEDIA_PATH/2024/my_docs" "$HOME/Documents/my_docs"

    # openmw
    log_step "Copying openmw files -> $DOWNLOADS_DIR"
    if [ ! -d "$DOWNLOADS_DIR/Morrowind" ] && [ ! -d "/mnt/new/openmw_gamedata" ]; then
        cp "$MEDIA_PATH/2024/Morrowind.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/Morrowind.zip" -d "$DOWNLOADS_DIR/Morrowind"
        log_info "Copied and unzipped Morrowind.zip -> $DOWNLOADS_DIR/Morrowind"
    else
        log_ok "$DOWNLOADS_DIR/Morrowind or /mnt/new/openmw_gamedata already exists, skipping."
    fi

    # openjkdf2
    log_step "Copying openjkdf2 files -> $HOME/.local/share/OpenJKDF2/openjkdf2"
    if [ ! -d "$HOME/.local/share/OpenJKDF2/openjkdf2/Episode" ]; then
        cp -r "$MEDIA_PATH/2024/star_wars_jkdf2/"* "$HOME/.local/share/OpenJKDF2/openjkdf2"
        log_info "Copied star_wars_jkdf2 -> $HOME/.local/share/OpenJKDF2/openjkdf2"
    else
        log_ok "Episode directory already exists in OpenJKDF2, skipping."
    fi

    # kotor
    log_step "Copying kotor files -> $DOWNLOADS_DIR"
    if [ ! -d "$DOWNLOADS_DIR/kotor" ]; then
        cp "$MEDIA_PATH/2024/Star Wars - KotOR.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/Star Wars - KotOR.zip" -d "$DOWNLOADS_DIR/kotor"
        log_info "Copied and unzipped 'Star Wars - KotOR.zip' -> $DOWNLOADS_DIR/kotor"
    else
        log_ok "$DOWNLOADS_DIR/kotor already exists, skipping."
    fi

    # kotor2
    log_step "Copying kotor2 files -> $DOWNLOADS_DIR"
    if [ ! -d "$DOWNLOADS_DIR/kotor2" ]; then
        cp "$MEDIA_PATH/2024/Star Wars - KotOR2.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/Star Wars - KotOR2.zip" -d "$DOWNLOADS_DIR/kotor2"
        log_info "Copied and unzipped 'Star Wars - KotOR2.zip' -> $DOWNLOADS_DIR/kotor2"
    else
        log_ok "$DOWNLOADS_DIR/kotor2 already exists, skipping."
    fi

    # stk addons
    log_step "Copying stk addon files -> $HOME/.local/share/supertuxkart/addons"
    for dir in "$MEDIA_PATH/2024/stk_addons"/*; do
        if [ -d "$dir" ]; then
            dest_dir="$HOME/.local/share/supertuxkart/addons/$(basename "$dir")"
            if [ ! -d "$dest_dir" ]; then
                cp -r "$dir" "$dest_dir"
                log_info "Copied $(basename "$dir") -> $HOME/.local/share/supertuxkart/addons"
            else
                log_ok "$(basename "$dir") already exists in addons, skipping."
            fi
        fi
    done

    # ioq3
    IOQ3_BUILD_DIR="$HOME/Code2/C/ioq3/build"
    IOQ3_RELEASE_DIR="$IOQ3_BUILD_DIR/Release"
    # fallback to old release dir if needed
    if [ ! -d "$IOQ3_RELEASE_DIR" ]; then
        IOQ3_RELEASE_DIR="$IOQ3_BUILD_DIR/release-linux-x86_64"
    fi
    # if still missing: print and skip this step
    if [ ! -d "$IOQ3_RELEASE_DIR" ]; then
        log_info "Skipping ioq3: release dir not found: $IOQ3_BUILD_DIR/Release or $IOQ3_BUILD_DIR/release-linux-x86_64"
    else
        IOQ3_BASEQ3_DIR="$IOQ3_RELEASE_DIR/baseq3"

        log_step "Copying ioq3 files -> $IOQ3_BASEQ3_DIR"
        mkdir -p "$IOQ3_BASEQ3_DIR"

        for file in "$MEDIA_PATH/2024/baseq3/"*.pk3; do
            [ -f "$file" ] || continue

            dest_file="$IOQ3_BASEQ3_DIR/$(basename "$file")"
            if [ ! -f "$dest_file" ]; then
                cp -- "$file" "$dest_file"
                log_info "Copied $(basename "$file") -> $IOQ3_BASEQ3_DIR"
            else
                log_ok "$(basename "$file") already exists in $IOQ3_BASEQ3_DIR, skipping."
            fi
        done
    fi

    # Diablo 2
    log_step "Copying d2 files -> $DOWNLOADS_DIR"
    copy_dir_to_target "$MEDIA_PATH/2024/d2" "$DOWNLOADS_DIR/d2"

    # Jar files
    log_step "Copying jar files -> $DOWNLOADS_DIR"
    copy_dir_to_target "$MEDIA_PATH/my_files/my_docs/jar_files/linux" "$DOWNLOADS_DIR/jar_files"

    # Setup dir lwjgl and joml jars
    LWJGL_JARS_DIR="$DOWNLOADS_DIR/lwjgl_jars"
    if [ ! -d "$LWJGL_JARS_DIR" ]; then
        log_step "Creating directory $LWJGL_JARS_DIR"
        mkdir -p "$LWJGL_JARS_DIR"

        # Copy joml jar
        JOML_JAR="$DOWNLOADS_DIR/jar_files/250630/lwjgl_jars/joml-1.10.8.jar"
        if [ -f "$JOML_JAR" ]; then
            log_info "Copying $JOML_JAR -> $LWJGL_JARS_DIR"
            cp "$JOML_JAR" "$LWJGL_JARS_DIR"
        else
            log_warn "$JOML_JAR does not exist."
        fi

        # Array of dirs to copy .jar files from
        JAR_SOURCE_DIRS=(
            "$DOWNLOADS_DIR/jar_files/250630/lwjgl-3.3.6-github-release/lwjgl"
            "$DOWNLOADS_DIR/jar_files/250630/lwjgl-3.3.6-github-release/lwjgl-glfw"
            "$DOWNLOADS_DIR/jar_files/250630/lwjgl-3.3.6-github-release/lwjgl-opengl"
        )

        # Copy all .jar files from each specified directory
        for DIR in "${JAR_SOURCE_DIRS[@]}"; do
            if [ -d "$DIR" ]; then
                log_info "Copying .jar files from $DIR -> $LWJGL_JARS_DIR"
                cp "$DIR"/*.jar "$LWJGL_JARS_DIR"
            else
                log_warn "Source directory $DIR does not exist."
            fi
        done
    fi

    # local config file
    if [ ! -f "$HOME/Documents/local/config.txt" ]; then
        mkdir -p "$HOME/Documents/local"
        if [ -f "$MEDIA_PATH/my_files/my_docs/local/config_home_pc.txt" ]; then
            cp "$MEDIA_PATH/my_files/my_docs/local/config_home_pc.txt" "$HOME/Documents/local/config.txt"
            log_info "Copied config file -> $HOME/Documents/local/config.txt"
            windows_path="C:/Users/jonas/OneDrive/Documents/Code2/c#/BloogBot/Bot/db.db"
            #unix_path="$HOME/Code2/C#/BloogBot/Bot/db.db"
            unix_path="${HOME}/Code2/C#/BloogBot/Bot/db.db"
            if grep -Fq "$windows_path" "$HOME/Documents/local/config.txt"; then
                # Use double quotes around the sed delimiters to expand HOME
                sed -i "s|$windows_path|$unix_path|g" "$HOME/Documents/local/config.txt"
                log_ok "Updated database path in config file."
            fi
        else
            log_warn "Source config file not found: $MEDIA_PATH/my_files/my_docs/local/config_home_pc.txt"
        fi
    else
        log_ok "Config file already exists at $HOME/Documents/local/config.txt"
    fi

    # Copy config.txt if missing
    if [ ! -f "$HOME/Documents/local/config.txt" ]; then
        mkdir -p "$HOME/Documents/local"
        if [ -f "$MEDIA_PATH/my_files/my_docs/local/config_home_pc.txt" ]; then
            cp "$MEDIA_PATH/my_files/my_docs/local/config_home_pc.txt" "$HOME/Documents/local/config.txt"
            log_info "Copied config file -> $HOME/Documents/local/config.txt"
        else
            log_warn "Source config file not found: $MEDIA_PATH/my_files/my_docs/local/config_home_pc.txt"
        fi
    else
        log_ok "Config file already exists at $HOME/Documents/local/config.txt"
    fi

    # Adjust BloogBot connection string if needed
    if [ -f "$HOME/Documents/local/config.txt" ]; then
        windows_path="C:/Users/jonas/OneDrive/Documents/Code2/c#/BloogBot/Bot/db.db"
        #unix_path="$HOME/Code2/C#/BloogBot/Bot/db.db"
        unix_path="${HOME}/Code2/C#/BloogBot/Bot/db.db"
        if grep -Fq "$windows_path" "$HOME/Documents/local/config.txt"; then
            # Use double quotes around the sed delimiters to expand HOME
            sed -i "s|$windows_path|$unix_path|g" "$HOME/Documents/local/config.txt"
            log_ok "Updated database path in config file."
        else
            log_ok "Config file does not have windows path for BloogBot connection string"
        fi
    fi

    # Copy BloogBot db if needed
    if [ -d "$HOME/Code2/C#/BloogBot" ]; then
        if [ ! -d "$HOME/Code2/C#/BloogBot/Bot" ]; then
            mkdir -p "$HOME/Code2/C#/BloogBot/Bot"
            log_info "Created directory $HOME/Code2/C#/BloogBot/Bot"
        fi

        if [ ! -f "$HOME/Code2/C#/BloogBot/Bot/db.db" ]; then
            cp "$MEDIA_PATH/my_files/my_docs/db_bkp/bloogbot/db.db" "$HOME/Code2/C#/BloogBot/Bot"
            log_info "Copied db.db -> $HOME/Code2/C#/BloogBot/Bot"
        else
            log_ok "File db.db already exists in $HOME/Code2/C#/BloogBot/Bot"
        fi
    else
        log_warn "Directory $HOME/Code2/C#/BloogBot does not exist."
    fi
}

if $justDoIt; then
    log_step "Copying game data..."
    copy_game_data
else
    if $justInform; then
        log_q "Do you want to check game data? (yes/y)"
    else
        log_q "Do you want to copy game data? (yes/y)"
    fi

    #read answer
    ## To lowercase using awk
    #answer=$(echo $answer | awk '{print tolower($0)}')
    #
    #if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
    #    $justInform && echo "Checking game data..." || echo "Copying game data..."
    #    copy_game_data
    #fi

    read -r answer
    answer="$(printf "%s" "$answer" | awk '{print tolower($0)}')"

    if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
        if $justInform; then
            log_step "Checking game data..."
        else
            log_step "Copying game data..."
        fi
        copy_game_data
    else
        log_info "Skipping game data."
    fi
fi

# Check if database exists
check_database_exists() {
    local db_name=$1
    result=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" -P"$MYSQL_PORT" -e "SHOW DATABASES LIKE '$db_name';" 2>/dev/null)
    if [[ "$result" == *"$db_name"* ]]; then
        log_ok "Database $db_name exists."
    else
        log_warn "Database $db_name does NOT exist."
    fi
}

# Check specified databases
check_dbs() {
    # Get MYSQL info via input
    #read -p "Enter MySQL user: " MYSQL_USER
    #read -sp "Enter MySQL password: " MYSQL_PASSWORD
    #echo ""
    #read -p "Enter MySQL host (default: localhost): " MYSQL_HOST
    #MYSQL_HOST=${MYSQL_HOST:-localhost}
    #read -p "Enter MySQL port (default: 3306): " MYSQL_PORT
    #MYSQL_PORT=${MYSQL_PORT:-3306}

    # Get MSQL info from set values
    if [ -z "$MYSQL_ROOT_PWD" ]; then
        die "MYSQL_ROOT_PWD environment variable is not set."
    fi

    if ! command -v mysql &> /dev/null; then
        die "mysql command not found. Please install MySQL client."
    fi

    MYSQL_USER="root"
    MYSQL_PASSWORD="$MYSQL_ROOT_PWD"
    MYSQL_HOST="localhost"
    MYSQL_PORT=3306

    # Check vmangos, cmangos, mangoszero, acore and tcore databases
    databases=(
        "vmangos_realmd" "vmangos_mangos" "vmangos_characters" "vmangos_logs"
        "classicrealmd" "classicmangos" "classiccharacters" "classiclogs"
        "tbcrealmd" "tbcmangos" "tbccharacters" "tbclogs"
        "realmd" "mangos0" "character0"
        "acore_auth" "acore_world" "acore_characters" "ac_eluna"
        "auth" "world" "characters"
    )

    # Create with sql scripts if they don't exist?
    for db in "${databases[@]}"; do
        check_database_exists "$db"
    done
}

# Fix conf files etc.
fix_other_files() {
    log_step "Fixing other files!"

    # Fix OpenDiablo2 config.json if it exists
    if [ -f "$HOME/.config/OpenDiablo2/config.json" ]; then
        DIABLO_DIRS=(
            "/mnt/new/d2/"
            "$HOME/Downloads/d2/"
            #"/media/2024/d2/"
        )

        NEW_PATH=""
        # Check each directory and set NEW_PATH to the first one that exists
        for DIR in "${DIABLO_DIRS[@]}"; do
            if [ -d "$DIR" ]; then
                NEW_PATH="$DIR"
                break
            fi
        done

        # Check if a new path was found
        if [ -z "$NEW_PATH" ]; then
            log_warn "No valid Diablo 2 directory found."
        fi

        if [ -n "$NEW_PATH" ]; then
            NEW_PATH="${NEW_PATH}d2video"
        fi

        ESCAPED_NEW_PATH=$(echo "$NEW_PATH" | sed 's/\\/\\\\/g')

        # Update config.json file with new path
        sed -i "s|\"MpqPath\": \".*\"|\"MpqPath\": \"$ESCAPED_NEW_PATH\"|g" $HOME/.config/OpenDiablo2/config.json
        log_ok "Updated config.json with new MpqPath: $NEW_PATH"
    else
        log_warn "$HOME/.config/OpenDiablo2/config.json does NOT exist yet (OpenDiablo2 not run)."
    fi

    # japp aka japlus
    #cp $HOME/Code2/C++/japp/*.so $HOME/.local/share/openjk/japlus/
    log_sep
    log_step "Checking japlus .so libs"
    SRC_DIR="$HOME/Code2/C++/japp"
    DEST_DIR="$HOME/.local/share/openjk/japlus"

    if [ -d "$SRC_DIR" ] && [ -d "$DEST_DIR" ]; then
        for file in "$SRC_DIR"/*.so; do
            if [ -f "$file" ]; then
                dest_file="$DEST_DIR/$(basename "$file")"
                if [ ! -f "$dest_file" ]; then
                    cp "$file" "$dest_file"
                    log_info "Copied $(basename "$file") -> $DEST_DIR"
                else
                    log_ok "$(basename "$file") already exists in $DEST_DIR, skipping."
                fi
            fi
        done
    else
        log_warn "Missing $SRC_DIR or $DEST_DIR. Skipping japlus lib copy."
    fi

    # Copy japp-assets to japlus dir
    log_sep
    log_step "Checking japp-assets"
    SRC_DIR="$HOME/Code2/Lua/my_lua/my_stuff/japp-assets"
    DEST_DIR="$HOME/.local/share/openjk/japlus"
    # Use rsync to copy only files and directories that don't already exist in the destination
    #rsync -av --ignore-existing "$SRC_DIR/" "$DEST_DIR/"
    if [ -d "$SRC_DIR" ] && [ -d "$DEST_DIR" ]; then
        for item in "$SRC_DIR"/*; do
            base_item=$(basename "$item")
            
            if [ ! -e "$DEST_DIR/$base_item" ]; then
                cp -r "$item" "$DEST_DIR"
                log_info "Copied $base_item -> $DEST_DIR"
            else
                log_ok "$base_item already exists in $DEST_DIR, skipping."
            fi
        done
    else
        log_warn "Missing $SRC_DIR or $DEST_DIR. Skipping japp-assets."
    fi
    
    # Python
    log_sep
    log_step "Checking python symlink/copy (Debian/Raspbian only)"
    if grep -qEi 'debian|raspbian' /etc/os-release; then
        if [ ! -f /usr/bin/python ]; then
            sudo cp /usr/bin/python3 /usr/bin/python
            log_ok "Copied /usr/bin/python3 -> /usr/bin/python"
        else
            log_ok "/usr/bin/python already exists, skipping."
        fi
    else
        OS_ID=$(grep "^ID=" /etc/os-release | cut -d'=' -f2)
        log_info "Skipping python copy (non Debian/Raspbian). OS: $OS_ID"
    fi

    CLASSIC_CONF_SCRIPT="$HOME/Documents/my_notes/scripts/wow/update_conf_classic.py"

    # vmangos
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "vmangos_db" "https://github.com/brotalnia/database"

    log_step "Setting up vmangos conf files"
    #cp $HOME/vmangos/etc/mangosd.conf.dist $HOME/vmangos/etc/mangosd.conf
    #cp $HOME/vmangos/etc/realmd.conf.dist $HOME/vmangos/etc/realmd.conf
    #python3 $HOME/Documents/my_notes/scripts/wow/update_conf_classic.py "vmangos"
    if [[ -d "$HOME/vmangos/etc" && -f "$HOME/vmangos/etc/mangosd.conf.dist" && -f "$HOME/vmangos/etc/realmd.conf.dist" ]]; then
        python3 "$CLASSIC_CONF_SCRIPT" vmangos
    else
        log_warn "Skipping vmangos conf script: missing one of ~/vmangos/etc/{mangosd.conf.dist,realmd.conf.dist}"
    fi
    # Follow vmangos install notes from setup_notes.txt...

    # cmangos
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "classic-db" "https://github.com/cmangos/classic-db"

    log_step "Setting up cmangos conf files"
    #cp $HOME/cmangos/run/etc/aiplayerbot.conf.dist $HOME/cmangos/run/etc/aiplayerbot.conf
    #cp $HOME/cmangos/run/etc/ahbot.conf.dist $HOME/cmangos/run/etc/ahbot.conf
    #cp $HOME/cmangos/run/etc/mangosd.conf.dist $HOME/cmangos/run/etc/mangosd.conf
    #cp $HOME/cmangos/run/etc/realmd.conf.dist $HOME/cmangos/run/etc/realmd.conf
    #python3 $HOME/Documents/my_notes/scripts/wow/update_conf_classic.py "cmangos"
    if [[ -d "$HOME/cmangos/run/etc" && -f "$HOME/cmangos/run/etc/mangosd.conf.dist" && -f "$HOME/cmangos/run/etc/realmd.conf.dist" && -f "$HOME/cmangos/run/etc/aiplayerbot.conf.dist" ]]; then
        python3 "$CLASSIC_CONF_SCRIPT" cmangos
    else
        log_warn "Skipping cmangos: missing one of ~/cmangos/run/etc/{mangosd.conf.dist,realmd.conf.dist,aiplayerbot.conf.dist}"
    fi
    # Follow cmangos install notes from setup_notes.txt...

    # mangoszero
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "mangoszero_db" "https://github.com/mangoszero/database"

    src_dir="$HOME/Documents/my_notes/sql/wow/mangoszero"
    dest_dir="$HOME/Code2/C++/mangoszero_db"
    if [ -d "$src_dir" ]; then
        if [ -d "$dest_dir" ]; then
            cp -r "$src_dir"/* "$dest_dir"
            log_ok "All files copied from $src_dir -> $dest_dir."
        else
            log_warn "$dest_dir does NOT exist. Can't copy mangoszero sql files."
        fi
    else
        log_warn "$src_dir does NOT exist. Can't copy mangoszero sql files from it..."
    fi

    # cmangos-tbc
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "tbc-db" "https://github.com/cmangos/tbc-db"

    log_step "Setting up cmangos-tbc conf files"
    if [[ -d "$HOME/cmangos-tbc/run/etc" && -f "$HOME/cmangos-tbc/run/etc/mangosd.conf.dist" && -f "$HOME/cmangos-tbc/run/etc/realmd.conf.dist" && -f "$HOME/cmangos-tbc/run/etc/aiplayerbot.conf.dist" ]]; then
        python3 "$CLASSIC_CONF_SCRIPT" cmangos-tbc
    else
        log_warn "Skipping cmangos-tbc: missing one of ~/cmangos-tbc/run/etc/{mangosd.conf.dist,realmd.conf.dist,aiplayerbot.conf.dist}"
    fi

    # Fix liblua...
    log_step "Checking liblua symlink/copy (Debian/Raspbian only)"
    if grep -qEi 'debian|raspbian' /etc/os-release; then
        if [ -f "/usr/lib/x86_64-linux-gnu/liblua5.2.so" ]; then
            log_ok "/usr/lib/x86_64-linux-gnu/liblua5.2.so exists."

            if [ ! -f "/usr/lib/x86_64-linux-gnu/liblua52.so" ]; then
                log_info "/usr/lib/x86_64-linux-gnu/liblua52.so does NOT exist. Copying it."
                sudo cp /usr/lib/x86_64-linux-gnu/liblua5.2.so /usr/lib/x86_64-linux-gnu/liblua52.so
                log_ok "Copied liblua5.2.so -> liblua52.so"
            else
                log_ok "/usr/lib/x86_64-linux-gnu/liblua52.so already exists."
            fi
        else
            log_warn "/usr/lib/x86_64-linux-gnu/liblua5.2.so does NOT exist. Skipping."
        fi
    fi

    # Check if $HOME/mangoszero/run/bin exists
    if [ -d "$HOME/mangoszero/run/bin" ]; then
        log_ok "$HOME/mangoszero/run/bin exists."

        if [ ! -d "$HOME/mangoszero/run/etc" ]; then
            log_warn "$HOME/mangoszero/run/etc does NOT exist."

            if [ -d "$HOME/mangoszero/etc" ]; then
                log_info "$HOME/mangoszero/etc exists. Moving it to $HOME/mangoszero/run/"
                mv "$HOME/mangoszero/etc" "$HOME/mangoszero/run/"
                log_ok "Moved etc -> run/"
            fi
        fi

        log_step "Setting up mangoszero conf files"
        #cp "$HOME/mangoszero/run/etc/aiplayerbot.conf.dist" "$HOME/mangoszero/run/etc/aiplayerbot.conf"
        #cp "$HOME/mangoszero/run/etc/ahbot.conf.dist" "$HOME/mangoszero/run/etc/ahbot.conf"
        #cp "$HOME/mangoszero/run/etc/mangosd.conf.dist" "$HOME/mangoszero/run/etc/mangosd.conf"
        #cp "$HOME/mangoszero/run/etc/realmd.conf.dist" "$HOME/mangoszero/run/etc/realmd.conf"
        #python3 $HOME/Documents/my_notes/scripts/wow/update_conf_classic.py "mangoszero"
        if [[ -d "$HOME/mangoszero/run/etc" && -f "$HOME/mangoszero/run/etc/mangosd.conf.dist" && -f "$HOME/mangoszero/run/etc/realmd.conf.dist" && -f "$HOME/mangoszero/run/etc/aiplayerbot.conf.dist" ]]; then
            python3 "$CLASSIC_CONF_SCRIPT" mangoszero
        else
            log_warn "Skipping mangoszero: missing one of ~/mangoszero/run/etc/{mangosd.conf.dist,realmd.conf.dist,aiplayerbot.conf.dist}"
        fi
        # Follow mangoszero install notes from setup_notes.txt...
    else
        log_warn "$HOME/mangoszero/run/bin does NOT exist. Skipping."
    fi

    # AzerothCore and TrinityCore
    SOURCE_FILES=(
        "$HOME/Documents/my_notes/scripts/wow/overwrite.py"
        "$HOME/Documents/my_notes/scripts/wow/gdb.conf"
    )

    TARGET_DIRS=(
        "$HOME/acore/bin"
        "$HOME/tcore/bin"
    )

    # Copy files if they don't already exist in target dirs
    log_step "Ensuring extra files exist in acore/tcore bin dirs"
    for target_dir in "${TARGET_DIRS[@]}"; do
        for source_file in "${SOURCE_FILES[@]}"; do
            file_name=$(basename "$source_file")
            target_file="$target_dir/$file_name"

            if [ ! -f "$target_file" ]; then
                sudo cp "$source_file" "$target_file"
                log_info "Copied $source_file -> $target_file"
            else
                log_ok "$target_file already exists. Skipping."
            fi
        done
    done

    log_step "Setting up AzerothCore conf files"
    python3 $HOME/Documents/my_notes/scripts/wow/update_conf.py "acore"

    log_step "Setting up TrinityCore conf files"
    python3 $HOME/Documents/my_notes/scripts/wow/update_conf.py "tcore"
    # Follow acore / tcore install notes in setup_notes.txt or setup db from
    # existing dbs in db_bkp

    log_step "Checking mpq files"
    # Check mpq exports
    if [ -d "$HOME/Code2/Wow/tools/mpq" ]; then
        log_ok "$HOME/Code2/Wow/tools/mpq exists."

        dir_to_use="$HOME/Downloads"
        export_dir="$HOME/Code2/Wow/tools/mpq"
        if [ -d "/mnt/new/wow" ]; then
            dir_to_use="/mnt/new"
            export_dir="/mnt/new/mpq"
            mkdir -p "$export_dir"
            log_info "Using /mnt/new paths for mpq export."
        fi

        if [ ! -d "$HOME/Code2/Wow/tools/mpq/Export" ]; then
            #printf "You should run: cd $HOME/Code2/Wow/tools/mpq && ./gophercraft_mpq_set export --chain-json docs/wotlk-chain.json --working-directory \"%s/wow/Data\" --export-directory \"%s/Export\"\n" "$dir_to_use" "$export_dir"
            #printf "You should run: cd $HOME/Code2/Wow/tools/mpq && ./mopaq export --chain-json docs/wotlk-chain.json --working-directory \"%s/wow/Data\" --export-directory \"%s/Export\"\n" "$dir_to_use" "$export_dir"
            printf "You should run: cd $HOME/Code2/Wow/tools/mpq && ./mopaq export docs/wotlk-chain.json -d \"%s/wow/Data\" -o \"%s/Export\"\n" "$dir_to_use" "$export_dir"
        else
            log_ok "$HOME/Code2/Wow/tools/mpq/Export already exists."
        fi
    else
        log_warn "$HOME/Code2/Wow/tools/mpq does NOT exist. Skipping."
    fi

    # Fix mysql extension in php.ini
    log_step "Checking php.ini file"
    # Prefer the global php.ini if it exists
    PHP_INI_FILE="/etc/php/php.ini"
    PHP_INI_FOUND=false

    if [[ -f "$PHP_INI_FILE" ]]; then
        PHP_INI_FOUND=true
    else
        # Fallback: derive major.minor from `php -v` (e.g., "8.2")
        if command -v php >/dev/null 2>&1; then
            PHP_MM_VERSION="$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | awk -F. '{print $1 "." $2}')"
            FALLBACK="/etc/php/${PHP_MM_VERSION}/cli/php.ini"

            if [[ -f "$FALLBACK" ]]; then
                PHP_INI_FILE="$FALLBACK"
                PHP_INI_FOUND=true
                log_info "Using fallback php.ini: $PHP_INI_FILE"
            else
                log_warn "Neither /etc/php/php.ini nor $FALLBACK exists. Skipping."
            fi
        else
            log_warn "php not found and /etc/php/php.ini missing. Skipping."
        fi
    fi

    # If the PHP_INI_FILE contains ";extension=mysqli"
    if [ "$PHP_INI_FOUND" = true ]; then
        if grep -q ";extension=mysqli" "$PHP_INI_FILE"; then
            log_info "Found ';extension=mysqli' - updating to 'extension=mysqli'"
            sudo sed -i 's/;extension=mysqli/extension=mysqli/g' "$PHP_INI_FILE"
            log_ok "Updated mysql extension line in $PHP_INI_FILE"
        else
            log_ok "'extension=mysqli' already fixed in $PHP_INI_FILE"
        fi
    fi

    log_step "Checking databases..."
    check_dbs
}

if $justDoIt; then
    log_step "Fixing other files..."
    fix_other_files
else
    #$justInform && echo -e "\n[q] Do you want to check other files? (yes/y)" || echo -e "\n[q] Do you want to fix other files? (yes/y)"
    #read answer
    ## To lowercase using awk
    #answer=$(echo $answer | awk '{print tolower($0)}')
    #
    #if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
    #    $justInform && echo "Checking other files..." || echo "Fixing other files..."
    #    fix_other_files
    #fi

    if $justInform; then
        log_q "Do you want to check other files? (yes/y)"
    else
        log_q "Do you want to fix other files? (yes/y)"
    fi

    read -r answer
    answer="$(printf "%s" "$answer" | awk '{print tolower($0)}')"

    if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
        $justInform && log_step "Checking other files..." || log_step "Fixing other files..."
        fix_other_files
    else
        log_info "Skipping other files."
    fi
fi

