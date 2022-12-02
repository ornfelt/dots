#! /usr/bin/bash
export TESSDATA_PREFIX=/usr/local/share/tessdata
grim -g "$(slurp)" ~/Pictures/Screenshots/ocr.png && python3 /home/jonas/.local/bin/my_scripts/hyprland/hypr_pytess.py
