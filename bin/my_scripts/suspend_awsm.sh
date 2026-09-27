#! /bin/bash
# Pause music, lock the screen (random image from ~/Pictures/lockscreens), then suspend;
# see lock_random.sh. mod-shift-comma
sh ~/.local/bin/my_scripts/alert_exit.sh &
exec ~/.local/bin/my_scripts/lock_random.sh --pause --suspend
