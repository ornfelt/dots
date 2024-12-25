#!/bin/bash

# https://github.com/cdown/clipmenu

# If run with an argument -> rofi
# otherwise -> dmenu
if [ $# -gt 0 ]; then
    export CM_LAUNCHER=rofi
else
    export CM_LAUNCHER=dmenu
fi

clipmenu

