#!/usr/bin/env bash

# rofi_command="rofi -theme $dir/powermenu.rasi"
rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

# Options
agiOpt="agile"
aiOpt="ai"
bdOpt="bd"
compOpt="complexities"
csdOpt="csd"
dpOpt="design patterns"
dsOpt="data structures"
dtOpt="data types"
g2kOpt="good 2 know"
genOpt="general"
netOpt="network"
praOpt="practical"
priOpt="principles"
sortOpt="sorting"
urlOpt="urls"

# Variable passed to rofi
options="$agiOpt\n$aiOpt\n$bdOpt\n$compOpt\n$csdOpt\n$dpOpt\n$dsOpt\n$dtOpt\n$g2kOpt\n$genOpt\n$netOpt\n$praOpt\n$priOpt\n$sortOpt\n$urlOpt"

# Dmenu
#chosen="$(echo -e "$options" | dmenu -i -p "Choose a command" -l 10)"
# Cleaner Dmenu
#chosen="$(echo -e "$options" | dmenu -i -l 10)"
# Rofi
chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $aiOpt)
        # ; zsh keeps the terminal alive after closing document
        #$1 -e bash -c 'nvim ~/Documents/progrm_help_docs/ai.txt; zsh'
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/ai.txt'
        ;;
    $agiOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/agile.txt'
        ;;
    $bdOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/bd.txt'
        ;;
    $compOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/complexities.txt'
        ;;
    $csdOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/csd.txt'
        ;;
    $dpOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/dp.txt'
        ;;
    $dsOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/ds.txt'
        ;;
    $dtOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/dt.txt'
        ;;
    $g2kOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/g2k.txt'
        ;;
    $genOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/general.txt'
        ;;
    $netOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/network.txt'
        ;;
    $praOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/practical.txt'
        ;;
    $priOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/principles.txt'
        ;;
    $sortOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/sorting.txt'
        ;;
    $urlOpt)
        $1 -e bash -c 'nvim ~/Documents/progrm_help_docs/urls.txt'
        ;;
esac
