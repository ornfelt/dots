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

# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/pytess.py
# maim -s selects with slop, which cancels on Escape (exits non-zero, so the
# OCR below is skipped); -u leaves the mouse cursor out of the capture
maim -s -u /home/jonas/Pictures/Screenshots/ocr.png &&python3 /home/jonas/.local/bin/my_scripts/pytess.py
#sed -i 's/^M//g'  ocr.txt
#sed -i 's/[[:space:]]*$//' ocr.txt
#sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt

