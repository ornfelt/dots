#!/bin/bash

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

options=(
    "This is a very long string for testing dmenu with a lot of characters to see how it handles overflow or long input"
    "Another example of a string that exceeds typical width for menu items and includes special characters !@#$%^&*()"
    "Short"
    "Medium length string for testing"
    "This string has newlines\nand other edge cases"
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua oaskdoaskdoasdkasodkasodkasdoaksdoadkasdjoasjdoasdjosadasjidjasodjasodajsdoasjdoasjdaosdjaosdoasdoajsdoajsdoajdjjjs"
    "Long string with spaces                     and tabs		for testing alignment and formatting"
    "Short"
    "Short"
    "Short"
    "Short"
    "Short"
    "Short"
    "Short"
    "Short"
    "Short"
)

input=$(printf "%s\n" "${options[@]}")

selected=$(echo "$input" | menu "Test" 20)

if [ -n "$selected" ]; then
    echo "You selected: $selected"
else
    echo "No option selected."
fi

