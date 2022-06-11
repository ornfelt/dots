#! /bin/bash

if [ -e ~/.local/bin/my_scripts/x.txt ]
then
	:
else
	pgrep -x dwm > /dev/null && neofetch
	pgrep -x i3 > /dev/null && neofetch
	# neofetch
	touch ~/.local/bin/my_scripts/x.txt
fi
