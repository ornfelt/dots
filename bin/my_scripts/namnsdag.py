#! /usr/bin/python3
from bs4 import BeautifulSoup
import requests

url = 'https://www.dagensnamn.nu/'
try:
    resp = requests.get(url)
    html = resp.text
    soup = BeautifulSoup(html, "html.parser")
    #print("Namnsdag idag: " + soup.find("div", {"class": "text-vertical-center"}).get_text().split("har")[1].split("...")[0])
    name_info = soup.find("div", {"class": "text-vertical-center"}).get_text().split("har")[1].split("...")[0]
    if "ingen namnsdag" in name_info:
        pass
    else:
        print("Namnsdag idag:", name_info)
except:
    pass
