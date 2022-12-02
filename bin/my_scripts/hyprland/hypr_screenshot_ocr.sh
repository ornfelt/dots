#! /usr/bin/bash
#import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
grim -g "$(slurp)" ~/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/hyprland/hypr_print_ocr.py > ocr.txt
sed -i 's/^M//g'  ocr.txt
sed -i 's/[[:space:]]*$//' ocr.txt
sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt
#xclip -sel c < ocr.txt
cat ocr.txt | wl-copy
