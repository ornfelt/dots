#! /bin/bash

#set -euo pipefail

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
#log_ok()    { printf "%b[ok]%b %b\n"   "$CYAN"   "$RESET" "$*"; }
#log_warn()  { printf "%b[warn]%b %b\n" "$YELLOW" "$RESET" "$*"; }
#log_err()   { printf "%b[err]%b %b\n"  "$RED"    "$RESET" "$*"; }
#log_info()  { printf "%b[i]%b %b\n"    "$DARKGRAY" "$RESET" "$*"; }
#log_step()  { printf "\n%b==>%b %b\n"  "$BLUE"   "$RESET" "$*"; }
#log_sep()   { log_info "--------------------------------------------------------"; }
# color the entire line
log_ok()    { printf "%b[ok] %b%b\n"   "$CYAN"    "$*" "$RESET"; }
log_warn()  { printf "%b[warn] %b%b\n" "$YELLOW"  "$*" "$RESET"; }
log_err()   { printf "%b[err] %b%b\n"  "$RED"     "$*" "$RESET"; }
log_info()  { printf "%b[i] %b%b\n"    "$DARKGRAY" "$*" "$RESET"; }
log_step()  { printf "\n%b==> %b%b\n"  "$BLUE"    "$*" "$RESET"; }
log_q()     { printf "\n%b[q] %b%b\n"  "$MAGENTA" "$*" "$RESET"; }

say()       { printf "%b\n" "$*"; }
die()       { log_err "$*"; exit 1; }

