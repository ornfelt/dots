#!/usr/bin/env bash
# Script for updating dotfiles

update_one() {
    rm -rf "/home/jonas/Downloads/dotfiles_2/bin"
    cp -r /home/jonas/.local/bin /home/jonas/Downloads/dotfiles_2/bin
}

#update_two() {
#
#
#}
#
#update_three() {
#}

case $1 in
    "1") update_one ;;
	#"2") update_two ;;
	#"3") update_three ;;
esac
