import pyperclip
command = "find MySourceCodeDir/ -name '*.java' -type f -print| xargs \ grep --color 'import'"
pyperclip.copy(command)