arg=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if [ $# -eq 0 ]; then
#if [ -z "$arg" ]; then
    log_step "No arguments provided. Updating installation docs..."
    INSTALL_DOCS_DIR="$HOME/Documents/installation"
    INSTALL_SCRIPT="$INSTALL_DOCS_DIR/update.sh"

    if [ ! -d "$INSTALL_DOCS_DIR" ]; then
        die "Directory $INSTALL_DOCS_DIR does not exist... Exiting."
    fi

    if [ ! -f "$INSTALL_SCRIPT" ]; then
        die "Script $INSTALL_SCRIPT does not exist... Exiting."
    fi

    cd "$INSTALL_DOCS_DIR" && ./update.sh && cd - > /dev/null
    rm -rf installation
    cp -r $HOME/Documents/installation installation/
    log_ok "Updated installation docs."
else
    if echo "$arg" | grep -q "no-pkg"; then
        log_info "Skipping update due to 'no-pkg' argument."
    else
        log_warn "Unknown argument provided: $1"
    fi
fi

rm -rf .config/alacritty
rm -rf .config/awesome
rm -rf .config/cava
rm -rf .config/conky
rm -rf .config/dmenu
rm -rf .config/dwm
rm -rf .config/dwmblocks
rm -rf .config/eww
rm -rf .config/hypr
rm -rf .config/i3
rm -rf .config/kitty
rm -rf .config/lf
rm -rf .config/neofetch
rm -rf .config/nvim
rm -rf .config/picom
rm -rf .config/pip
rm -rf .config/polybar
rm -rf .config/ranger
rm -rf .config/zsh

if [[ -d "$HOME/.config/yazi/plugins" ]]; then
    rm -rf .config/yazi
else
    log_warn "Directory $HOME/.config/yazi/plugins does not exist. Skipping copy."
fi

rm -rf .config/rofi
rm -rf .config/st
rm -rf .config/zathura
rm -rf .dwm
rm -rf bin
rm .bashrc
rm .tmux.conf
rm .wezterm.lua
rm .xinitrc
rm .Xresources
rm .Xresources_cat
rm .zshrc

log_ok "Removed files..."
sleep 0.5

cp -r $HOME/.config/awesome .config/awesome/
cp -r $HOME/.config/alacritty .config/alacritty/
cp -r $HOME/.config/cava .config/cava/
cp -r $HOME/.config/conky .config/conky/
cp -r $HOME/.config/dmenu .config/dmenu/
cp -r $HOME/.config/dwm .config/dwm/
cp -r $HOME/.config/dwmblocks .config/dwmblocks/
cp -r $HOME/.config/eww .config/eww/
cp -r $HOME/.config/hypr .config/hypr/
cp -r $HOME/.config/i3 .config/i3/
cp -r $HOME/.config/kitty .config/kitty/
cp -r $HOME/.config/lf .config/lf/
cp -r $HOME/.config/neofetch .config/neofetch/
cp -r $HOME/.config/nvim .config/nvim/
cp -r $HOME/.config/picom .config/picom/
cp -r $HOME/.config/pip .config/pip/
cp -r $HOME/.config/polybar .config/polybar/
cp -r $HOME/.config/ranger .config/ranger/
cp -r $HOME/.config/zsh .config/zsh/

if [[ -d "$HOME/.config/yazi/plugins" ]]; then
    cp -r $HOME/.config/yazi .config/yazi/
else
    log_warn "Directory $HOME/.config/yazi/plugins does not exist. Skipping copy."
fi

cp -r $HOME/.config/rofi .config/rofi/
cp -r $HOME/.config/st .config/st/
cp -r $HOME/.config/zathura .config/zathura/
cp $HOME/.config/mimeapps.list .config/
cp $HOME/.config/gtk-3.0/bookmarks .config/gtk-3.0/

cp -r $HOME/.dwm .dwm/
mkdir -p bin
cp -r $HOME/.local/bin/cron bin/
cp -r $HOME/.local/bin/dwm_keybinds bin/
cp -r $HOME/.local/bin/i3-used-keybinds bin/
cp -r $HOME/.local/bin/my_scripts bin/
cp -r $HOME/.local/bin/statusbar bin/
cp -r $HOME/.local/bin/widgets bin/
cp -r $HOME/.local/bin/xyz bin/
cp -r $HOME/.local/bin/lfub bin/
cp -r $HOME/.local/bin/lf-select bin/
cp -r $HOME/.local/bin/greenclip bin/

cp -r $HOME/.bashrc .bashrc
cp -r $HOME/.tmux.conf .tmux.conf
cp -r $HOME/.wezterm.lua .wezterm.lua
cp -r $HOME/.xinitrc .xinitrc
cp -r $HOME/.Xresources .Xresources
cp -r $HOME/.Xresources_cat .Xresources_cat
cp -r $HOME/.zshrc .zshrc

rm --f .config/dmenu/dmenu
rm --f .config/dmenu/stest
rm --f .config/dwm/dwm
rm --f .config/dwmblocks/dwmblocks
rm --f .config/st/st
rm --f installation/packages/log.txt

rm --f .config/dmenu/*.o
rm --f .config/dwm/*.o
rm --f .config/dwmblocks/*.o
rm --f .config/st/*.o

sudo rm -r --f .config/dwmblocks/build
sudo rm -r --f .config/awesome/.git

# Remove .git dirs from dmenu, dwm and st
dirs=(
    ".config/dmenu/.git"
    ".config/dwm/.git"
    ".config/dwmblocks/.git"
    ".config/st/.git"
)

for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        log_info "Removing $dir"
        rm -rf "$dir"
    else
        log_info "$dir does not exist, skipping."
    fi
done

# Update alacritty, preserving custom font size (if any)
DEFAULT_FONT_SIZE="7.0"

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

if ! grep -q "size: $DEFAULT_FONT_SIZE" "$HOME/.config/alacritty/alacritty.yml"; then
  log_info "Reverting font size in alacritty.yml to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.yml" "$DEFAULT_FONT_SIZE"
fi

if ! grep -q "size = $DEFAULT_FONT_SIZE" "$HOME/.config/alacritty/alacritty.toml"; then
  log_info "Reverting font size in alacritty.toml to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.toml" "$DEFAULT_FONT_SIZE"
fi

# bash_profile
keys=(
  "GITHUB_TOKEN"
  "ALT_GITHUB_TOKEN"
  "OPENAI_API_KEY"
  "GOOGLE_API_KEY"
  "MISTRAL_API_KEY"
  "OPENWEATHERMAP_KEY"
  "SYSTEMET_KEY"
  "GOOGLE_MAPS_KEY"
  "MYSQL_ROOT_PWD"
  "ALPHAVANTAGE_API_KEY"
  "HF_TOKEN"
)

# Overwrite content of ./bash_profile (shouldn't be copied)
{
  echo "#"
  echo "# ~/.bash_profile"
  echo "#"
  for key in "${keys[@]}"; do
    echo "export $key=\"\""
  done

  echo ''
  echo '[[ -f ~/.bashrc ]] && . ~/.bashrc'
  echo ''
  echo '#. "$HOME/.cargo/env"'
} > ./.bash_profile

# Double check that all keys don't have any values (they should be empty "")
for key in "${keys[@]}"; do
  if grep -qE "export $key=\"[^\"]+\"" ./.bash_profile; then
    log_err "Key $key contains a value. Deleting ./bash_profile."
    rm -f ./.bash_profile
    exit 1 # exit with error
  fi
done

log_ok "All keys are empty. ./bash_profile is intact."

log_ok "Copied latest files..."

#git add -A
#git commit -m $1
#git push https://"{$2}"@github.com/archornf/dotfiles.git
#git push https://$GITHUB_TOKEN@github.com/archornf/dotfiles.git

