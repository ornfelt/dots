#!/bin/bash

rofi_command="rofi -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi"

case $1 in
	"old") codeDir="Code" ;;
	"new") codeDir="Code2" ;;
esac

# Options
csharpOpt="c#"
cplplOpt="c++"
cOpt="c"
goOpt="go"
javaOpt="java"
jsOpt="js"
latexOpt="latex"
luaOpt="lua"
sqlOpt="sql"
pythonOpt="python"
rOpt="r"
rustOpt="rust"

# Variable passed to rofi
options="$csharpOpt\n$cplplOpt\n$cOpt\n$goOpt\n$javaOpt\n$jsOpt\n$latexOpt\n$luaOpt\n$sqlOpt\n$pythonOpt\n$rOpt\n$rustOpt"

chosen="$(echo -e "$options" | $rofi_command -p "Choose a command" -dmenu -selected-row 0)"
case $chosen in
    $csharpOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/C#;ls --color=auto; zsh;'
        ;;
    $cplplOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/C++;ls --color=auto; zsh'
        ;;
    $cOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/C;ls --color=auto; zsh'
        ;;
    $goOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Go;ls --color=auto; zsh'
        ;;
    $javaOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Java;ls --color=auto; zsh'
        ;;
    $jsOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Javascript;ls --color=auto; zsh'
        ;;
    $latexOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Latex;ls --color=auto; zsh'
        ;;
    $luaOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Lua;ls --color=auto; zsh'
        ;;
    $sqlOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/MYSQL;ls --color=auto; zsh'
        ;;
    $pythonOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Python;ls --color=auto; zsh'
        ;;
    $rOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/R;ls --color=auto; zsh'
        ;;
    $rustOpt)
		$2 -e bash -c 'cd ~/'"$codeDir"'/Rust;ls --color=auto; zsh'
        ;;
esac
