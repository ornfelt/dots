#!/usr/bin/env bash
# Wifi menu (right click on the network block): scans once and lists the
# networks it finds, the ones with a preset (wifi_preset_add.sh) first.
# A preset connects with its password, a saved or open network without one,
# any other network asks for its password and becomes a preset when the
# connection succeeds. dmenu or rofi: --dmenu / --rofi, else $LAUNCHER, else
# dmenu (menu_lib.sh); the password prompt is rofi's or yad's (hidden).

. ~/.local/bin/my_scripts/menu_lib.sh
menu_need
. ~/.local/bin/my_scripts/wifi_lib.sh
wifi_need_backend

TAG="string:x-dunst-stack-tag:wifi-menu"
msg() { wifi_notify -h "$TAG" "$@"; }
fail() { wifi_notify -u critical -h "$TAG" "$@"; exit 1; }

dev=$(wifi_dev) || fail "Wifi" "No wifi device"

# one menu at a time
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/wifi_menu.lock"
flock -n 9 || exit 0

ask_password() {
    if command -v rofi >/dev/null; then
        rofi -dmenu -password -l 0 -p "Password for $1" \
            -theme "$HOME/.config/rofi/themes/gruvbox/gruvbox-dark.rasi" </dev/null
    elif command -v yad >/dev/null; then
        yad --entry --hide-text --title "Wifi" --text "Password for $1"
    else
        fail "Wifi: can't ask for the password" "Install rofi: $(pkg_tip rofi rofi)"
    fi
}

# Tell the status bar to update the network block now (the awesome widget
# updates on its own timer)
refresh() {
    pkill -RTMIN+16 -x 'dwmblocks[cr]?' 2>/dev/null
}

msg -t 10000 "Wifi" "Scanning..."
# scan while gpg asks for the passphrase (if the agent doesn't have it)
scanfile=$(mktemp)
trap 'rm -f "$scanfile"' EXIT
wifi_scan > "$scanfile" &
scanpid=$!
presets=
if [ -f "$WIFI_PRESETS" ] && command -v gpg >/dev/null; then
    presets=$(presets_read) || msg "Wifi presets" "Couldn't decrypt them; showing the scan only"
fi
wait "$scanpid"
[ -s "$scanfile" ] || fail "Wifi" "The scan found no networks"

declare -A pw sec line2ssid
while IFS=$'\t' read -r ssid pass; do
    [ -n "$ssid" ] && pw[$ssid]=$pass
done <<< "$presets"

# presets first, each group strongest first (the scan's order)
lines=()
for group in preset other; do
    while IFS=$'\t' read -r signal security inuse ssid; do
        sec[$ssid]=$security
        if [ -n "${pw[$ssid]+x}" ]; then [ $group = preset ] || continue; else [ $group = other ] || continue; fi
        mark="  "; [ "$inuse" = "*" ] && mark="* "
        if [ $group = preset ]; then
            l=$(printf '%s%s  (preset, %s%%)' "$mark" "$ssid" "$signal")
        else
            l=$(printf '%s%s  (%s%%, %s)' "$mark" "$ssid" "$signal" "$security")
        fi
        line2ssid[$l]=$ssid
        lines+=("$l")
    done < "$scanfile"
done
wifi_notify -h "$TAG" -t 1 "Wifi" "Scan done"

chosen=$(printf '%s\n' "${lines[@]}" | menu "Wifi" 15)
[ -n "$chosen" ] || exit 0
ssid=${line2ssid[$chosen]}
[ -n "$ssid" ] || exit 0
[ "$ssid" = "$(wifi_current)" ] && { msg "Wifi" "Already connected to $(wifi_esc "$ssid")"; exit 0; }

password= newpreset=
if [ -n "${pw[$ssid]+x}" ]; then
    password=${pw[$ssid]}
elif [ "${sec[$ssid]}" = open ]; then
    :
elif wifi_known "$ssid"; then
    # the backend has the password; keep a copy as a preset if it tells us
    newpreset=$(wifi_secret "$ssid")
else
    password=$(ask_password "$ssid")
    [ -n "$password" ] || exit 0
    newpreset=$password
fi

msg -t 40000 "Wifi" "Connecting to $(wifi_esc "$ssid")..."
known=0; wifi_known "$ssid" && known=1
if ! err=$(wifi_connect "$ssid" "$password"); then
    # a failed first attempt leaves a profile with the wrong password behind
    [ $known = 0 ] && wifi_forget "$ssid"
    refresh
    fail "Wifi: couldn't connect to $(wifi_esc "$ssid")" "$(wifi_esc "$err")"
fi
refresh

saved=
if [ -n "$newpreset" ] && command -v gpg >/dev/null; then
    if presets_add "$ssid" "$newpreset"; then
        saved=" (saved as a preset)"
    else
        saved=" (couldn't save it as a preset)"
    fi
fi
msg "Wifi" "Connected to $(wifi_esc "$ssid")$saved"
