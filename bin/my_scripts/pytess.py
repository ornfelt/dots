#! /usr/bin/python
# pip install pytesseract pyperclip
import pytesseract
import pyperclip

pytesseract.pytesseract.tesseract_cmd = r'/usr/bin/tesseract'
#print(pytesseract.image_to_string(r'/home/jonas/Pictures/Screenshots/ocr.png'))
text = pytesseract.image_to_string(r'/home/jonas/Pictures/Screenshots/ocr.png')
pyperclip.copy(text)
# for tesseract_ocr.sh's notification
print(text)

