#!/bin/bash

BAR_ID=$(pgrep -x polybar)

if [ -n "${BAR_ID}" ] ; then
    kill -TERM ${BAR_ID}
    pkill -ALRM sxhkd
    bspc config top_padding 0
else
    pkill -ALRM sxhkd
    # Launch bar1 and bar2
	~/.config/polybar/launch.sh --forest
    #polybar left_screen &
    #polybar right_screen
    echo "Bars launched..."
fi
