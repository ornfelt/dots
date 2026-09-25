#!/bin/bash

# Watch the memory use of the running window manager and status bar, like
# `watch -n 5 free -m`, to spot leaks: RSS/PSS now, the change since the
# script started and since the last sample, the growth per hour, the peak,
# threads and open files. With -p, draw live timecharts instead
# (wm_mem_plot.py, plotext, gruvbox like `proc.sh livetop`).
#
# USAGE:
# wm_mem.sh                  (detect the window manager and bar, every 5 seconds)
# wm_mem.sh 2                (sample every 2 seconds)
# wm_mem.sh -p               (live timecharts)
# wm_mem.sh -p 1             (live timecharts, sampled every second)
# wm_mem.sh -w dwmr -b dwmblocksr   (watch the given process names or PIDs)
# wm_mem.sh -b none          (the window manager only)
#
# Window manager: the X window manager's _NET_WM_NAME, then Hyprland's
# environment, then the first known window manager process of this user.
# Bar: the first known bar process of this user; awesome, somewm, qtile and
# the like draw their bar themselves, so it is part of their memory.
#
# Colours: green is fine, dark yellow worth a look, red a likely problem.
# Sizes are judged by the kind of process (dwm-like, awesome-like or a
# desktop shell), growth relative to the size at the start; the growth rate
# is only judged after 10 minutes, before that it is too noisy.

usage() { sed -n '3,/^$/s/^# \{0,1\}//p' "$0"; }

# Colours, only on a terminal
if [ -t 1 ]; then
	RESET=$'\033[0m' RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m'
	CYAN=$'\033[36m' MAGENTA=$'\033[35m' DARKGRAY=$'\033[90m'
else
	RESET= RED= GREEN= YELLOW= CYAN= MAGENTA= DARKGRAY=
fi
write_err() { echo "${RED}${1}${RESET}"; }
write_info() { echo "${CYAN}${1}${RESET}"; }
# Colour of a table cell's level: g(ood), w(arning), b(ad), n(eutral),
# p(rocess), d (not judged yet)
declare -A LEVEL=([g]=$GREEN [w]=$YELLOW [b]=$RED [n]= [p]=$MAGENTA [d]=$DARKGRAY)

interval=5 plot= want_wm= want_bar= pids_only=
while [ $# -gt 0 ]; do
	case $1 in
	-p | --plot) plot=1 ;;
	-w | --wm) want_wm=${2:?-w needs a name or PID}; shift ;;
	-b | --bar) want_bar=${2:?-b needs a name, PID or none}; shift ;;
	--pids) pids_only=1 ;; # for wm_mem_plot.py: print "wm|bar PID NAME"
	-h | --help) usage; exit 0 ;;
	[0-9]*) interval=$1 ;;
	*) want_wm=$1 ;; # wm_mem.sh 5 dwmr, as before
	esac
	shift
done

# Process names (as in /proc/PID/comm, at most 15 characters)
wms=(dwmr dwm awesome somewm Hyprland i3 sway bspwm qtile xmonad herbstluftwm
	openbox fluxbox spectrwm leftwm river niri labwc wayfire xfwm4 kwin_x11
	kwin_wayland gnome-shell)
bars=(dwmblocksr dwmblocks slstatus polybar waybar lemonbar i3status-rs
	i3status i3blocks yambar ironbar xmobar tint2 eww somebar dzen2 sfwbar
	plasmashell xfce4-panel lxpanel)
# window managers whose bar is part of the window manager process
builtin_bar=" awesome somewm qtile gnome-shell "
# Size classes for the RSS/PSS/anon colours (keep in sync with wm_mem_plot.py):
# small C programs, desktop shells and compositors, and the rest in between
small=" dwmr dwm i3 bspwm herbstluftwm openbox fluxbox spectrwm leftwm river
	dwmblocksr dwmblocks slstatus lemonbar i3status i3status-rs i3blocks somebar dzen2 yambar "
large=" gnome-shell kwin_x11 kwin_wayland plasmashell Hyprland "

