#! /bin/bash
# /usr/local/share/tessdata doesn't exist (tesseract warns and falls back to its
# own tessdata):
#export TESSDATA_PREFIX=/usr/local/share/tessdata
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
# maim -s (or slurp) selects, cancelling on Escape: shot_grab exits, so the
# OCR below is skipped
. ~/.local/bin/my_scripts/screenshot_lib.sh
shot_need tesseract:tesseract-ocr
shot_need_py pytesseract pyperclip
shot_grab /home/jonas/Pictures/Screenshots/ocr.png
# pytess.py copies the text and prints it; pyperclip picks wl-copy by itself
# under Wayland, so pytess.py needs no branch. Not text=$(...): the xclip that
# pyperclip starts keeps serving the clipboard with python's stdout open, so
# the substitution would wait until the clipboard changes
out=$(mktemp)
trap 'rm -f "$out" "$SHOT_ERR"' EXIT
if ! python3 /home/jonas/.local/bin/my_scripts/pytess.py > "$out" 2>"$SHOT_ERR"; then
    shot_error "OCR failed" "$(shot_errmsg)"
    exit 1
fi
text=$(cat "$out")
# tesseract prints a form feed when it finds nothing
if [ -z "$(printf '%s' "$text" | tr -d '[:space:]')" ]; then
    shot_notify "OCR: no text found"
else
    shot_notify "OCR text copied to clipboard" "$(shot_esc "$(printf '%s\n' "$text" | head -n 8)")"
fi
#sed -i 's/^M//g'  ocr.txt
#sed -i 's/[[:space:]]*$//' ocr.txt
#sed -i 's/\n//' ocr.txt
#sed -i '/^[[:space:]]*$/d' ocr.txt

