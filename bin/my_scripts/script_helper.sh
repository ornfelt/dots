#!/usr/bin/env bash

# rofi_command="rofi -theme $dir/powermenu.rasi"
rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
awkOpt="Awk"
grepOpt="Grep"
perlOpt="Perl"
sedOpt="Sed"
otherOpt="Other"

# Variable passed to rofi
options="$awkOpt\n$grepOpt\n$perlOpt\n$sedOpt\n$otherOpt"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $awkOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/awk.txt; zsh'
        ;;
    $grepOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/grep.txt; zsh'
        ;;
    $perlOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/perl.txt; zsh'
        ;;
    $sedOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/sed.txt; zsh'
        ;;
    $otherOpt)
		urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/other.txt; zsh'
        ;;
esac
