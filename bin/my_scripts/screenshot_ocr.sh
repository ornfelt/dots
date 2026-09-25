#! /bin/bash

# Pip requirements:
# pip3 install ocrspace

# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
# maim -s selects with slop, which cancels on Escape (exits non-zero); stop
# there so the clipboard is left untouched. -u leaves the mouse cursor out
maim -s -u /home/jonas/Pictures/Screenshots/ocr.png || exit
python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
sed -i 's/^M//g'  ocr.txt
sed -i 's/[[:space:]]*$//' ocr.txt
sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt
xclip -sel c < ocr.txt

