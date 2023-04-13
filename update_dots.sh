#! /bin/sh

rm -rf .config/awesome
rm -rf .config/cava
rm -rf .config/conky
rm -rf .config/dmenu
rm -rf .config/dwm
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
rm -rf .config/zathura

rm -rf .dwm
rm -rf bin
rm -rf installation

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
cp -r ~/.config/dwm .config/dwm/
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
cp -r ~/.config/zathura .config/zathura/

cp -r ~/.dwm .dwm/
cp -r ~/.local/bin bin/
cp -r ~/Documents/installation installation/

cp -r ~/.bashrc .bashrc
cp -r ~/.tmux.conf .tmux.conf
cp -r ~/.xinitrc .xinitrc
cp -r ~/.Xresources .Xresources
cp -r ~/.Xresources_cat .Xresources_cat
cp -r ~/.zshrc .zshrc

printf "Copied latest files...\n"

#git add -A
#git commit -m $1
#git push ...
#git push https://"{$2}"@github.com/archornf/dotfiles.git

