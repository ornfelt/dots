import sys
import pyperclip

# Define a dictionary to map incoming arguments to corresponding commands
commands = {
    "ps ajxf | awk": 'pas ajxf...',
    "for i in */.git": 'for i in */.git; do cd $(dirname $i); git pull; cd ..; done',
    "for code in {0..255}": 'for code in {0..255}; do echo -e "\e[38;05;${code}m $code: Test"; done',
    "cat ~/.bash_history | tr ...": 'cat ~/.bash_history | tr "\|\;" "\n" | sed -e "s/^ //g" | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 10',
    "python3 -c \"import csv, ...\"": 'python3 -c "import csv,json,sys;print(json.dumps(list(csv.reader(open(sys.argv[1])))))" test.csv',
    "perl -e '$|++": """perl -e '$|++; while (1) { print " ." x (rand(10) + 1), int(rand(2)) }'""",
}

# Get the chosen argument from the command line
chosen_argument = sys.argv[1]

# Check if the chosen argument has a corresponding command
chosen_command = commands.get(chosen_argument)

if chosen_command is not None:
    pyperclip.copy(chosen_command)
else:
    print(f"No command found for argument '{chosen_argument}'")
