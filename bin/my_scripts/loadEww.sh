#! /bin/bash
check_process() {
	[ `pgrep $1` ] && return 1 || return 0
}
check_process "eww"
[ $? -eq 0 ] && eww daemon && /usr/bin/eww open-many user power date control screenshot system fetch player home disk downloads pictures documents favourite myPicture
[ $? -eq 1 ] && pkill eww
