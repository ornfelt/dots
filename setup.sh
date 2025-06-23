#!/bin/bash

printf "\n***** Setting up config files! *****\n\n"

# Setup required dirs
mkdir -p $HOME/.config/
mkdir -p $HOME/.config/wezterm
mkdir -p $HOME/.local/bin/
mkdir -p $HOME/Documents $HOME/Downloads $HOME/Pictures/Wallpapers
mkdir -p $HOME/Code/c $HOME/Code/c++ $HOME/Code/c# $HOME/Code/go $HOME/Code/js $HOME/Code/python $HOME/Code/rust $HOME/Code2/C $HOME/Code2/C++ $HOME/Code2/C# $HOME/Code2/General $HOME/Code2/Go $HOME/Code2/Javascript $HOME/Code2/Lua $HOME/Code2/Python $HOME/Code2/Wow/tools

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
cp -r .config/polybar/ $HOME/.config/
cp -r .config/ranger/ $HOME/.config/
cp -r .config/rofi/ $HOME/.config/
cp -r .config/st/ $HOME/.config/
cp -r .config/yazi/ $HOME/.config/
cp -r .config/zathura/ $HOME/.config/
cp .config/mimeapps.list $HOME/.config/

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
cp .xinitrc $HOME/.xinitrc
cp .Xresources $HOME/.Xresources
cp .Xresources_cat $HOME/.Xresources_cat
cp .zshrc $HOME/.zshrc

# Update alacritty, preserving custom font size (if any)
DEFAULT_FONT_SIZE="7.0"
CURRENT_FONT_SIZE=$(grep -oP 'size:\s*\K[0-9.]*' "$HOME/.config/alacritty/alacritty.yml")

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
  echo "Current font size is $CURRENT_FONT_SIZE. Updating to $CURRENT_FONT_SIZE in source configuration before copying alacritty files."
  update_font_size ".config/alacritty/alacritty.yml" "$CURRENT_FONT_SIZE"
  update_font_size ".config/alacritty/alacritty.toml" "$CURRENT_FONT_SIZE"
fi

cp -r ".config/alacritty" "$HOME/.config/"

if [ -n "$CURRENT_FONT_SIZE" ] && [ "$CURRENT_FONT_SIZE" != "$DEFAULT_FONT_SIZE" ]; then
  echo "Reverting font size in alacritty configs to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.yml" "$DEFAULT_FONT_SIZE"
  update_font_size ".config/alacritty/alacritty.toml" "$DEFAULT_FONT_SIZE"
fi

if [ ! -f $HOME/.bash_profile ]; then
    cp -r .bash_profile $HOME/.bash_profile
else
    echo ".bash_profile already exists."
fi

# oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "oh-my-zsh already installed."
fi

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/.git" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already installed."
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/.git" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already installed."
fi

original_dir=$(pwd)
cd "$HOME/Downloads"

# polybar-themes
if [ ! -d "$HOME/Downloads/polybar-themes" ]; then
    git clone --depth=1 https://github.com/adi1090x/polybar-themes.git
    cd polybar-themes
    chmod +x setup.sh
    ./setup.sh
    cd "$original_dir"
else
    echo "polybar-themes already cloned."
fi

# gruvbox-dark-gtk theme
if [ ! -d "$HOME/.themes/gruvbox-dark-gtk" ]; then
    git clone https://github.com/jmattheis/gruvbox-dark-gtk "$HOME/.themes/gruvbox-dark-gtk"
    echo "Set gruvbox-dark theme through lxappearance (should appear through dmenu)"
else
    echo "gruvbox-dark-gtk theme already installed."
fi

# fzf
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install"
else
    echo "fzf already installed."
fi

# packer.nvim
if [ ! -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim/.git" ]; then
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    mv $HOME/.config/nvim/init.lua $HOME/.config/nvim/temp.lua
    mv $HOME/.config/nvim/install.lua $HOME/.config/nvim/init.lua
    echo "Packer installed! Now open vim and do :PackerInstall and then move temp.lua to init.lua in $HOME/.config/nvim"
else
    echo "packer already installed."
fi

# wezterm session manager
if [ ! -d "$HOME/.config/wezterm/wezterm-session-manager" ]; then
    git clone https://github.com/danielcopper/wezterm-session-manager.git $HOME/.config/wezterm/wezterm-session-manager
    echo "wezterm-session-manager installed!"
else
    echo "wezterm-session-manager already installed."
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
    echo "Downloading JetBrains Mono font..."
    cd $HOME/Downloads && wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
    
    echo "Installing JetBrains Mono font..."
    mkdir -p $HOME/.local/share/fonts/ && unzip JetBrainsMono.zip -d $HOME/.local/share/fonts/
    
    echo "Updating font cache..."
    fc-cache -fv
}

# Install fonts on debian only since arch uses the package: ttf-jetbrains-mono-nerd
if grep -qEi 'debian|raspbian' /etc/os-release; then
    if ! check_font_exists; then
        install_jetbrains_mono
    else
        echo "JetBrains Mono font already installed."
    fi
else
    echo "Install jetbrains via sudo pacman -S ttf-jetbrains-mono-nerd"
fi

# Variable to control whether to skip prompts and proceed directly
justDoIt=false
# Variable to control whether to only inform about missing repos / builds etc.
justInform=false

# Helper function
print_and_cd_to_dir() {
    local dir_path=$1
    local print_prefix=$2

    echo -e "\n--------------------------------------------------------"
    echo -e "$print_prefix projects in $dir_path...\n"
    cd "$dir_path" || exit
}

clone_repo_if_missing() {
    local repo_dir=$1
    local repo_url=$2
    local branch=$3
    local parent_dir="."

    my_repo_dirs=("my_notes" "utils" "my_js" "my_cplusplus" "my_lua")

    echo "--------------------------------------------------------"
    if printf '%s\n' "${my_repo_dirs[@]}" | grep -q "^$repo_dir$"; then
    #if [[ "${repo_dir,,}" == "my_notes" || "${repo_dir,,}" == "utils" ]]; then
        if [ -z "$GITHUB_TOKEN" ]; then
            echo "Error: GITHUB_TOKEN environment variable is not set. Skipping $repo_dir..."
            return 1
        fi
    fi

    # Case insensitive check
    if find "$parent_dir" -maxdepth 1 -type d -iname "$(basename "$repo_dir")" | grep -iq "$(basename "$repo_dir")$"; then
        echo "$repo_dir already cloned."
        return 0
    else
        if $justInform; then
            echo "$repo_dir NOT cloned."
            return 0
        fi
        echo "Cloning $repo_dir from $repo_url"

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
        eval "$clone_cmd"
        return $?
    fi
}

