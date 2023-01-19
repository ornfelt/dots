#!/usr/bin/env bash

# rofi_command="rofi -theme $dir/powermenu.rasi"
rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
awkOpt="awk"
bashOpt="bash"
grepOpt="grep"
perlOpt="perl"
prgrmOpt="progrm"
sedOpt="sed"
otherOpt="other"
vimOpt="vim"
visidataOpt="visidata"

# Variable passed to rofi
options="$awkOpt\n$bashOpt\n$grepOpt\n$perlOpt\n$prgrmOpt\n$sedOpt\n$otherOpt\n$vimOpt\n$visidataOpt"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $awkOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/awk.txt; zsh'
        ;;
    $bashOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/bash.txt; zsh'
        ;;
    $grepOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/grep.txt; zsh'
        ;;
    $perlOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/perl.txt; zsh'
        ;;
    $prgrmOpt)
		#$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/prgrm.txt; zsh'
		~/.local/bin/my_scripts/progrm_helper.sh $1
        ;;
    $sedOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/sed.txt; zsh'
        ;;
    $otherOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/other.txt; zsh'
        ;;
    $vimOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/vim.txt; zsh'
        ;;
    $visidataOpt)
		$1 -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/visidata.txt; zsh'
        ;;
esac
