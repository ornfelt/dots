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
sixthOpt="${textSplit[5]}"
seventhOpt="${textSplit[6]}"
eighthOpt="${textSplit[7]}"
ninthOpt="${textSplit[8]}"
tenthOpt="${textSplit[9]}"
eleventhOpt="${textSplit[10]}"
twelfthOpt="${textSplit[11]}"
thirteenthOpt="${textSplit[12]}"
fourteenthOpt="${textSplit[13]}"
fifteenthOpt="${textSplit[14]}"
sixteenthOpt="${textSplit[15]}"
seventeenthOpt="${textSplit[16]}"
eighteenthOpt="${textSplit[17]}"
nineteenthOpt="${textSplit[18]}"
twentiethOpt="${textSplit[19]}"
twentyfirstOpt="${textSplit[20]}"
#otherOpt=$(echo $fileText | sed -n '1p')
#otherOpt=$(echo $fileText | awk 'NR==1')

# Variable passed to rofi
options="$firstOpt\n$secondOpt\n$thirdOpt\n$fourthOpt\n$fifthOpt\n$sixthOpt\n$seventhOpt\n$eighthOpt\n$ninthOpt\n$tenthOpt\n$eleventhOpt\n$twelfthOpt\n$thirteenthOpt\n$fourteenthOpt\n$fifteenthOpt\n$sixteenthOpt\n$seventhOpt\n$eighteenthOpt\n$nineteenthOpt\n$twentiethOpt\n$twentyfirstOpt"

chosen="$(echo -e "$options" | rofi -theme "/home/jonas/.config/rofi/themes/gruvbox/gruvbox-dark2.rasi" -p "Choose a command to copy" -dmenu -selected-row 0)"

case $chosen in
    $firstOpt)
		echo "$firstOpt" | xclip -sel clip
        ;;
    $secondOpt)
		echo "$secondOpt" | xclip -sel clip
        ;;
    $thirdOpt)
		echo "$thirdOpt" | xclip -sel clip
        ;;
    $fourthOpt)
		echo "$fourthOpt" | xclip -sel clip
        ;;
    $fifthOpt)
		echo "$fifthOpt" | xclip -sel clip
        ;;
    $sixthOpt)
		echo "$sixthOpt" | xclip -sel clip
        ;;
    $seventhOpt)
		echo "$seventhOpt" | xclip -sel clip
        ;;
    $eighthOpt)
		echo "$eighthOpt" | xclip -sel clip
        ;;
    $ninthOpt)
		echo "$ninthOpt" | xclip -sel clip
        ;;
    $tenthOpt)
		echo "$tenthOpt" | xclip -sel clip
        ;;
    $eleventhOpt)
		echo "$eleventhOpt" | xclip -sel clip
        ;;
    $twelfthOpt)
		echo "$twelfthOpt" | xclip -sel clip
        ;;
    $thirteenthOpt)
		echo "$thirteenthOpt" | xclip -sel clip
        ;;
    $fourteenthOpt)
		echo "$fourteenthOpt" | xclip -sel clip
        ;;
    $fifteenthOpt)
		echo "$fifteenthOpt" | xclip -sel clip
        ;;
    $sixteenthOpt)
		echo "$sixteenthOpt" | xclip -sel clip
        ;;
    $seventeenthOpt)
		echo "$seventeenthOpt" | xclip -sel clip
        ;;
    $eighteenthOpt)
		echo "$eighteenthOpt" | xclip -sel clip
        ;;
    $nineteenthOpt)
		echo "$nineteenthOpt" | xclip -sel clip
        ;;
    $twentiethOpt)
		echo "$twentiethOpt" | xclip -sel clip
        ;;
    $twentyfirstOpt)
		echo "$twentyfirstOpt" | xclip -sel clip
        ;;
esac