pidof_user() { pgrep -o -x -u "$USER" "$1"; }

# find NAME|PID: the PID of a process name, or the PID itself if it runs
find_pid() {
	if [[ $1 =~ ^[0-9]+$ ]]; then [ -d "/proc/$1" ] && echo "$1"; else pidof_user "$1"; fi
}

detect_wm() {
	local name pid win
	[ -n "$want_wm" ] && { find_pid "$want_wm"; return; }
	# X: the window manager names itself on the _NET_SUPPORTING_WM_CHECK window
	if [ -n "$DISPLAY" ] && command -v xprop >/dev/null; then
		win=$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk '/window id/ { print $NF }')
		if [ -n "$win" ]; then
			name=$(xprop -id "$win" _NET_WM_NAME 2>/dev/null | sed -n 's/.*= "\(.*\)"/\1/p')
			[ -n "$name" ] && pid=$(pidof_user "$name") && { echo "$pid"; return; }
		fi
	fi
	[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && pid=$(pidof_user Hyprland) && { echo "$pid"; return; }
	for name in "${wms[@]}"; do
		pid=$(pidof_user "$name") && { echo "$pid"; return; }
	done
	return 1
}

detect_bar() {
	local name pid
	[ "$want_bar" = none ] && return 1
	[ -n "$want_bar" ] && { find_pid "$want_bar"; return; }
	for name in "${bars[@]}"; do
		pid=$(pidof_user "$name") && { echo "$pid"; return; }
	done
	return 1
}

if [ -n "$pids_only" ]; then
	pid=$(detect_wm) && echo "wm $pid $(cat "/proc/$pid/comm")"
	pid=$(detect_bar) && echo "bar $pid $(cat "/proc/$pid/comm")"
	exit 0
fi

if [ -n "$plot" ]; then
	args=(--interval "$interval")
	[ -n "$want_wm" ] && args+=(--wm "$want_wm")
	[ -n "$want_bar" ] && args+=(--bar "$want_bar")
	exec python3 "${0%/*}/wm_mem_plot.py" "${args[@]}"
fi

# Value in kB of a "Key:   123 kB" line
field() { awk -v k="$1:" '$1 == k { print $2; exit }' "$2" 2>/dev/null; }

mib() { awk -v k="$1" 'BEGIN { printf "%.2f MiB", k / 1024 }'; }
signed_mib() { awk -v k="$1" 'BEGIN { printf "%+.2f MiB", k / 1024 }'; }
per_hour() { awk -v d="$1" -v t="$2" 'BEGIN { if (t > 0) printf "%+.2f MiB/h", d / 1024 * 3600 / t; else print "-" }'; }

# level VALUE GOOD WARN: g if VALUE <= GOOD, w if <= WARN, b above
level() { awk -v v="$1" -v g="$2" -v w="$3" 'BEGIN { print (v <= g ? "g" : v <= w ? "w" : "b") }'; }

# size_limits NAME: the good and warning limits in kB for its memory size
size_limits() {
	if [[ $small == *" $1 "* ]]; then echo "32768 98304"         # 32 / 96 MiB
	elif [[ $large == *" $1 "* ]]; then echo "393216 1048576"    # 384 MiB / 1 GiB
	else echo "131072 393216"; fi                                 # 128 / 384 MiB
}

# growth_level DELTA START: growth since the start, in kB; fine up to 2% of
# the size at the start (at least 512 kB), a warning up to 10% (2 MiB)
growth_level() {
	awk -v d="$1" -v s="$2" 'BEGIN {
		g = s * 0.02; if (g < 512) g = 512
		w = s * 0.10; if (w < 2048) w = 2048
		print (d <= g ? "g" : d <= w ? "w" : "b") }'
}

# rate_level DELTA ELAPSED: kB over seconds; fine up to 0.25 MiB/h, a warning
# up to 2 MiB/h; not judged (d) for the first 10 minutes, when it is mostly noise
rate_level() {
	awk -v d="$1" -v t="$2" 'BEGIN {
		if (t < 600) { print "d"; exit }
		r = d / 1024 * 3600 / t
		print (r <= 0.25 ? "g" : r <= 2 ? "w" : "b") }'
}

