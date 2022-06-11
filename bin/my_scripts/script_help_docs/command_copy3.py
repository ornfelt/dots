import pyperclip
command = "awk '/^[ \t]*$/{next}{print}' file.txt"
pyperclip.copy(command)
