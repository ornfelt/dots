#! /bin/bash
export TESSDATA_PREFIX=/usr/local/share/tessdata
# For debian:
# sudo apt-get install tesseract-ocr
# old (might not be needed?):
#export TESSDATA_PREFIX=/home/jonas/.local/share/tessdata
# Also change env to /usr/bin/bash and might need: /usr/bin/python3

# Pip requirements:
# pip3 install pytesseract
# pip3 install pyperclip

import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/pytess.py
#sed -i 's/^M//g'  ocr.txt
#sed -i 's/[[:space:]]*$//' ocr.txt
#sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt

