#!/usr/bin/env bash
# Add a wifi preset to the encrypted presets file (wifi_lib.sh), or replace
# the one with the same name. wifi_menu.sh offers the presets that a scan
# finds.
#   wifi_preset_add.sh SSID [PASSWORD]  asks for the password when it's not
#                                       given (hidden)
#   wifi_preset_add.sh --import         every saved network with a password
#                                       that wifi_passwords.sh lists
# The first preset creates the gpg key "wifi-presets", which asks for a new
# passphrase. Reading the presets back asks for it (gpg-agent caches it).

. ~/.local/bin/my_scripts/wifi_lib.sh
presets_need_gpg

die() { echo "${0##*/}: $*" >&2; exit 1; }

# A hidden password prompt: on the terminal, else a rofi or yad dialog
ask_password() {
    local pw
    if [ -t 0 ]; then
        read -rsp "Password for $1: " pw && echo >&2
    elif command -v rofi >/dev/null; then
        pw=$(rofi -dmenu -password -l 0 -p "Password for $1" \
            -theme "$HOME/.config/rofi/themes/gruvbox/gruvbox-dark.rasi" </dev/null)
    elif command -v yad >/dev/null; then
        pw=$(yad --entry --hide-text --title "Wifi preset" --text "Password for $1")
    else
        die "no terminal, rofi or yad to ask for the password"
    fi
    printf '%s' "$pw"
}

case $1 in
    "" | -h | --help)
        sed -n '2,11s/^# \{0,1\}//p' "$0"
        exit 0 ;;
    --import)
        rows=$(~/.local/bin/my_scripts/wifi_passwords.sh --tsv) || die "wifi_passwords.sh failed"
        [ -n "$rows" ] || die "wifi_passwords.sh lists no saved networks"
        # one decrypt and one encrypt for all of them
        presets_key || die "no gpg key $WIFI_KEY"
        old=$(presets_read) || die "can't decrypt $WIFI_PRESETS"
        added=0 skipped=
        while IFS=$'\t' read -r ssid sec pass; do
            case $sec:$pass in
                open:* | *:- | *:"(not readable)" | wpa-eap*) skipped="$skipped, $ssid ($sec)"; continue ;;
            esac
            old=$(printf '%s\n' "$old" | awk -F '\t' -v s="$ssid" 'NF && $1 != s'; printf '%s\t%s' "$ssid" "$pass")
            added=$((added + 1))
        done <<< "$rows"
        [ "$added" -gt 0 ] || die "no network with a password to import${skipped:+ (skipped ${skipped#, })}"
        umask 077
        mkdir -p "$WIFI_PRESETS_DIR" && chmod 700 "$WIFI_PRESETS_DIR"
        tmp="$WIFI_PRESETS.tmp.$$"
        printf '%s\n' "$old" | gpg --quiet --no-tty --batch --yes --trust-model always \
            --encrypt -r "$WIFI_KEY" -o "$tmp" && mv "$tmp" "$WIFI_PRESETS" || { rm -f "$tmp"; die "encrypting failed"; }
        echo "Imported $added preset(s) into $WIFI_PRESETS"
        [ -n "$skipped" ] && echo "Skipped (no password): ${skipped#, }"
        exit 0 ;;
esac

ssid=$1
pw=${2-$(ask_password "$ssid")}
[ -n "$pw" ] || die "no password given"
presets_add "$ssid" "$pw" || die "couldn't save the preset"
echo "Saved preset $ssid"
