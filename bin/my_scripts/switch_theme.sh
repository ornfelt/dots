#!/usr/bin/env bash
rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
theme1="gruvbox"
theme2="catpuccin"
theme3="hybrid"

# Variable passed to rofi
options="$theme1\n$theme2\n$theme3"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $theme1)
		if [ -e ~/.Xresources_gruv ]; then
			mv ~/.Xresources ~/.Xresources_catm
			mv ~/.Xresources_gruv ~/.Xresources

			mv ~/.config/nvim/init.vim 	~/.config/nvim/init_catm.vim
			mv ~/.config/nvim/init_gruv.vim ~/.config/nvim/init.vim
			xrdb ~/.Xresources

			#mv ~/.config/hypr/wallpapers ~/.config/hypr/wallpapers_catm
			#mv ~/.config/hypr/wallpapers_gruv ~/.config/hypr/wallpapers
		fi
		
        ;;
    $theme2)
		if [ -e ~/.Xresources_catm ]; then
			mv ~/.Xresources ~/.Xresources_gruv
			mv ~/.Xresources_catm ~/.Xresources

			mv ~/.config/nvim/init.vim 	~/.config/nvim/init_gruv.vim
			mv ~/.config/nvim/init_catm.vim ~/.config/nvim/init.vim
			xrdb ~/.Xresources

			#mv ~/.config/hypr/wallpapers ~/.config/hypr/wallpapers_gruv
			#mv ~/.config/hypr/wallpapers_catm ~/.config/hypr/wallpapers
		fi
		
        ;;
    $theme3)
		echo "Not implemented"
        ;;
esac
