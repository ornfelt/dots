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
twentysecondOpt="${textSplit[21]}"
twentythirdOpt="${textSplit[22]}"
twentyfourthOpt="${textSplit[23]}"
twentyfifthOpt="${textSplit[24]}"
twentysixthOpt="${textSplit[25]}"
twentyseventhOpt="${textSplit[26]}"
twentyeighthOpt="${textSplit[27]}"
twentyninthOpt="${textSplit[28]}"
#otherOpt=$(echo $fileText | sed -n '1p')
#otherOpt=$(echo $fileText | awk 'NR==1')

# Variable passed to rofi
options="$firstOpt\n$secondOpt\n$thirdOpt\n$fourthOpt\n$fifthOpt\n$sixthOpt\n$seventhOpt\n$eighthOpt\n$ninthOpt\n$tenthOpt\n$eleventhOpt\n$twelfthOpt\n$thirteenthOpt\n$fourteenthOpt\n$fifteenthOpt\n$sixteenthOpt\n$seventeenthOpt\n$eighteenthOpt\n$nineteenthOpt\n$twentiethOpt\n$twentyfirstOpt\n$twentysecondOpt\n$twentythirdOpt\n$twentyfourthOpt\n$twentyfifthOpt\n$twentysixthOpt\n$twentyseventhOpt\n$twentyeighthOpt\n$twentyninthOpt"

chosen="$(echo -e "$options" | rofi -theme "/home/jonas/.config/rofi/themes/gruvbox/gruvbox-dark2.rasi" -p "Choose a command to copy" -dmenu -selected-row 0)"

case $chosen in
    $firstOpt)
		#echo "$firstOpt" | xclip -sel clip
		echo "$firstOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $secondOpt)
		echo "$secondOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $thirdOpt)
		echo "$thirdOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $fourthOpt)
		echo "$fourthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $fifthOpt)
		echo "$fifthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $sixthOpt)
		echo "$sixthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $seventhOpt)
		echo "$seventhOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $eighthOpt)
		echo "$eighthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $ninthOpt)
		echo "$ninthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $tenthOpt)
		echo "$tenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $eleventhOpt)
		echo "$eleventhOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twelfthOpt)
		echo "$twelfthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $thirteenthOpt)
		echo "$thirteenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $fourteenthOpt)
		echo "$fourteenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $fifteenthOpt)
		echo "$fifteenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $sixteenthOpt)
		echo "$sixteenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $seventeenthOpt)
		echo "$seventeenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $eighteenthOpt)
		echo "$eighteenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $nineteenthOpt)
		echo "$nineteenthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentiethOpt)
		echo "$twentiethOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentyfirstOpt)
		echo "$twentyfirstOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentysecondOpt)
		echo "$twentysecondOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentythirdOpt)
		echo "$twentythirdOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentyfourthOpt)
		echo "$twentyfourthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentyfifthOpt)
		echo "$twentyfifthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentysixthOpt)
		echo "$twentysixthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentyseventhOpt)
		echo "$twentyseventhOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentyeighthOpt)
		echo "$twentyeighthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
    $twentyninthOpt)
		echo "$twentyninthOpt" | sed "s/\s*#.*//g" | xclip -sel clip
        ;;
esac
