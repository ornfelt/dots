#! /bin/bash
amixer set Master mute
pkill -44 -x 'dwmblocksr?'
systemctl suspend
