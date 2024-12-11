#! /bin/bash

# Pip requirements:
# pip3 install ocrspace

import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
sed -i 's/^M//g'  ocr.txt
sed -i 's/[[:space:]]*$//' ocr.txt
sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt
xclip -sel c < ocr.txt

