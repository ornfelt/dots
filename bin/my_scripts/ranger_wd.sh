#!/bin/bash
WHEREAMI=$(cat /tmp/whereami)
#ranger -r ~/.config/ranger -cd "$WHEREAMI"
urxvt -e ranger -r ~/.config/ranger "$WHEREAMI"
