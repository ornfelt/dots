#! /bin/bash
amixer set Master mute
kill -44 $(pidof dwmblocks)
systemctl suspend
