#! /usr/bin/python
import pytesseract
import pyperclip
pytesseract.pytesseract.tesseract_cmd = r'/usr/bin/tesseract'
#print(pytesseract.image_to_string(r'/home/jonas/.local/bin/my_scripts/hyprland/Pictures/ocr.png'))
pyperclip.copy(pytesseract.image_to_string(r'/home/jonas/Pictures/Screenshots/ocr.png'))