# Per target (wm, bar): pid, name, start time and the first/previous samples
declare -A pid name start start_rss start_anon prev_rss
# This sample's values, per target: val[wm_rss], ...
declare -A val

# sample T: read target T's /proc files into val[T_*]; 1 if it has no process
sample() {
	local t=$1 p status
	if [ -z "${pid[$t]}" ] || [ ! -d "/proc/${pid[$t]}" ]; then
		if [ "$t" = wm ]; then p=$(detect_wm); else p=$(detect_bar); fi || { pid[$t]=; return 1; }
		pid[$t]=$p name[$t]=$(cat "/proc/$p/comm" 2>/dev/null)
		start[$t]=$(date +%s) start_rss[$t]= start_anon[$t]= prev_rss[$t]=
	fi
	p=${pid[$t]} status=/proc/$p/status
	val[${t}_rss]=$(field VmRSS "$status")
	[ -z "${val[${t}_rss]}" ] && { pid[$t]=; return 1; } # it exited meanwhile
	local k
	for k in RssAnon:anon RssFile:file RssShmem:shmem VmHWM:hwm VmSize:size VmSwap:swap Threads:threads; do
		val[${t}_${k#*:}]=$(field "${k%:*}" "$status")
	done
	val[${t}_pss]=$(field Pss "/proc/$p/smaps_rollup")
	val[${t}_dirty]=$(field Private_Dirty "/proc/$p/smaps_rollup")
	val[${t}_fds]=$(ls "/proc/$p/fd" 2>/dev/null | wc -l)
	val[${t}_etime]=$(ps -o etime= -p "$p" | tr -d ' ')
	: "${val[${t}_anon]:=0}"
	: "${start_rss[$t]:=${val[${t}_rss]}}" "${prev_rss[$t]:=${val[${t}_rss]}}" "${start_anon[$t]:=${val[${t}_anon]}}"
	return 0
}

# cell "LEVEL|TEXT": TEXT right-aligned in 18 columns, in LEVEL's colour
# (padded before colouring, so the escape codes don't break the alignment)
cell() {
	local pad
	printf -v pad '%18s' "${1#*|}"
	printf '%s%s%s' "${LEVEL[${1%%|*}]}" "$pad" "$RESET"
}

# row LABEL WM-CELL BAR-CELL
row() { printf '  %-22s %s %s\n' "$1" "$(cell "$2")" "$(cell "$3")"; }

# column T: target T's cells for the table, "LEVEL|TEXT" one per line
column() {
	local t=$1 now elapsed rss anon swap good warn threads fds lv
	if [ -z "${pid[$t]}" ]; then
		for _ in {1..18}; do echo "n|"; done
		return
	fi
	now=$(date +%s) elapsed=$((now - start[$t]))
	rss=${val[${t}_rss]} anon=${val[${t}_anon]} swap=${val[${t}_swap]:-0}
	read -r good warn < <(size_limits "${name[$t]}")
	echo "p|${name[$t]} (${pid[$t]})"
	echo "n|${val[${t}_etime]}"
	echo "$(level "$rss" "$good" "$warn")|$(mib "$rss")"
	echo "$(level "$anon" "$good" "$warn")|$(mib "$anon")"
	echo "n|$(mib "${val[${t}_file]:-0}")"
	echo "n|$(mib "${val[${t}_shmem]:-0}")"
	echo "$(level "${val[${t}_pss]:-0}" "$good" "$warn")|$(mib "${val[${t}_pss]:-0}")"
	echo "$(level "${val[${t}_dirty]:-0}" "$good" "$warn")|$(mib "${val[${t}_dirty]:-0}")"
	echo "$(level "$swap" 0 10240)|$(mib "$swap")"
	echo "$(level "${val[${t}_hwm]:-0}" "$good" "$warn")|$(mib "${val[${t}_hwm]:-0}")"
	echo "n|$(mib "${val[${t}_size]:-0}")"
	echo "$(level $((rss - prev_rss[$t])) 64 1024)|$(signed_mib $((rss - prev_rss[$t])))"
	echo "$(growth_level $((rss - start_rss[$t])) "${start_rss[$t]}")|$(signed_mib $((rss - start_rss[$t])))"
	echo "$(growth_level $((anon - start_anon[$t])) "${start_rss[$t]}")|$(signed_mib $((anon - start_anon[$t])))"
	echo "$(rate_level $((rss - start_rss[$t])) "$elapsed")|$(per_hour $((rss - start_rss[$t])) "$elapsed")"
	echo "$(rate_level $((anon - start_anon[$t])) "$elapsed")|$(per_hour $((anon - start_anon[$t])) "$elapsed")"
	threads=${val[${t}_threads]:-0} fds=${val[${t}_fds]:-0}
	# the worse of the two: many threads or a growing number of open files
	lv=$(level "$threads" 32 128)
	[ "$lv" != b ] && case $(level "$fds" 128 512) in b) lv=b ;; w) lv=w ;; esac
	echo "$lv|$threads / $fds"
	echo "n|$((elapsed / 60))m $((elapsed % 60))s"
}

