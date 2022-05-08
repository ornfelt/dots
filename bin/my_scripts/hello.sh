#! /bin/bash

if [ -e ~/.local/bin/my_scripts/x.txt ]
then
	:
else
	neofetch
	touch ~/.local/bin/my_scripts/x.txt
fi
