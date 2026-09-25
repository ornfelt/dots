#! /bin/bash

# Pip requirements:
# pip3 install ocrspace

# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
# maim -s selects with slop, which cancels on Escape (exits non-zero); stop
# there so the clipboard is left untouched. -u leaves the mouse cursor out
if [ -n "$WAYLAND_DISPLAY" ]; then
    # slurp exits non-zero on Escape, same as maim -s
    region=$(slurp) || exit
    grim -g "$region" /home/jonas/Pictures/Screenshots/ocr.png || exit
else
    maim -s -u /home/jonas/Pictures/Screenshots/ocr.png || exit
fi
python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
sed -i 's/^M//g'  ocr.txt
sed -i 's/[[:space:]]*$//' ocr.txt
sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt
if [ -n "$WAYLAND_DISPLAY" ]; then
    wl-copy < ocr.txt
else
    xclip -sel c < ocr.txt
fi

