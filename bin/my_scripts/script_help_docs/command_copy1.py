import pyperclip
command = "python3 -c  'import csv,json,sys;print(json.dumps(list(csv.reader(open(sys.argv[1])))))' file.csv"
pyperclip.copy(command)
