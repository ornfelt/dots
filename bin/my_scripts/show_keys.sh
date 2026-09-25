#!/usr/bin/env bash
case $1 in
	"dwm") $2 -e bash -c 'nvim ~/.local/bin/dwm_keybinds/keys;' ;;
	"i3") $2 -e bash -c 'nvim ~/.local/bin/i3-used-keybinds/keys;' ;;
	"vim") $2 -e bash -c 'nvim ~/.local/bin/vim/keys;' ;;
	"hyprland") $2 -e bash -c 'nvim ~/.config/hypr/hyprland.conf;' ;;
esac

