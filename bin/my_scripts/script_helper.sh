#!/usr/bin/env bash

# rofi_command="rofi -theme $dir/powermenu.rasi"
rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
awkOpt="Awk"
bashOpt="Bash"
grepOpt="Grep"
perlOpt="Perl"
prgrmOpt="Prgrm"
sedOpt="Sed"
otherOpt="Other"
vimOpt="Vim"
visidataOpt="Visidata"

# Variable passed to rofi
options="$awkOpt\n$bashOpt\n$grepOpt\n$perlOpt\n$prgrmOpt\n$sedOpt\n$otherOpt\n$vimOpt\n$visidataOpt"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $awkOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/awk.txt; zsh'
        ;;
    $bashOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/bash.txt; zsh'
        ;;
    $grepOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/grep.txt; zsh'
        ;;
    $perlOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/perl.txt; zsh'
        ;;
    $prgrmOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/prgrm.txt; zsh'
        ;;
    $sedOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/sed.txt; zsh'
        ;;
    $otherOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/other.txt; zsh'
        ;;
    $vimOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/vim.txt; zsh'
        ;;
    $visidataOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/visidata.txt; zsh'
        ;;
esac
