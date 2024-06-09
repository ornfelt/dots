#! /bin/bash
#urxvt -e bash -c "nvim $(fzf)"
case $1 in
	"st") st -e bash -c 'nvim -c "FZF ~"; zsh' ;;
	"urxvt") urxvt -e bash -c 'nvim -c "FZF ~"; zsh' ;;
	"alacritty") alacritty -e bash -c 'nvim -c "FZF ~"; zsh' ;;
esac

