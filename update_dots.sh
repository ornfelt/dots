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
# color the entire line
log_ok()    { printf "%b[ok] %b%b\n"   "$CYAN"    "$*" "$RESET"; }
log_warn()  { printf "%b[warn] %b%b\n" "$YELLOW"  "$*" "$RESET"; }
log_err()   { printf "%b[err] %b%b\n"  "$RED"     "$*" "$RESET"; }
log_info()  { printf "%b[i] %b%b\n"    "$DARKGRAY" "$*" "$RESET"; }
log_step()  { printf "\n%b==> %b%b\n"  "$BLUE"    "$*" "$RESET"; }
log_q()     { printf "\n%b[q] %b%b\n"  "$MAGENTA" "$*" "$RESET"; }

log_sep()   { log_info "--------------------------------------------------------"; }

say()       { printf "%b\n" "$*"; }
die()       { log_err "$*"; exit 1; }

# Everything below rm -rf's relative paths, so it must run inside the dotfiles repo
# (from ~ it would delete the real ~/.config/nvim, ~/.bashrc, ...)
cd "$(dirname "$(readlink -f "$0")")" || die "Failed to cd to the script dir"
if [ ! -d .git ] || [ ! -f setup.sh ]; then
    die "$PWD doesn't look like the dotfiles repo (no .git or setup.sh). Exiting."
fi

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

    # Subshell so a failing update.sh can't leave us in $INSTALL_DOCS_DIR for the rm -rf's below
    (cd "$INSTALL_DOCS_DIR" && ./update.sh) || die "$INSTALL_SCRIPT failed. Exiting."
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

# Replace the repo copy only when the source exists, so a config that is missing on
# this machine isn't deleted from the repo (and then from the next commit)
sync_dir() {
    local src=$1
    local dest=$2
    if [ -d "$src" ]; then
        rm -rf "$dest"
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
    else
        log_warn "$src does not exist. Keeping repo copy of $dest."
    fi
}

sync_file() {
    local src=$1
    local dest=$2
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
    else
        log_warn "$src does not exist. Keeping repo copy of $dest."
    fi
}

config_dirs=(
    alacritty awesome somewm cava conky dmenu dunst dwm dwmblocks dwmr dwmblocksr
    dwmc dwmblocksc eww hypr i3 kitty lf neofetch nvim picom pip polybar ranger
    wezterm zsh rofi st zathura
)
for dir in "${config_dirs[@]}"; do
    sync_dir "$HOME/.config/$dir" ".config/$dir"
done

if [[ -d "$HOME/.config/yazi/plugins" ]]; then
    sync_dir "$HOME/.config/yazi" ".config/yazi"
else
    log_warn "Directory $HOME/.config/yazi/plugins does not exist. Skipping copy."
fi

sync_file "$HOME/.config/mimeapps.list" ".config/mimeapps.list"
sync_file "$HOME/.config/gtk-3.0/bookmarks" ".config/gtk-3.0/bookmarks"
sync_file "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml" \
    ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml"

sync_dir "$HOME/.dwm" ".dwm"

for dir in cron dwm_keybinds i3-used-keybinds my_scripts statusbar widgets xyz; do
    sync_dir "$HOME/.local/bin/$dir" "bin/$dir"
done
for file in lfub lf-select greenclip; do
    sync_file "$HOME/.local/bin/$file" "bin/$file"
done

for file in .bashrc .tmux.conf .wezterm.lua .xinitrc .Xresources .Xresources_cat .zshrc .zshenv; do
    sync_file "$HOME/$file" "$file"
done

# Copy selected Claude configuration
sync_file "$HOME/.claude/settings.json" ".claude/settings.json"
sync_dir "$HOME/.claude/hooks" ".claude/hooks"

log_ok "Synced files..."

rm -f .config/dmenu/dmenu
rm -f .config/dmenu/stest
rm -f .config/dwm/dwm
rm -f .config/dwmblocks/dwmblocks
rm -f .config/st/st
rm -f installation/packages/log.txt

