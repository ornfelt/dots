#!/usr/bin/env bash
case $1 in
	"1") urxvt -e bash -c 'nvim ~/Documents/first_notes.txt;' ;;
	"2") urxvt -e bash -c 'nvim ~/Documents/help.txt;' ;;
esac

