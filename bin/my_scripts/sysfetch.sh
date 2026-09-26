#!/usr/bin/env bash
# System info in a notification, like neofetch (mod-section in awesome, dwm,
# dwmc and dwmr). Each item below says what it shows, and gives a one-liner
# that prints the same in a terminal.
#   sysfetch.sh           the notification
#   sysfetch.sh --print   print it to the terminal instead
#
# Everything is read from /proc, /sys and a few quick commands, so it takes a
# fraction of a second; an item it can't find shows "unknown".

# "Label: value" lines; dunst's font is monospace, so the values line up. A
# value with several lines gets them indented under the first (a long line
# would wrap, and awesome's popups then cut off the last line)
out=""
add() { [ -n "$2" ] || set -- "$1" unknown; out+=$(printf '%-9s %s' "$1:" "$2" | sed '2,$s/^/          /')$'\n'; }
have() { command -v "$1" >/dev/null; }

# Title: user@hostname
#   echo "$USER@$(hostname)"
title="$USER@$(cat /proc/sys/kernel/hostname)"

# OS: distribution name and CPU architecture
#   . /etc/os-release; echo "$PRETTY_NAME $(uname -m)"
os=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")
add OS "${os:+$os }$(uname -m)"

# Kernel: the running kernel's release
#   uname -r
add Kernel "$(uname -r)"

# Host: the machine's vendor and model from the firmware (DMI)
#   cat /sys/class/dmi/id/{sys_vendor,product_name,product_version}
#   (or: hostnamectl | grep -E 'Vendor|Model')
dmi=/sys/class/dmi/id
host=$(cat "$dmi/sys_vendor" "$dmi/product_name" "$dmi/product_version" 2>/dev/null |
    grep -viE '^(|none|default string|to be filled.*|system product name|not applicable)$' | awk '!seen[$0]++' | tr '\n' ' ')
add Host "${host% }"

# Uptime: time since boot
#   uptime -p        (or: awk '{ print int($1 / 3600) "h " int($1 % 3600 / 60) "m" }' /proc/uptime)
add Uptime "$(awk '{ s = int($1); d = int(s / 86400); h = int(s % 86400 / 3600); m = int(s % 3600 / 60)
    printf "%s%s%dm", d ? d "d " : "", (d || h) ? h "h " : "", m }' /proc/uptime)"

# Packages: installed packages per package manager
#   dpkg-query -f '.\n' -W | wc -l    (Debian)
#   pacman -Qq | wc -l                (Arch)
#   flatpak list | wc -l; snap list | tail -n +2 | wc -l
pkgs=()
have dpkg-query && pkgs+=("$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l) (dpkg)")
have pacman && pkgs+=("$(pacman -Qq 2>/dev/null | wc -l) (pacman)")
have rpm && pkgs+=("$(rpm -qa 2>/dev/null | wc -l) (rpm)")
have flatpak && pkgs+=("$(flatpak list 2>/dev/null | wc -l) (flatpak)")
have snap && pkgs+=("$(snap list 2>/dev/null | tail -n +2 | wc -l) (snap)")
add Packages "$(IFS=,; echo "${pkgs[*]}" | sed 's/,/, /g')"

# Display: each active monitor's resolution and refresh rate
#   xrandr --query | awk '/ connected/ { o = $1 } /\*/ { print o, $1, $2 }'   (X)
#   wlr-randr, or hyprctl monitors                                              (Wayland)
display=
if [ -n "$DISPLAY" ] && have xrandr; then
    display=$(xrandr --query 2>/dev/null | awk '
        / connected/ { out = $1 }
        /\*/ { for (i = 2; i <= NF; i++) if ($i ~ /\*/) { r = $i; gsub(/[*+]/, "", r) }
               printf "%s%s %s @ %.0fHz", sep, out, $1, r; sep = ", " }')
elif have hyprctl; then
    display=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/ { o = $2 } /@/ && o { split($1, m, "@"); printf "%s%s %s @ %.0fHz", sep, o, m[1], m[2]; sep = ", "; o = "" }')
elif have wlr-randr; then
    display=$(wlr-randr 2>/dev/null | awk '/^[^ ]/ { o = $1 } /current/ { printf "%s%s %s @ %.0fHz", sep, o, $1, $3; sep = ", " }')
fi
add Display "$display"

# WM: the running window manager, with its version
#   xprop -id "$(xprop -root _NET_SUPPORTING_WM_CHECK | awk '{ print $NF }')" _NET_WM_NAME
#   (the dwm forks all call themselves dwm there; tell them apart with: pgrep -xa 'dwm|dwmc|dwmr')
wm=
for w in awesome dwmr dwmc dwm i3 sway Hyprland bspwm openbox xmonad qtile herbstluftwm; do
    pgrep -x "$w" >/dev/null || continue
    case $w in
        awesome) wm=$(awesome --version 2>/dev/null | head -n 1 | awk '{ print "awesome", $2 }') ;;
        dwm) wm=$(dwm -v 2>&1 | head -n 1) ;;
        *) wm=$w ;;
    esac
    break
done
if [ -z "$wm" ] && [ -n "$DISPLAY" ] && have xprop; then
    id=$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk '{ print $NF }')
    wm=$(xprop -id "$id" _NET_WM_NAME 2>/dev/null | sed -n 's/.*= "\(.*\)"/\1/p')
