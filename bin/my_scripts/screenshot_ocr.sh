#! /bin/bash

# Pip requirements:
# pip3 install ocrspace

# Old: ImageMagick's import grabs only the pointer, so Escape can't cancel it:
#import /home/jonas/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt
# maim -s (or slurp) selects, cancelling on Escape: shot_grab exits, so the
# clipboard is left untouched
. ~/.local/bin/my_scripts/screenshot_lib.sh
shot_need_py ocrspace requests
if [ -n "$WAYLAND_DISPLAY" ]; then
    shot_need wl-copy:wl-clipboard
else
    shot_need xclip
fi
shot_grab /home/jonas/Pictures/Screenshots/ocr.png
if ! python3 /home/jonas/.local/bin/my_scripts/print_ocr.py > ocr.txt 2>"$SHOT_ERR"; then
    shot_error "OCR (ocr.space) failed" "$(shot_errmsg)"
    exit 1
fi
sed -i 's/^M//g'  ocr.txt
sed -i 's/[[:space:]]*$//' ocr.txt
sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt
if [ -n "$WAYLAND_DISPLAY" ]; then
    wl-copy < ocr.txt 2>"$SHOT_ERR"
else
    xclip -sel c < ocr.txt 2>"$SHOT_ERR"
fi || { shot_error "OCR: copy to clipboard failed" "$(shot_errmsg)"; exit 1; }
if [ -z "$(tr -d '[:space:]' < ocr.txt)" ]; then
    shot_notify "OCR (ocr.space): no text found"
else
    shot_notify "OCR (ocr.space) text copied to clipboard" "$(shot_esc "$(head -n 8 ocr.txt)")"
fi
