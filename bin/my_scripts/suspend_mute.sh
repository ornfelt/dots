#! /bin/bash
amixer set Master mute
pkill -44 -x 'dwmblocks[rc]?'
systemctl suspend