fi
add WM "${wm:-${XDG_CURRENT_DESKTOP:-}}"

# Bar: the status bar(s) running
#   pgrep -xa 'dwmblocks|dwmblocksc|dwmblocksr|i3bar|polybar|waybar|lemonbar|xmobar|eww|tint2|yambar'
#   (awesome and qtile draw their own bar: pgrep -x awesome)
bars=()
for b in dwmblocks dwmblocksc dwmblocksr i3bar i3blocks polybar waybar lemonbar xmobar eww tint2 yambar; do
    pgrep -x "$b" >/dev/null && bars+=("$b")
done
case $wm in
    awesome*) bars=("awesome wibar" "${bars[@]}") ;;
    qtile*) bars=("qtile bar" "${bars[@]}") ;;
esac
add Bar "$(IFS=,; echo "${bars[*]}" | sed 's/,/, /g')"

# CPU: the model, threads and highest clock speed
#   grep -m1 'model name' /proc/cpuinfo; nproc
#   (or: lscpu | grep -E 'Model name|^CPU\(s\)|max MHz')
cpu=$(awk -F ': ' '/^model name/ { print $2; exit }' /proc/cpuinfo | sed 's/ \{2,\}/ /g; s/(R)//g; s/(TM)//g; s/ with .*//; s/ [0-9]*-Core Processor//; s/ CPU//')
threads=$(grep -c '^processor' /proc/cpuinfo)
maxkhz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
add CPU "$cpu${threads:+ ($threads)}${maxkhz:+ @ $(awk -v k="$maxkhz" 'BEGIN { printf "%.2fGHz", k / 1e6 }')}"

# GPU: graphics devices on the PCI bus
#   lspci | grep -Ei 'vga|3d|display'
gpu=
if have lspci; then
    gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller' |
        sed 's/^[0-9a-f:.]* [^:]*: //; s/ (rev [0-9a-f]*)//; s/Advanced Micro Devices, Inc. \[AMD\/ATI\]/AMD/; s/NVIDIA Corporation/NVIDIA/; s/Intel Corporation/Intel/' |
        paste -sd ',' | sed 's/,/, /g')
else
    gpu="unknown (lspci: $( . /etc/os-release; case " $ID $ID_LIKE " in *" arch "*) echo "sudo pacman -S pciutils" ;; *) echo "sudo apt install pciutils" ;; esac))"
fi
add GPU "$gpu"

# Memory: used (total minus what's available) of the total
#   free -h        (or: awk '/MemTotal|MemAvailable/' /proc/meminfo)
# Swap: used of the total
#   free -h | grep Swap    (or: swapon --show)
read -r memline swapline < <(awk '
    function h(k) { return k >= 1048576 ? sprintf("%.1fGiB", k / 1048576) : sprintf("%dMiB", k / 1024) }
    { m[$1] = $2 }
    END {
        mu = m["MemTotal:"] - m["MemAvailable:"]; su = m["SwapTotal:"] - m["SwapFree:"]
        printf "%s/%s(%d%%) ", h(mu), h(m["MemTotal:"]), m["MemTotal:"] ? mu * 100 / m["MemTotal:"] : 0
        if (m["SwapTotal:"]) printf "%s/%s(%d%%)\n", h(su), h(m["SwapTotal:"]), su * 100 / m["SwapTotal:"]
        else print "none"
    }' /proc/meminfo)
add Memory "$(sed 's|/| / |; s|(| (|' <<< "$memline")"
add Swap "$(sed 's|/| / |; s|(| (|' <<< "$swapline")"

# Disk: used of the size of the root filesystem
#   df -h /
add Disk "$(df -hP / 2>/dev/null | awk 'NR == 2 { printf "%s / %s (%s) %s", $3, $2, $5, $1 }')"

# Local IP: the address of the interface used for the internet (the default
# route), and the other interfaces with an address
#   ip route get 1.1.1.1 | awk '{ for (i = 1; i < NF; i++) if ($i == "src") print $(i + 1) }'
#   ip -4 -br addr show scope global      (or: hostname -I)
ipinfo=
if have ip; then
    main=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{ for (i = 1; i < NF; i++) { if ($i == "src") s = $(i + 1); if ($i == "dev") d = $(i + 1) } } END { if (s) print s " (" d ")" }')
    others=$(ip -4 -br addr show scope global 2>/dev/null | awk -v m="$main" '{ split($3, a, "/"); if (index(m, a[1] " ") != 1) print a[1] " (" $1 ")" }')
    ipinfo="$main${main:+${others:+$'\n'}}$others"
fi
add "Local IP" "${ipinfo:-not connected}"

# Battery: charge and state of each battery
#   cat /sys/class/power_supply/BAT*/{capacity,status}   (or: acpi -b, upower -i $(upower -e | grep BAT))
bat=
for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] || continue
    bat+="${bat:+, }$(cat "$b/capacity")% ($(cat "$b/status" 2>/dev/null | tr '[:upper:]' '[:lower:]'))"
done
add Battery "${bat:-none}"

out=${out%$'\n'}
if [ "$1" = --print ] || ! have notify-send; then
    printf '%s\n%s\n' "$title" "$out"
else
    notify-send -a sysfetch -t 20000 -h string:x-dunst-stack-tag:sysfetch "$title" \
        "$(printf '%s' "$out" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
fi
