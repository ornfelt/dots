#!/usr/bin/env bash

fileText=$(cat ~/.local/bin/my_scripts/script_help_docs/script_copy.txt)

#set -o noglob
IFS=$'\n' textSplit=($fileText)
#set +o noglob

# Options
#echo "${textSplit[0]}"
firstOpt="${textSplit[0]}"
secondOpt="${textSplit[1]}"
thirdOpt="${textSplit[2]}"
fourthOpt="${textSplit[3]}"
fifthOpt="${textSplit[4]}"
sixthOpt="${textSplit[4]}"
seventhOpt="${textSplit[4]}"
eightOpt="${textSplit[4]}"
ninthOpt="${textSplit[4]}"
tenthOpt="${textSplit[4]}"
eleventhOpt="${textSplit[4]}"
twelfthOpt="${textSplit[4]}"
thirteenthOpt="${textSplit[4]}"
fourteenthOpt="${textSplit[4]}"
fifteenthOpt="${textSplit[4]}"
sixteenthOpt="${textSplit[4]}"
seventeenthOpt="${textSplit[4]}"
eighteenthOpt="${textSplit[4]}"
nineteenthOpt="${textSplit[4]}"
twentiethOpt="${textSplit[4]}"
twentyfirstOpt="${textSplit[4]}"
#otherOpt=$(echo $fileText | sed -n '1p')
#otherOpt=$(echo $fileText | awk 'NR==1')

# Variable passed to rofi
options="$firstOpt\n$secondOpt\n$thirdOpt\n$fourthOpt\n$fifthOpt\n$sixthOpt\n$seventhOpt\n$eightOpt\n$ninthOpt\n$tenthOpt\n$eleventhOpt\n$twelfthOpt\n$thirteenthOpt\n$fourteenthOpt\n$fifteenthOpt\n$sixteenthOpt\n$seventhOpt\n$eighteenthOpt\n$nineteenthOpt\n$twentiethOpt\n$twentyfirstOpt"

chosen="$(echo -e "$options" | rofi -theme "/home/jonas/.config/rofi/themes/gruvbox/gruvbox-dark2.rasi" -p "Choose a command" -dmenu -selected-row 0)"

case $chosen in
    $firstOpt)
		#urxvt -e bash -c 'nvim ~/.local/bin/my_scripts/script_help_docs/awk.txt; zsh'
		echo "1" | xclip -sel clip
        ;;
    $secondOpt)
		echo "2" | xclip -sel clip
        ;;
    $thirdOpt)
		echo "3" | xclip -sel clip
        ;;
    $fourthOpt)
		echo "4" | xclip -sel clip
        ;;
    $fifthOpt)
		echo "5" | xclip -sel clip
        ;;
esac
