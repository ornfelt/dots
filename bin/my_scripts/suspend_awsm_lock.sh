#! /bin/bash
sh ~/.local/bin/my_scripts/alert_exit.sh &

if ! command -v i3lock >/dev/null; then
    msg="missing: i3lock. Install with: sudo apt install i3lock"
    echo "suspend_awsm_lock: $msg" >&2
    command -v notify-send >/dev/null && notify-send "suspend_awsm_lock" "$msg"
    exit 1
fi

# No "&": i3lock forks only after it has grabbed the screen, so waiting for it
# means the machine never suspends before the lock is up. Don't suspend
# unlocked if it fails
i3lock || exit 1
amixer set Master mute
systemctl suspend