rm -f .config/dmenu/*.o
rm -f .config/dwm/*.o
rm -f .config/dwmblocks/*.o
rm -f .config/st/*.o

rm -rf .config/dwmblocks/build

# Remove nested .git dirs (dmenu, dwm, st, awesome, any cloned plugin, ...) so they
# aren't committed as broken embedded repos; the repo's own ./.git is skipped
find . -path ./.git -prune -o -name .git -prune -print | while IFS= read -r dir; do
    log_info "Removing $dir"
    rm -rf "$dir"
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

if [ -f "$HOME/.config/alacritty/alacritty.yml" ] && [ -f ".config/alacritty/alacritty.yml" ] &&
   ! grep -q "size: $DEFAULT_FONT_SIZE" "$HOME/.config/alacritty/alacritty.yml"; then
  log_info "Reverting font size in alacritty.yml to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.yml" "$DEFAULT_FONT_SIZE"
fi

if [ -f "$HOME/.config/alacritty/alacritty.toml" ] && [ -f ".config/alacritty/alacritty.toml" ] &&
   ! grep -q "size = $DEFAULT_FONT_SIZE" "$HOME/.config/alacritty/alacritty.toml"; then
  log_info "Reverting font size in alacritty.toml to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.toml" "$DEFAULT_FONT_SIZE"
fi

# bash_profile
keys=(
  "ALPHAVANTAGE_API_KEY"
  "GITHUB_TOKEN"
  "ALT_GITHUB_TOKEN"
  "OPENAI_API_KEY"
  "OPENAI_ADMIN_API_KEY"
  "GOOGLE_API_KEY"
  "GOOGLE_ADMIN_API_KEY"
  "ANTHROPIC_API_KEY"
  "ANTHROPIC_ADMIN_API_KEY"
  "MISTRAL_API_KEY"
  "OPENWEATHERMAP_KEY"
  "SYSTEMET_KEY"
  "GOOGLE_MAPS_KEY"
  "MYSQL_ROOT_PWD"
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
  echo '# Raspberrypi'
  echo '#export MESA_GL_VERSION_OVERRIDE=3.3'
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

# The files synced from $HOME could also carry a key: KEY=value, KEY="value" or "KEY": "value".
# Put the repo version back so the value never sits in the working tree, then stop.
secret_files=(.bashrc .zshrc .zshenv .claude/settings.json)
for file in "${secret_files[@]}"; do
  [ -f "$file" ] || continue
  for key in "${keys[@]}"; do
    if grep -qE "\b$key=[\"']?[^\"'[:space:]]|\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]" "$file"; then
      log_err "$file sets $key to a value. Restoring the repo version of $file."
      git restore -- "$file" 2>/dev/null || rm -f "$file"
      die "Remove $key from \$HOME/$file (or move it to ~/.bash_profile) and rerun."
    fi
  done
done

log_ok "No keys found in synced shell/Claude config."

# Restore Claude settings if the only change is effortLevel
RESTORE_CLAUDE_EFFORT_ONLY=true

if $RESTORE_CLAUDE_EFFORT_ONLY; then
    CLAUDE_SETTINGS=".claude/settings.json"

    if ! git diff --quiet -- "$CLAUDE_SETTINGS"; then
        changed_lines=$(
            git diff --unified=0 -- "$CLAUDE_SETTINGS" |
                grep -E '^[+-]' |
                grep -vE '^(---|\+\+\+)'
        )

        if [[ -n "$changed_lines" ]] &&
           echo "$changed_lines" | grep -qv '"effortLevel"'; then
            log_info "Claude settings contains changes other than effortLevel. Keeping changes."
        else
            log_info "Only Claude effortLevel changed. Restoring $CLAUDE_SETTINGS."
            git restore -- "$CLAUDE_SETTINGS"
        fi
    fi
fi

log_ok "Copied latest files..."

#git add -A
#git commit -m $1
#git push https://"{$2}"@github.com/archornf/dotfiles.git
#git push https://$GITHUB_TOKEN@github.com/archornf/dotfiles.git