labels=("Process" "Running for" "RSS (resident)" "  anon (heap/stack)" "  file (mapped libs)"
	"  shmem" "PSS (proportional)" "Private dirty" "Swap" "Peak RSS" "Virtual size"
	"RSS since last sample" "RSS since start" "Anon since start" "RSS growth rate"
	"Anon growth rate" "Threads / open files" "Watched for")

while true; do
	sample wm
	sample bar
	if [ -z "${pid[wm]}" ] && [ -z "${pid[bar]}" ]; then
		clear
		write_err "wm_mem: no window manager or bar found (try: wm_mem.sh -w <name|pid> -b <name|pid>)"
		sleep "$interval"
		continue
	fi

	mapfile -t wmcol < <(column wm)
	mapfile -t barcol < <(column bar)
	if [ -z "${pid[bar]}" ]; then
		if [ "$want_bar" = none ]; then barcol[0]="n|(not watched)"
		elif [[ $builtin_bar == *" ${name[wm]} "* ]]; then barcol[0]="n|(in ${name[wm]})"
		else barcol[0]="w|(no bar found)"; fi
	fi
	[ -z "${pid[wm]}" ] && wmcol[0]="w|(no wm found)"

	clear
	printf '%sEvery %ss: window manager and bar memory%s%*s%s%s%s\n\n' "$CYAN" "$interval" "$RESET" 8 "" \
		"$DARKGRAY" "$(date '+%a %d %b %H:%M:%S')" "$RESET"
	printf '  %-22s %s%18s %18s%s\n' "" "$CYAN" "WINDOW MANAGER" "BAR" "$RESET"
	for i in "${!labels[@]}"; do
		row "${labels[$i]}" "${wmcol[$i]}" "${barcol[$i]}"
		case $i in 1 | 10 | 15) echo ;; esac
	done
	echo
	echo "  ${GREEN}fine${RESET}  ${YELLOW}worth a look${RESET}  ${RED}likely a problem${RESET}"
	# the growth rates are gray until they are judged, say so and for how long
	warm=0
	for t in wm bar; do
		[ -n "${pid[$t]}" ] && (($(date +%s) - start[$t] < 600)) &&
			warm=$((600 - ($(date +%s) - start[$t])))
	done
	((warm > 0)) && echo "  ${DARKGRAY}Growth rates are judged after 10 minutes ($((warm / 60))m $((warm % 60))s to go).${RESET}"
	echo "${DARKGRAY}  Anon/private dirty that keeps growing while you do the same things is a leak;"
	echo "  file/shmem go up and down with libraries and shared buffers.${RESET}"

	for t in wm bar; do [ -n "${pid[$t]}" ] && prev_rss[$t]=${val[${t}_rss]}; done
	sleep "$interval"
done
