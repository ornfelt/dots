#!/bin/bash
WHEREAMI=$(cat /tmp/whereami)
#urxvt -e ranger -r ~/.config/ranger "$WHEREAMI"
$1 -e ranger -r ~/.config/ranger "$WHEREAMI"
