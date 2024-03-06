#! /bin/sh

arg=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if [ $# -eq 0 ]; then
#if [ -z "$arg" ]; then
    echo "No arguments provided."
    cd ~/Documents/installation && ./update.sh && cd - > /dev/null
    rm -rf installation
    cp -r ~/Documents/installation installation/
    cp ~/Documents/help.txt installation/
else
    if echo "$arg" | grep -q "no-pkg"; then
        echo "Skipping update due to 'no-pkg' argument."
    else
        echo "Unknown argument provided"
    fi
fi

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

cp -r ~/.config/awesome .config/awesome/
cp -r ~/.config/cava .config/cava/
cp -r ~/.config/conky .config/conky/
cp -r ~/.config/dmenu .config/dmenu/
cp -r ~/.config/dmenu_git .config/dmenu_git/
cp -r ~/.config/dwm .config/dwm/
cp -r ~/.config/dwm_git .config/dwm_git/
cp -r ~/.config/dwmblocks .config/dwmblocks/
cp -r ~/.config/dwm_mul_mon .config/dwm_mul_mon/
cp -r ~/.config/eww .config/eww/
cp -r ~/.config/hypr .config/hypr/
cp -r ~/.config/i3 .config/i3/
cp -r ~/.config/kitty .config/kitty/
cp -r ~/.config/lf .config/lf/
cp -r ~/.config/neofetch .config/neofetch/
cp -r ~/.config/nvim .config/nvim/
cp -r ~/.config/picom .config/picom/
cp -r ~/.config/polybar .config/polybar/
cp -r ~/.config/ranger .config/ranger/
cp -r ~/.config/rofi .config/rofi/
cp -r ~/.config/st .config/st/
cp -r ~/.config/st_git .config/st_git/
cp -r ~/.config/zathura .config/zathura/

cp -r ~/.dwm .dwm/
mkdir -p bin
cp -r ~/.local/bin/cron bin/
cp -r ~/.local/bin/dwm_keybinds bin/
cp -r ~/.local/bin/i3-used-keybinds bin/
cp -r ~/.local/bin/my_scripts bin/
cp -r ~/.local/bin/statusbar bin/
cp -r ~/.local/bin/vim bin/
cp -r ~/.local/bin/widgets bin/
cp -r ~/.local/bin/xyz bin/
cp -r ~/.local/bin/lfub bin/
cp -r ~/.local/bin/lf-select bin/

cp -r ~/.bashrc .bashrc
cp -r ~/.tmux.conf .tmux.conf
cp -r ~/.xinitrc .xinitrc
cp -r ~/.Xresources .Xresources
cp -r ~/.Xresources_cat .Xresources_cat
cp -r ~/.zshrc .zshrc

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

printf "Copied latest files...\n"

#git add -A
#git commit -m $1
#git push https://"{$2}"@github.com/archornf/dotfiles.git
#git push https://$GITHUB_TOKEN@github.com/archornf/dotfiles.git
