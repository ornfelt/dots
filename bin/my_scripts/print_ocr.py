#! /usr/bin/python
import ocrspace
import requests

api = ocrspace.API()

TEST_FILENAME = '/home/jonas/Pictures/Screenshots/ocr.png'
# With file path
print(api.ocr_file(TEST_FILENAME))
