#!/usr/bin/env bash

# rofi_command="rofi -theme $dir/powermenu.rasi"
rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
compOpt="complexities"
dpOpt="design patterns"
dsOpt="data structures"
genOpt="general"

# Variable passed to rofi
options="$compOpt\n$dpOpt\n$dsOpt\n$genOpt"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $compOpt)
		$1 -e bash -c 'nvim ~/Documents/progrm_help_docs/complexities.txt; zsh'
        ;;
    $dpOpt)
		$1 -e bash -c 'nvim ~/Documents/progrm_help_docs/dp.txt; zsh'
        ;;
    $dsOpt)
		$1 -e bash -c 'nvim ~/Documents/progrm_help_docs/ds.txt; zsh'
        ;;
    $genOpt)
		$1 -e bash -c 'nvim ~/Documents/progrm_help_docs/general.txt; zsh'
        ;;
esac
