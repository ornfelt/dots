#!/usr/bin/env bash

# System menu (lock/sleep/logout/restart/shutdown) for every WM's mod-shift-e.

# Clear the login greeting stamp (see hello.sh), as the wrapper did
sh ~/.local/bin/my_scripts/alert_exit.sh &

uptime=$(uptime -p | sed -e 's/up //g')

# dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else dmenu (menu_lib.sh)
. ~/.local/bin/my_scripts/menu_lib.sh
menu_need

# Options
shutdown=" Shutdown"
reboot=" Restart"
lock=" Lock"
suspend=" Sleep"
logout=" Logout"

# Confirmation
confirm_exit() {
	# "No" first so an accidental Enter is harmless; lowercase so typed
	# answers like "Y" still match the checks below
	echo -e "No\nYes" | menu "Are You Sure?" "" -selected-row 0 | tr '[:upper:]' '[:lower:]'
}

# Message
msg() {
	menu_msg "Available Options  -  yes / y / no / n"
}

# Variable passed to the menu
options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | menu "Uptime: $uptime" "" -selected-row 0)"
case $chosen in
    $shutdown)
		ans=$(confirm_exit &)
		if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			systemctl poweroff
		elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			exit 0
        fi
        ;;
    $reboot)
		ans=$(confirm_exit &)
		if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			systemctl reboot
		elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			exit 0
        fi
        ;;
    $lock)
		if [[ -f /usr/bin/i3lock ]]; then
			i3lock
		elif [[ -f /usr/bin/betterlockscreen ]]; then
			betterlockscreen -l
		fi
        ;;
    $suspend)
		ans=$(confirm_exit &)
		if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			exit 0
        fi
        ;;
    $logout)
		ans=$(confirm_exit &)
		if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			if [[ "$DESKTOP_SESSION" == "Openbox" ]]; then
				openbox --exit
			elif [[ "$DESKTOP_SESSION" == "bspwm" ]]; then
				bspc quit
			elif [[ "$DESKTOP_SESSION" == "i3" ]]; then
				i3-msg exit
			else
				# WM-agnostic: end the X session itself. Killing xinit (startx)
				# takes down the server and every client, whatever WM runs;
				# fall back to logind for display-manager sessions.
				xinit_pid=$(pgrep -u "$USER" -x xinit | head -n 1)
				if [[ -n "$xinit_pid" ]]; then
					kill "$xinit_pid"
				elif [[ -n "$XDG_SESSION_ID" ]]; then
					loginctl terminate-session "$XDG_SESSION_ID"
				else
					loginctl terminate-user "$USER"
				fi
			fi
		elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			exit 0
        fi
        ;;
esac
