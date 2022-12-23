import sys
import pyperclip

#print('Number of arguments:', len(sys.argv), 'arguments.')
#print(str(sys.argv[1]))

chosen_command = int(sys.argv[1])

if chosen_command == 100:
    chosen_command = 19

if chosen_command == 101:
    pyperclip.copy('for i in */.git; do cd $(dirname $i); git pull; cd ..; done')
elif chosen_command == 102:
    pyperclip.copy('for code in {0..255}; do echo -e "\e[38;05;${code}m $code: Test"; done')
elif chosen_command == 103:
    pyperclip.copy('cat ~/.bash_history | tr "\|\;" "\n" | sed -e "s/^ //g" | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 10')
elif chosen_command == 104:
    pyperclip.copy('python3 -c "import csv,json,sys;print(json.dumps(list(csv.reader(open(sys.argv[1])))))" test.csv')

else:
    #with open('raw_oneliners.txt') as f:
    with open('/home/jonas/.local/bin/my_scripts/script_help_docs/oneliners.txt') as f:
        #lines = f.readlines()
        lines = [line.rstrip('\n') for line in f]
        
    for i in range (len(lines)):
        if i == chosen_command:
            #print(lines[i])
            pyperclip.copy(lines[i])
