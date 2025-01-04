#!/usr/bin/env bash

tsla=$(tstock tsla -b 1 | sed -n -e 's/^.*change://p' | sed -r 's/\s+//g')
evo=$(tstock evo -b 1 | sed -n -e 's/^.*change://p' | sed -r 's/\s+//g')

amd=$(tstock amd -b 1 | sed -n -e 's/^.*change://p' | sed -r 's/\s+//g')
msft=$(tstock msft -b 1 | sed -n -e 's/^.*change://p' | sed -r 's/\s+//g')
#echo $tsla
#echo $evo
#echo $amd
#echo $msft

#calc=`expr $tsla + $evo`
#calcTwo=`expr $amd + $msft`
#echo $calc
#echo $calcTwo

#urxvt -e sh -c "tstock tsla && printf '\nCalc: $calc \nCalc2: $calcTwo'; zsh"
#urxvt -e sh -c "tstock tsla -y 20 && echo -e '\nTesla stock: $tsla\nEvo stock: $evo\nAmd stock: $amd\nMsft stock: $msft'; zsh"
wezterm -e sh -c "tstock tsla -y 20 && echo -e '\nTesla stock: $tsla\nEvo stock: $evo\nAmd stock: $amd\nMsft stock: $msft'; zsh"

