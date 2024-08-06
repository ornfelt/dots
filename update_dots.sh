#! /bin/sh

arg=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if [ $# -eq 0 ]; then
#if [ -z "$arg" ]; then
    echo "No arguments provided."
    cd $HOME/Documents/installation && ./update.sh && cd - > /dev/null
    rm -rf installation
    cp -r $HOME/Documents/installation installation/
else
    if echo "$arg" | grep -q "no-pkg"; then
        echo "Skipping update due to 'no-pkg' argument."
    else
        echo "Unknown argument provided"
    fi
fi

rm -rf .config/alacritty
rm -rf .config/awesome
rm -rf .config/cava
rm -rf .config/conky
rm -rf .config/dmenu
rm -rf .config/dmenu_git
rm -rf .config/dwm
rm -rf .config/dwm_git
rm -rf .config/dwmblocks
rm -rf .config/dwm_mul_mon
rm -rf .config/eww
rm -rf .config/hypr
rm -rf .config/i3
rm -rf .config/kitty
rm -rf .config/lf
rm -rf .config/neofetch
rm -rf .config/nvim
rm -rf .config/picom
rm -rf .config/polybar
rm -rf .config/ranger
rm -rf .config/rofi
rm -rf .config/st
rm -rf .config/st_git
rm -rf .config/zathura

rm -rf .dwm
rm -rf bin

rm .bashrc
rm .tmux.conf
rm .xinitrc
rm .Xresources
rm .Xresources_cat
rm .zshrc

printf "Removed files...\n"
sleep 0.5

cp -r $HOME/.config/awesome .config/awesome/
cp -r $HOME/.config/alacritty .config/alacritty/
cp -r $HOME/.config/cava .config/cava/
cp -r $HOME/.config/conky .config/conky/
cp -r $HOME/.config/dmenu .config/dmenu/
cp -r $HOME/.config/dmenu_git .config/dmenu_git/
cp -r $HOME/.config/dwm .config/dwm/
cp -r $HOME/.config/dwm_git .config/dwm_git/
cp -r $HOME/.config/dwmblocks .config/dwmblocks/
cp -r $HOME/.config/dwm_mul_mon .config/dwm_mul_mon/
cp -r $HOME/.config/eww .config/eww/
cp -r $HOME/.config/hypr .config/hypr/
cp -r $HOME/.config/i3 .config/i3/
cp -r $HOME/.config/kitty .config/kitty/
cp -r $HOME/.config/lf .config/lf/
cp -r $HOME/.config/neofetch .config/neofetch/
cp -r $HOME/.config/nvim .config/nvim/
cp -r $HOME/.config/picom .config/picom/
cp -r $HOME/.config/polybar .config/polybar/
cp -r $HOME/.config/ranger .config/ranger/
cp -r $HOME/.config/rofi .config/rofi/
cp -r $HOME/.config/st .config/st/
cp -r $HOME/.config/st_git .config/st_git/
cp -r $HOME/.config/zathura .config/zathura/
cp $HOME/.config/mimeapps.list .config/

cp -r $HOME/.dwm .dwm/
mkdir -p bin
cp -r $HOME/.local/bin/cron bin/
cp -r $HOME/.local/bin/dwm_keybinds bin/
cp -r $HOME/.local/bin/i3-used-keybinds bin/
cp -r $HOME/.local/bin/my_scripts bin/
cp -r $HOME/.local/bin/statusbar bin/
cp -r $HOME/.local/bin/vim bin/
cp -r $HOME/.local/bin/widgets bin/
cp -r $HOME/.local/bin/xyz bin/
cp -r $HOME/.local/bin/lfub bin/
cp -r $HOME/.local/bin/lf-select bin/
cp -r $HOME/.local/bin/greenclip bin/

cp -r $HOME/.bashrc .bashrc
cp -r $HOME/.tmux.conf .tmux.conf
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

# Update alacritty, preserving custom font size (if any)
DEFAULT_FONT_SIZE="7.0"

update_font_size() {
  local file=$1
  local new_size=$2
  [[ $file == *.toml ]] && sed -i "s/size = .*/size = $new_size/" "$file" || sed -i "s/size: .*/size: $new_size/" "$file"
}

if ! grep -q "size: $DEFAULT_FONT_SIZE" "$HOME/.config/alacritty/alacritty.yml"; then
  echo "Reverting font size in alacritty.yml to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.yml" "$DEFAULT_FONT_SIZE"
fi

if ! grep -q "size = $DEFAULT_FONT_SIZE" "$HOME/.config/alacritty/alacritty.toml"; then
  echo "Reverting font size in alacritty.toml to default size $DEFAULT_FONT_SIZE."
  update_font_size ".config/alacritty/alacritty.toml" "$DEFAULT_FONT_SIZE"
fi

printf "\nCopied latest files...\n"

#git add -A
#git commit -m $1
#git push https://"{$2}"@github.com/archornf/dotfiles.git
#git push https://$GITHUB_TOKEN@github.com/archornf/dotfiles.git