# Clone projects (unless they already exist)
clone_projects() {
    printf "\n***** Cloning projects! *****\n\n"

    print_and_cd_to_dir "$HOME/Documents" "Cloning"
    clone_repo_if_missing "my_notes" "https://github.com/archornf/my_notes"

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
    clone_repo_if_missing "reone" "https://github.com/seedhartha/reone"

    print_and_cd_to_dir "$HOME/Code/js" "Cloning"
    clone_repo_if_missing "KotOR.js" "https://github.com/KobaltBlu/KotOR.js"

    print_and_cd_to_dir "$HOME/Code/rust" "Cloning"
    clone_repo_if_missing "eww" "https://github.com/elkowar/eww"
    clone_repo_if_missing "swww" "https://github.com/LGFae/swww"

    print_and_cd_to_dir "$HOME/Code2/C" "Cloning"
    clone_repo_if_missing "ioq3" "https://github.com/ornfelt/ioq3"
    clone_repo_if_missing "picom-animations" "https://github.com/ornfelt/picom-animations"

    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "stk-code" "https://github.com/ornfelt/stk-code"
    if [ ! -d "stk-assets" ]; then
        if $justInform; then
            echo "$repo_dir NOT cloned."
        else
            svn co https://svn.code.sf.net/p/supertuxkart/code/stk-assets stk-assets
        fi
    else
        echo "stk-assets already cloned."
    fi
    clone_repo_if_missing "small_games" "https://github.com/ornfelt/small_games" "linux"
    clone_repo_if_missing "AzerothCore-wotlk-with-NPCBots" "https://github.com/rewow/AzerothCore-wotlk-with-NPCBots"
    ACORE_DIR="AzerothCore-wotlk-with-NPCBots/modules"
    if [ -d "$ACORE_DIR" ]; then
        cd "$ACORE_DIR"

        if [ -f /etc/arch-release ]; then
            echo "Arch Linux detected, checking out 'linux' branch..."
            git checkout linux || { echo "Failed to checkout linux branch"; exit 1; }
        fi

        clone_repo_if_missing "mod-eluna" "https://github.com/azerothcore/mod-eluna"
        cd ../..
    else
        echo "Directory $DIR does NOT exist."
    fi
    clone_repo_if_missing "Trinitycore-3.3.5-with-NPCBots" "https://github.com/rewow/Trinitycore-3.3.5-with-NPCBots" "npcbots_3.3.5"
    clone_repo_if_missing "simc" "https://github.com/ornfelt/simc"
    clone_repo_if_missing "OpenJKDF2" "https://github.com/ornfelt/OpenJKDF2" "linux"
    clone_repo_if_missing "devilutionX" "https://github.com/ornfelt/devilutionX"
    clone_repo_if_missing "crispy-doom" "https://github.com/ornfelt/crispy-doom"
    clone_repo_if_missing "dhewm3" "https://github.com/ornfelt/dhewm3"

    clone_repo_if_missing "my_cplusplus" "https://github.com/ornfelt/my_cplusplus"
    clone_repo_if_missing "japp" "https://github.com/ornfelt/japp"
    clone_repo_if_missing "mangos-classic" "https://github.com/ornfelt/mangos-classic"
    clone_repo_if_missing "core" "https://github.com/ornfelt/core"
    clone_repo_if_missing "server" "https://github.com/ornfelt/server"

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
        echo -e "\nDo you want to check cloned projects? (yes/y)"
    else
        echo -e "\nDo you want to proceed with cloning projects? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        clone_projects
    fi
fi

# Function to install if binary doesn't exist
install_if_missing() {
    local binary=$1
    local directory=$2

    echo "--------------------------------------------------------"
    if ! command -v $binary &> /dev/null; then
        echo "$binary NOT found..."
        if $justInform; then
            return 0
        fi
        echo "installing: $binary"
        cd $HOME/.config/$directory || exit

        if [ "$binary" == "dwmblocks" ]; then
            ./compile.sh
        else
            sudo make clean install
        fi

        cd - || exit # Return to previous directory
    else
        echo "$binary exists, skipping installation."
    fi
}

ask_for_compile() {
    local dir_name=$1

    read -p "Compile $dir_name? (yes/y to confirm): " user_input
    if [[ "$user_input" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Proceeding with compilation of $dir_name..."
    else
        echo "Skipping compilation of $dir_name."
        return 1 # False
    fi
}

check_dir() {
    local dir_name=$1
    local dir_type=${2:-build} # Default to build
    echo "--------------------------------------------------------"

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
                echo "${target_dir} already compiled."
                return 1 # Return false
            else
                if $justInform; then
                    echo "${target_dir} NOT compiled."
                    return 1
                fi

                if ! ask_for_compile "$dir_name"; then
                    return 1
                fi
    
                echo "Entering ${actual_dir_name}..."
                cd "./${actual_dir_name}"
                sleep 1
                return 0 # Return true
            fi
        else
            if [ -d "$target_dir" ]; then
                echo "${target_dir} already compiled."
                return 1 # Return false
            else
                if $justInform; then
                    echo "${target_dir} NOT compiled."
                    return 1
                fi

                if ! ask_for_compile "$dir_name"; then
                    return 1
                fi

                if [[ "$dir_type" == *"build"* ]]; then
                    echo "Creating and entering ${target_dir}..."
                    mkdir -p "$target_dir" && cd "$target_dir"
                else
                    echo "Entering ${actual_dir_name}..."
                    cd "./${actual_dir_name}"
                fi
                sleep 1
                return 0 # Return true
            fi
        fi
    else
        echo "Directory $dir_name does NOT exist."
        return 1 # Return false
    fi
}

check_file() {
    local dir_name=$1
    local file_path=$2
    echo "--------------------------------------------------------"

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
        echo "${dir_name} already compiled."
        return 1 # Return false
    else
        echo "File ${file_path} in ${dir_name} does NOT exist."
        if $justInform; then
            echo "${dir_name} NOT compiled."
            return 1
        fi

        if ! ask_for_compile "$dir_name"; then
            return 1
        fi

        echo "Entering ${actual_dir_name}..."
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
            echo "Changed ownership of $dir to $USER"
        else
            echo "Ownership of $dir is already set to $CURRENT_USER, skipping chown"
        fi
    else
        echo "Directory $dir does NOT exist, skipping."
    fi
}

fix_ownerships() {
    local CURRENT_USER=$(whoami)
    local NPM_PREFIX=$(npm config get prefix)
    sudo mkdir -p "$NPM_PREFIX/lib/node_modules"

    # Check ownership and change only if necessary
    #for dir in "$NPM_PREFIX/lib/node_modules" "$NPM_PREFIX/bin" "$NPM_PREFIX/share"; do
    for dir in "$NPM_PREFIX/lib/node_modules"; do
        if [ -d "$dir" ]; then
            # Get owner of dir
            local DIR_OWNER=$(stat -c '%U' "$dir")
            if [ "$DIR_OWNER" != "$CURRENT_USER" ]; then
                sudo chown -R "$CURRENT_USER" "$dir"
                echo "Changed ownership of $dir to $CURRENT_USER"
            else
                echo "Ownership of $dir is already set to $CURRENT_USER, skipping chown"
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
        "$HOME/Code2/C++/core"
        "$HOME/Code2/C++/server"
        "$HOME/Code2/Wow/tools/BLPConverter"
        "$HOME/Code2/Wow/tools/StormLib"
        "$HOME/.local/share/openjk"
        "$HOME/cmangos"
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
    printf "\n***** Compiling projects! *****\n\n"
    architecture=$(uname -m)
    echo -e "Identified architecture: $architecture\n"
    fix_ownerships

    echo -e "\nCompiling projects in $HOME/.config..."
    install_if_missing dwm dwm
    install_if_missing dwmblocks dwmblocks
    install_if_missing dmenu dmenu
    install_if_missing st st

    export CMAKE_POLICY_VERSION_MINIMUM=3.5

    print_and_cd_to_dir "$HOME/Code/c" "Compiling"

    #if grep -q -E "Debian|Raspbian" /etc/os-release; then
    #    if check_dir "neovim"; then
    #        cd ..
    #        if dpkg -l | grep -qw "neovim"; then
    #            sudo apt remove neovim -y
    #        fi
    #        git checkout stable
    #        make CMAKE_BUILD_TYPE=RelWithDebInfo
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
            echo "Unsupported Linux distribution."
            exit 1
        fi

        if [ ! -z "$mygui_version" ]; then
            echo "MyGUI version detected: $mygui_version"

            if [ -f /etc/debian_version ]; then
                if [[ "$mygui_version" == "3.4.2"* ]]; then
                    echo "MyGUI version is 3.4.2"
                    git checkout 1c2f92cac9
                elif [[ "$mygui_version" == "3.4.1"* ]]; then
                    echo "MyGUI version is 3.4.1"
                    git checkout abb71eeb
                else
                    echo "MyGUI version is: $mygui_version"
                fi
            fi
            #cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            cmake .. -DCMAKE_BUILD_TYPE=Release
            make -j$(nproc)
            sudo make install
            
            # Note** If you are having undefined reference errors while
            # compiling, its possible that you have previously installed a
            # different openscenegraph version than what openMW depends on.
            # To remove it, you can use:
            # #removes just package
            # apt-get remove <yourOSGversion>
            # #or 
            # #removes configurations as well
            # apt-get remove --purge <yourOSGversion>

            #cd ...
            #cd ../..
        else
            echo "MyGUI is not installed or not found."
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

    print_and_cd_to_dir "$HOME/Code/js" "Compiling"

    if check_dir "KotOR.js" "node_modules"; then
        npm install
        #npm run webpack:dev-watch
        npm run webpack:dev -- --no-watch # No watch to exit after compile
        cd "$HOME/Code/js"
    fi

    print_and_cd_to_dir "$HOME/Code/rust" "Compiling"

    if ! command -v rustc &>/dev/null; then
        echo "rustc is not installed. Skipping rust projects..."
    else
        # Only compile if rust version is > 1.63
        #rust_version=$(rustc --version | awk '{print $2}') # Also works...
        rust_version=$(rustc --version | grep -oP 'rustc \K[^\s]+')
        major_version=$(echo "$rust_version" | cut -d'.' -f1)
        minor_version=$(echo "$rust_version" | cut -d'.' -f2)
        echo "Rust version: $rust_version"
        echo "major: $major_version"
        echo "minor: $minor_version"

        if grep -qEi 'arch' /etc/os-release; then
            if check_dir "eww" "target"; then
                if [ "$major_version" -gt 1 ] || { [ "$major_version" -eq 1 ] && [ "$minor_version" -gt 63 ]; }; then
                    echo "rustc version is above 1.63"
                    cargo build --release --no-default-features --features x11
                    cd target/release
                    chmod +x ./eww
                else
                    cd ..
                    echo "rustc version is 1.63 or below. Skipping rust project..."
                fi
                cd "$HOME/Code/rust"
            fi

            if check_dir "swww" "target"; then
                if [ "$major_version" -gt 1 ] || { [ "$major_version" -eq 1 ] && [ "$minor_version" -gt 63 ]; }; then
                    echo "rustc version is above 1.63"
                    cargo build --release
                else
                    cd ..
                    echo "rustc version is 1.63 or below. Skipping rust project..."
                fi
                cd "$HOME/Code/rust"
            fi
        else
            OS_ID=$(grep "^ID=" /etc/os-release | cut -d'=' -f2)
            echo "Skipping compilation of eww and swww (only for Arch). Found os: $OS_ID"
        fi
    fi

    print_and_cd_to_dir "$HOME/Code2/C" "Compiling"

    if check_dir "ioq3"; then
        cd ..
        make
        cd "$HOME/Code2/C"
    fi

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
            echo "The Python package 'cogapp' needs to be installed for compiling OpenJKDF2..."
        else
            export CC=clang
            export CXX=clang++
            source build_linux64.sh
        fi
        cd "$HOME/Code2/C++"
    fi

    if check_dir "devilutionX" "build*"; then
        if grep -qEi 'debian|raspbian' /etc/os-release; then
            echo "Running on Debian or Raspbian. Installing smpq package from tools script."
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

    if check_dir "core"; then
        cmake .. -DDEBUG=0 -DSUPPORTED_CLIENT_BUILD=5875 -DUSE_EXTRACTORS=1 -DCMAKE_INSTALL_PREFIX=$HOME/vmangos
        make -j$(nproc)
        sudo make install
        cd "$HOME/Code2/C++"
    fi

    if check_dir "server"; then
        cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=1 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run
        make -j$(nproc)
        sudo make install
        sudo chown -R $USER:$USER $HOME/mangoszero
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
            echo "Go is not installed..."
            exit 1
        fi

        MAJOR_MINOR=$(echo "$GO_VERSION" | grep -oP 'go\d+\.\d+' | grep -oP '\d+\.\d+')
        IFS='.' read -r MAJOR MINOR PATCH <<< "$MAJOR_MINOR.0" # Adding .0 to handle versions without patch number

        echo "Go version: $MAJOR_MINOR"
        echo "Go major version: $MAJOR"
        echo "Go minor version: $MINOR"

        if (( MAJOR < 1 )) || { (( MAJOR == 1 )) && (( MINOR < 21 )); } || { (( MAJOR == 1 )) && (( MINOR == 21 )) && (( PATCH < 1 )); }; then
            echo "Go version is below 1.21.1. Installing go 1.21.1..."
            # Don't install dependencies through apt since they are too old for
            # this repo...
            curl -O https://dl.google.com/go/go1.21.1.linux-amd64.tar.gz
            sudo rm -rf /usr/local/go 
            sudo rm /usr/bin/go
            sudo tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc
            echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
            echo 'export PATH=$PATH:$GOPATH/bin' >> $HOME/.bashrc
            source $HOME/.bashrc
        else
            echo "Go version is 1.21.1 or higher. Continuing with install..."
        fi
        #sudo apt update && sudo apt upgrade
        sudo apt install protobuf-compiler
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

    cd "$original_dir"
}

if $justDoIt; then
    compile_projects
else
    if $justInform; then
        echo -e "\nDo you want to check compiled projects? (yes/y)"
    else
        echo -e "\nDo you want to proceed with compiling projects? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        compile_projects
    fi
fi

check_pip_packages() {
    printf "\n***** Checking pip packages! *****\n\n"
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
    echo -e "\nPackages in requirements.txt but not installed:\n"
    for pkg in "${!reqs[@]}"; do
        if [[ ! ${installed["$pkg"]} ]]; then
            echo "$pkg"
        fi
    done

    # Compare: find installed packages not in requirements.txt
    echo -e "\nInstalled packages not in requirements.txt:\n"
    for pkg in "${!installed[@]}"; do
        if [[ ! ${reqs["$pkg"]} ]]; then
            echo "$pkg"
        fi
    done
}

install_pip_packages() {
    printf "\n***** Installing pip packages! *****\n\n"
    #pip3 install -r $HOME/Documents/installation/requirements.txt
    requirements_path="$HOME/Documents/installation/requirements.txt"

    # Read each line in requirements.txt, remove version specifications, and install
    while read -r package || [[ -n $package ]]; do
        package_name=$(echo "$package" | cut -d'=' -f1)
        pip3 install "$package_name"
    done < "$requirements_path"
}

# Install python packages
if $justDoIt; then
    echo "Installing python packages..."
    install_pip_packages
else
    if $justInform; then
        echo -e "\nDo you want to check python packages? (yes/y)"
    else
        echo -e "\nDo you want to install python packages? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        if $justInform; then
            echo "Checking python packages..."
            check_pip_packages
        else
            echo "Installing python packages..."
            install_pip_packages
        fi
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
                echo "$BASE_NAME already exists in /mnt/new/, skipping copy."
                return 0
            elif [ -d "$ALT_DEST_MEDIA" ]; then
                echo "$BASE_NAME already exists in /media/, skipping copy."
                return 0
            fi

            $justInform && echo "Copied $SRC to $DEST" && return 0

            cp -r "$SRC" "$DEST"
            echo "Copied $SRC to $DEST"
        else
            echo "$DEST already exists, skipping copy."
        fi
    else
        echo "$SRC does NOT exist, skipping."
    fi
}

check_space() {
    printf "Checking disk space...\n"
    local dir=$1
    local min_space_gb=40
    local available_space_kb=$(df "$dir" --output=avail | tail -n 1)
    local available_space_gb=$((available_space_kb / 1024 / 1024))

    if (( available_space_gb > min_space_gb )); then
        echo "Disk at $dir has more than $min_space_gb GB available. Space left: $available_space_gb GB"
        return 0
    else
        echo "Disk at $dir does not have more than $min_space_gb GB available. Space left: $available_space_gb GB"
        return 1
    fi
}

copy_game_data() {
    printf "\n***** Copying game data! *****\n\n"
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
            echo -e "\nFound mounted hard drive at: $MEDIA_PATH\n"
            break
        fi
    done

    # Check if MEDIA_PATH was set
    if [ -z "$MEDIA_PATH" ]; then
        echo "The hard drive is not mounted."
        return 1
    fi

    # Directories to copy from 2024
    DIRS=("wow" "wow_classic" "wow_retail" "cata")
    if [ -d "/mnt/new/other" ]; then
        DOWNLOADS_DIR="/mnt/new"
    else
        DOWNLOADS_DIR="$HOME/Downloads"
    fi

    # Check space 
    if [ "$DOWNLOADS_DIR" = "/mnt/new" ]; then
        if ! check_space "$DOWNLOADS_DIR"; then
            echo "Not enough space on disk... Skipping."
            return 1
        fi
    else
        if ! check_space "/"; then
            echo "Not enough space on disk... Skipping."
            return 1
        fi
    fi

    echo -e "\n***Copying wow, wow_classic, wow_retail and cata to $DOWNLOADS_DIR***"
    for dir in "${DIRS[@]}"; do
        SRC="$MEDIA_PATH/2024/$dir"
        DEST="$DOWNLOADS_DIR/$dir"
        copy_dir_to_target "$SRC" "$DEST"
    done

    # AzerothCore
    DEST_DIR="$HOME/acore/bin"
    echo -e "\n***Copying acore files to $DEST_DIR***"
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
    #            echo "Copied $script to $DEST_DIR/lua_scripts/$script_name"
    #        else
    #            echo "$DEST_DIR/lua_scripts/$script_name already exists, skipping copy."
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
                        echo "Copied directory $item to $DEST_DIR/lua_scripts/$item_name"
                    else
                        echo "Directory $DEST_DIR/lua_scripts/$item_name already exists, skipping copy."
                    fi
                else
                    # Copy the file
                    if [ ! -f "$DEST_DIR/lua_scripts/$item_name" ]; then
                        cp "$item" "$DEST_DIR/lua_scripts/$item_name"
                        echo "Copied file $item to $DEST_DIR/lua_scripts/$item_name"
                    else
                        echo "File $DEST_DIR/lua_scripts/$item_name already exists, skipping copy."
                    fi
                fi
            fi
        done
    else
        echo "$LUA_SRC does NOT exist, skipping."
    fi

    # TrinityCore
    DEST_DIR="$HOME/tcore/bin"
    echo -e "\n***Copying tcore files to $DEST_DIR***"
    #cp -r "$MEDIA_PATH/2024/tcore/"* "$HOME/tcore/bin"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/dbc_old" "$DEST_DIR/dbc_old"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/tcore/vmaps" "$DEST_DIR/vmaps"
    #[ -f "$HOME/tcore/bin/TDB_full_world_335.23061_2023_06_14.sql" ] && echo "File already exists, skipping copy." || (cp "$MEDIA_PATH/2024/tcore/TDB_full_world_335.23061_2023_06_14.sql" "$HOME/tcore/bin/" && echo "Copied TDB_full_world_335.23061_2023_06_14.sql to $HOME/tcore/bin")
    FILE_NAME="TDB_full_world_335.23061_2023_06_14.sql"
    SRC_FILE="$MEDIA_PATH/2024/tcore/$FILE_NAME"
    DEST_FILE="$HOME/tcore/bin/$FILE_NAME"
    if [ -f "$DEST_FILE" ]; then
        echo "File already exists, skipping copy."
    else
        cp "$SRC_FILE" "$DEST_FILE"
        echo "Copied $FILE_NAME to $HOME/tcore/bin"
    fi

    # Cmangos
    DEST_DIR="$HOME/cmangos/run/bin"
    echo -e "\n***Copying cmangos files to $DEST_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/cmangos/x64_RelWithDebInfo/vmaps" "$DEST_DIR/vmaps"

    # Vmangos
    DEST_DIR="$HOME/vmangos/bin"
    echo -e "\n***Copying vmangos files to $DEST_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/Cameras" "$DEST_DIR/Cameras"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/5875" "$DEST_DIR/5875"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/vmangos/RelWithDebInfo/vmaps" "$DEST_DIR/vmaps"

    # Mangoszero
    DEST_DIR="$HOME/mangoszero/run/etc"
    echo -e "\n***Copying mangoszero files to $DEST_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/dbc" "$DEST_DIR/dbc"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/maps" "$DEST_DIR/maps"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/mmaps" "$DEST_DIR/mmaps"
    copy_dir_to_target "$MEDIA_PATH/2024/mangoszero/RelWithDebInfo/vmaps" "$DEST_DIR/vmaps"
    
    # db backups
    echo -e "\n***Copying db_bkp files to $HOME/Documents***"
    copy_dir_to_target "$MEDIA_PATH/2024/db_bkp" "$HOME/Documents/db_bkp"

    # Diablo
    SRC_DIABLO="$MEDIA_PATH/2024/diasurgical/devilution"
    DEST_DIR_DIABLO="$HOME/Code2/C++/devilutionX/build"
    echo -e "\n***Copying diablo files to $DEST_DIR_DIABLO***"
    if [ -d "$SRC_DIABLO" ]; then
        mkdir -p "$DEST_DIR_DIABLO"
        for file in "$SRC_DIABLO"/*; do
            file_name=$(basename "$file")
            if [ ! -f "$DEST_DIR_DIABLO/$file_name" ]; then
                cp "$file" "$DEST_DIR_DIABLO/$file_name"
                echo "Copied $file to $DEST_DIR_DIABLO/$file_name"
            else
                echo "$DEST_DIR_DIABLO/$file_name already exists, skipping copy."
            fi
        done
    else
        echo "$SRC_DIABLO does NOT exist, skipping."
    fi

    # doom3
    echo -e "\n***Copying doom3 files to $DOWNLOADS_DIR***"
    if [ ! -d "$DOWNLOADS_DIR/doom3" ]; then
        cp "$MEDIA_PATH/2024/doom3_base.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/doom3_base.zip" -d "$DOWNLOADS_DIR/doom3"
        echo "Copied and unzipped doom3_base.zip to $DOWNLOADS_DIR/doom3"
    else
        echo "$DOWNLOADS_DIR/doom3 already exists, skipping copy and unzip."
    fi

    # doom
    echo -e "\n***Copying doom files to $DOWNLOADS_DIR***"
    if [ ! -d "$DOWNLOADS_DIR/doom" ]; then
        unzip DOOM.zip -d "$DOWNLOADS_DIR"
        cp "$MEDIA_PATH/2024/DOOM.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/DOOM.zip" -d "$DOWNLOADS_DIR/doom"
        echo "Copied and unzipped DOOM.zip to $DOWNLOADS_DIR/doom"
    else
        echo "$DOWNLOADS_DIR/doom already exists, skipping copy and unzip."
    fi

    echo -e "\n***Copying GTA3 files to $DOWNLOADS_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/GTA3" "$DOWNLOADS_DIR/gta3"
    echo -e "\n***Copying GTA_VICE files to $DOWNLOADS_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/GTA_VICE" "$DOWNLOADS_DIR/gta_vice"

    # jo
    echo -e "\n***Copying JediOutcast files to $HOME/.local/share/openjk/JediOutcast/base***"
    if [ ! -f "$HOME/.local/share/openjk/JediOutcast/base/assets0.pk3" ]; then
        cp "$MEDIA_PATH/2024/jedi_outcast_gamedata.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/jedi_outcast_gamedata.zip" -d "$DOWNLOADS_DIR/jedi_outcast_gamedata"
        cp "$DOWNLOADS_DIR/jedi_outcast_gamedata/base"/*.pk3 "$HOME/.local/share/openjk/JediOutcast/base/"
        echo "Copied and unzipped jedi_outcast_gamedata.zip and moved *.pk3 files to $HOME/.local/share/openjk/JediOutcast/base/"
    else
        echo "assets0.pk3 already exists in $HOME/.local/share/openjk/JediOutcast/base/, skipping copy and unzip."
    fi

    # ja
    echo -e "\n***Copying JediAcademy files to $HOME/.local/share/openjk/JediAcademy/base***"
    # Not 100% sure about JediKnightGalaxies and jk2mv...
    if [ ! -f "$HOME/.local/share/openjk/JediAcademy/base/assets0.pk3" ] && [ ! -f "$HOME/.local/share/openjk/base/assets0.pk3" ]; then
        cp "$MEDIA_PATH/2024/JK_JA_GameData.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/JK_JA_GameData.zip" -d "$DOWNLOADS_DIR/JK_JA_GameData"
        cp "$DOWNLOADS_DIR/JK_JA_GameData/base"/*.pk3 "$HOME/.local/share/openjk/JediAcademy/base"
        echo "Copied and unzipped JK_JA_GameData.zip and moved *.pk3 files to $HOME/.local/share/openjk/JediAcademy/base"
    else
        echo "assets0.pk3 already exists in $HOME/.local/share/openjk/JediAcademy/base or $HOME/.local/share/openjk/base, skipping copy and unzip."
    fi

    # my_docs
    echo -e "\n***Copying my_docs files to $HOME/Documents***"
    copy_dir_to_target "$MEDIA_PATH/2024/my_docs" "$HOME/Documents/my_docs"

    # openmw
    echo -e "\n***Copying openmw files to $DOWNLOADS_DIR***"
    if [ ! -d "$DOWNLOADS_DIR/Morrowind" ] && [ ! -d "/mnt/new/openmw_gamedata" ]; then
        cp "$MEDIA_PATH/2024/Morrowind.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/Morrowind.zip" -d "$DOWNLOADS_DIR/Morrowind"
        echo "Copied and unzipped Morrowind.zip to $DOWNLOADS_DIR/Morrowind"
    else
        echo "$DOWNLOADS_DIR/Morrowind or /mnt/new/openmw_gamedata already exists, skipping copy and unzip."
    fi

    # openjkdf2
    echo -e "\n***Copying openjkdf2 files to $HOME/.local/share/OpenJKDF2/openjkdf2***"
    if [ ! -d "$HOME/.local/share/OpenJKDF2/openjkdf2/Episode" ]; then
        cp -r "$MEDIA_PATH/2024/star_wars_jkdf2/"* "$HOME/.local/share/OpenJKDF2/openjkdf2"
        echo "Copied all files and directories from star_wars_jkdf2 to $HOME/.local/share/OpenJKDF2/openjkdf2"
    else
        echo "Episode directory already exists in $HOME/.local/share/OpenJKDF2/openjkdf2, skipping copy."
    fi

    # kotor
    echo -e "\n***Copying kotor files to $DOWNLOADS_DIR***"
    if [ ! -d "$DOWNLOADS_DIR/kotor" ]; then
        cp "$MEDIA_PATH/2024/Star Wars - KotOR.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/Star Wars - KotOR.zip" -d "$DOWNLOADS_DIR/kotor"
        echo "Copied and unzipped 'Star Wars - KotOR.zip' to $DOWNLOADS_DIR/kotor"
    else
        echo "$DOWNLOADS_DIR/kotor already exists, skipping copy and unzip."
    fi

    # kotor2
    echo -e "\n***Copying kotor2 files to $DOWNLOADS_DIR***"
    if [ ! -d "$DOWNLOADS_DIR/kotor2" ]; then
        cp "$MEDIA_PATH/2024/Star Wars - KotOR2.zip" "$DOWNLOADS_DIR"
        unzip "$DOWNLOADS_DIR/Star Wars - KotOR2.zip" -d "$DOWNLOADS_DIR/kotor2"
        echo "Copied and unzipped 'Star Wars - KotOR2.zip' to $DOWNLOADS_DIR/kotor2"
    else
        echo "$DOWNLOADS_DIR/kotor2 already exists, skipping copy and unzip."
    fi

    # stk addons
    echo -e "\n***Copying stk addon files to $HOME/.local/share/supertuxkart/addons***"
    for dir in "$MEDIA_PATH/2024/stk_addons"/*; do
        if [ -d "$dir" ]; then
            dest_dir="$HOME/.local/share/supertuxkart/addons/$(basename "$dir")"
            if [ ! -d "$dest_dir" ]; then
                cp -r "$dir" "$dest_dir"
                echo "Copied $(basename "$dir") to $HOME/.local/share/supertuxkart/addons"
            else
                echo "$(basename "$dir") already exists in $HOME/.local/share/supertuxkart/addons, skipping copy."
            fi
        fi
    done

    # ioq3
    echo -e "\n***Copying ioq3 files to $HOME/Code2/C/ioq3/build/release-linux-x86_64/baseq3/***"
    for file in "$MEDIA_PATH/2024/baseq3/"*.pk3; do
        if [ -f "$file" ]; then
            dest_file="$HOME/Code2/C/ioq3/build/release-linux-x86_64/baseq3/$(basename "$file")"
            if [ ! -f "$dest_file" ]; then
                cp "$file" "$dest_file"
                echo "Copied $(basename "$file") to $HOME/Code2/C/ioq3/build/release-linux-x86_64/baseq3/"
            else
                echo "$(basename "$file") already exists in $HOME/Code2/C/ioq3/build/release-linux-x86_64/baseq3/, skipping copy."
            fi
        fi
    done

    # Diablo 2
    echo -e "\n***Copying d2 files to $DOWNLOADS_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/d2" "$DOWNLOADS_DIR/d2"

    # Jar files
    echo -e "\n***Copying jar files to $DOWNLOADS_DIR***"
    copy_dir_to_target "$MEDIA_PATH/2024/jar_files" "$DOWNLOADS_DIR/jar_files"

    # TODO:
    # Copy llama models?
    # baby-yoda and other joja mods...
    # star_wars_ja_mods
    # star_wars_jo_mods
    # wezterm compile for deb...
}

if $justDoIt; then
    echo "Copying game data..."
    copy_game_data
else
    if $justInform; then
        echo -e "\nDo you want to check game data? (yes/y)"
    else
        echo -e "\nDo you want to copy game data? (yes/y)"
    fi
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        $justInform && echo "Checking game data..." || echo "Copying game data..."
        copy_game_data
    fi
fi

# Check if database exists
check_database_exists() {
    local db_name=$1
    result=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" -P"$MYSQL_PORT" -e "SHOW DATABASES LIKE '$db_name';" 2>/dev/null)
    if [[ "$result" == *"$db_name"* ]]; then
        echo "Database $db_name exists."
    else
        echo "Database $db_name does NOT exist."
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
        echo "Error: MYSQL_ROOT_PWD environment variable is not set. Exiting..."
        exit 1
    fi

    if ! command -v mysql &> /dev/null; then
        echo "mysql command not found. Please install MySQL client. Exiting..."
        exit 1
    fi

    MYSQL_USER="root"
    MYSQL_PASSWORD="$MYSQL_ROOT_PWD"
    MYSQL_HOST="localhost"
    MYSQL_PORT=3306

    # Check vmangos, cmangos, mangoszero, acore and tcore databases
    databases=(
        "vmangos_realmd" "vmangos_mangos" "vmangos_characters" "vmangos_logs"
        "classicrealmd" "classicmangos" "classiccharacters" "classiclogs"
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
    printf "\n***** Fixing other files! *****\n\n"

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
            echo "No valid Diablo 2 directory found."
        fi

        if [ -n "$NEW_PATH" ]; then
            NEW_PATH="${NEW_PATH}d2video"
        fi

        ESCAPED_NEW_PATH=$(echo "$NEW_PATH" | sed 's/\\/\\\\/g')

        # Update config.json file with new path
        sed -i "s|\"MpqPath\": \".*\"|\"MpqPath\": \"$ESCAPED_NEW_PATH\"|g" $HOME/.config/OpenDiablo2/config.json
        echo "Updated config.json with new MpqPath path: $NEW_PATH"
    else
        echo "$HOME/.config/config.json does NOT exist yet. OpenDiablo2 has not been run yet..."
    fi

    # japp aka japlus
    #cp $HOME/Code2/C++/japp/*.so $HOME/.local/share/openjk/japlus/
    echo -e "\n"
    SRC_DIR="$HOME/Code2/C++/japp"
    DEST_DIR="$HOME/.local/share/openjk/japlus"

    if [ -d "$SRC_DIR" ] && [ -d "$DEST_DIR" ]; then
        for file in "$SRC_DIR"/*.so; do
            if [ -f "$file" ]; then
                dest_file="$DEST_DIR/$(basename "$file")"
                if [ ! -f "$dest_file" ]; then
                    cp "$file" "$dest_file"
                    printf "Copied %s to %s\n" "$(basename "$file")" "$DEST_DIR"
                else
                    printf "%s already exists in %s, skipping copy.\n" "$(basename "$file")" "$DEST_DIR"
                fi
            fi
        done
    else
        echo "Either source directory ($SRC_DIR) or destination directory ($DEST_DIR) does not exist. Skipping copy of japlus lib files..."
    fi

    # Copy japp-assets to japlus dir
    echo -e "\n"
    SRC_DIR="$HOME/Code2/Lua/my_lua/my_stuff/japp-assets"
    DEST_DIR="$HOME/.local/share/openjk/japlus"
    # Use rsync to copy only files and directories that don't already exist in the destination
    #rsync -av --ignore-existing "$SRC_DIR/" "$DEST_DIR/"
    if [ -d "$SRC_DIR" ] && [ -d "$DEST_DIR" ]; then
        for item in "$SRC_DIR"/*; do
            base_item=$(basename "$item")
            
            if [ ! -e "$DEST_DIR/$base_item" ]; then
                cp -r "$item" "$DEST_DIR"
                echo "Copied $item to $DEST_DIR"
            else
                echo "$DEST_DIR/$base_item already exists, skipping"
            fi
        done
    else
        echo "Either source directory ($SRC_DIR) or destination directory ($DEST_DIR) does not exist. Skipping copy of japp-assets..."
    fi
    
    # Python
    echo -e "\n"
    if grep -qEi 'debian|raspbian' /etc/os-release; then
        if [ ! -f /usr/bin/python ]; then
            sudo cp /usr/bin/python3 /usr/bin/python
            echo "Copied /usr/bin/python3 to /usr/bin/python"
        else
            echo "/usr/bin/python already exists, skipping copy."
        fi
    else
        OS_ID=$(grep "^ID=" /etc/os-release | cut -d'=' -f2)
        echo "Skipping copy of python binary (only for Debian or Raspbian architectures). Found os: $OS_ID"
    fi

    # vmangos
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "vmangos_db" "https://github.com/brotalnia/database"

    echo -e "\nSetting up vmangos conf files\n"
    #cp $HOME/vmangos/etc/mangosd.conf.dist $HOME/vmangos/etc/mangosd.conf
    #cp $HOME/vmangos/etc/realmd.conf.dist $HOME/vmangos/etc/realmd.conf
    python3 $HOME/Documents/my_notes/scripts/wow/update_conf_classic.py "vmangos"
    # Follow vmangos install notes from setup_notes.txt...

    # cmangos
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "classic-db" "https://github.com/cmangos/classic-db"

    echo -e "\nSetting up cmangos conf files\n"
    #cp $HOME/cmangos/run/etc/aiplayerbot.conf.dist $HOME/cmangos/run/etc/aiplayerbot.conf
    #cp $HOME/cmangos/run/etc/ahbot.conf.dist $HOME/cmangos/run/etc/ahbot.conf
    #cp $HOME/cmangos/run/etc/mangosd.conf.dist $HOME/cmangos/run/etc/mangosd.conf
    #cp $HOME/cmangos/run/etc/realmd.conf.dist $HOME/cmangos/run/etc/realmd.conf
    python3 $HOME/Documents/my_notes/scripts/wow/update_conf_classic.py "cmangos"
    # Follow cmangos install notes from setup_notes.txt...

    # mangoszero
    print_and_cd_to_dir "$HOME/Code2/C++" "Cloning"
    clone_repo_if_missing "mangoszero_db" "https://github.com/mangoszero/database"

    src_dir="$HOME/Documents/my_notes/sql/wow/mangoszero"
    dest_dir="$HOME/Code2/C++/mangoszero_db"
    if [ -d "$src_dir" ]; then
        if [ -d "$dest_dir" ]; then
            cp -r "$src_dir"/* "$dest_dir"
            echo -e "\nAll files copied from $src_dir to $dest_dir."
        fi
    else
        echo -e "\n$src_dir does NOT exist. Can't copy mangoszero sql files from it..."
    fi

    # Fix liblua...
    if grep -qEi 'debian|raspbian' /etc/os-release; then
        if [ -f "/usr/lib/x86_64-linux-gnu/liblua5.2.so" ]; then
            echo "/usr/lib/x86_64-linux-gnu/liblua5.2.so exists."

            if [ ! -f "/usr/lib/x86_64-linux-gnu/liblua52.so" ]; then
                echo -e "\n/usr/lib/x86_64-linux-gnu/liblua52.so does NOT exist. Copying it."
                sudo cp /usr/lib/x86_64-linux-gnu/liblua5.2.so /usr/lib/x86_64-linux-gnu/liblua52.so
            else
                echo -e "\n/usr/lib/x86_64-linux-gnu/liblua52.so already exists."
            fi
        else
            echo -e "\n/usr/lib/x86_64-linux-gnu/liblua5.2.so does NOT exist. Skipping."
        fi
    fi

    # Check if $HOME/mangoszero/run/bin exists
    if [ -d "$HOME/mangoszero/run/bin" ]; then
        echo "$HOME/mangoszero/run/bin exists."

        if [ ! -d "$HOME/mangoszero/run/etc" ]; then
            echo "$HOME/mangoszero/run/etc does NOT exist."

            if [ -d "$HOME/mangoszero/etc" ]; then
                echo "$HOME/mangoszero/etc exists. Moving it to $HOME/mangoszero/run/"
                mv "$HOME/mangoszero/etc" "$HOME/mangoszero/run/"
            fi
        fi

        echo -e "\nSetting up mangoszero conf files\n"
        #cp "$HOME/mangoszero/run/etc/aiplayerbot.conf.dist" "$HOME/mangoszero/run/etc/aiplayerbot.conf"
        #cp "$HOME/mangoszero/run/etc/ahbot.conf.dist" "$HOME/mangoszero/run/etc/ahbot.conf"
        #cp "$HOME/mangoszero/run/etc/mangosd.conf.dist" "$HOME/mangoszero/run/etc/mangosd.conf"
        #cp "$HOME/mangoszero/run/etc/realmd.conf.dist" "$HOME/mangoszero/run/etc/realmd.conf"
        python3 $HOME/Documents/my_notes/scripts/wow/update_conf_classic.py "mangoszero"
        # Follow mangoszero install notes from setup_notes.txt...
    else
        echo "$HOME/mangoszero/run/bin does NOT exist. Skipping."
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
    for target_dir in "${TARGET_DIRS[@]}"; do
        for source_file in "${SOURCE_FILES[@]}"; do
            file_name=$(basename "$source_file")
            target_file="$target_dir/$file_name"

            if [ ! -f "$target_file" ]; then
                sudo cp "$source_file" "$target_file"
                echo "Copied $source_file to $target_file"
            else
                echo "$target_file already exists. Skipping."
            fi
        done
    done

    echo -e "\nSetting up AzerothCore conf files\n"
    python3 $HOME/Documents/my_notes/scripts/wow/update_conf.py "acore"
    echo -e "\nSetting up TrinityCore conf files\n"
    python3 $HOME/Documents/my_notes/scripts/wow/update_conf.py "tcore"
    # Follow acore / tcore install notes in setup_notes.txt or setup db from
    # existing dbs in db_bkp

    echo -e "\nChecking mpq files\n"
    # Check mpq exports
    if [ -d "$HOME/Code2/Wow/tools/mpq" ]; then
        echo "$HOME/Code2/Wow/tools/mpq exists."

        dir_to_use="$HOME/Downloads"
        export_dir="$HOME/Code2/Wow/tools/mpq"
        if [ -d "/mnt/new/wow" ]; then
            dir_to_use="/mnt/new"
            export_dir="/mnt/new/mpq"
            mkdir -p "$export_dir"
        fi

        if [ ! -d "$HOME/Code2/Wow/tools/mpq/Export" ]; then
            #printf "You should run: cd $HOME/Code2/Wow/tools/mpq && ./gophercraft_mpq_set export --chain-json docs/wotlk-chain.json --working-directory \"%s/wow/Data\" --export-directory \"%s/Export\"\n" "$dir_to_use" "$export_dir"
            printf "You should run: cd $HOME/Code2/Wow/tools/mpq && ./mopaq export --chain-json docs/wotlk-chain.json --working-directory \"%s/wow/Data\" --export-directory \"%s/Export\"\n" "$dir_to_use" "$export_dir"
        else
            echo "$HOME/Code2/Wow/tools/mpq/Export already exists. All good!"
        fi
    else
        echo "$HOME/Code2/Wow/tools/mpq does NOT exist. Skipping."
    fi

    echo -e "\nChecking databases...\n"
    check_dbs
}

if $justDoIt; then
    echo "Fixing other files..."
    fix_other_files
else
    $justInform && echo -e "\nDo you want to check other files? (yes/y)" || echo -e "\nDo you want to fix other files? (yes/y)"
    read answer
    # To lowercase using awk
    answer=$(echo $answer | awk '{print tolower($0)}')

    if [[ "$answer" == "yes" ]] || [[ "$answer" == "y" ]]; then
        $justInform && echo "Checking other files..." || echo "Fixing other files..."
        fix_other_files
    fi
fi

