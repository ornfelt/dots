#!/usr/bin/env bash
# Print the wifi presets of the encrypted presets file (wifi_lib.sh):
#   wifi_preset_list.sh           SSID and password of each, as a table
#   wifi_preset_list.sh --ssids   the SSIDs only
# Asks for the passphrase of the gpg key when gpg-agent doesn't have it.

. ~/.local/bin/my_scripts/wifi_lib.sh
presets_need_gpg

[ -f "$WIFI_PRESETS" ] || { echo "No presets yet ($WIFI_PRESETS); add one with wifi_preset_add.sh"; exit 0; }
presets=$(presets_read) || { echo "${0##*/}: can't decrypt $WIFI_PRESETS" >&2; exit 1; }

case $1 in
    --ssids) printf '%s\n' "$presets" | cut -f1 | sort -f ;;
    "")
        {
            printf 'SSID\tPASSWORD\n'
            printf '%s\n' "$presets" | sort -f
        } | column -t -s $'\t' ;;
    *) sed -n '2,5s/^# \{0,1\}//p' "$0"; exit 1 ;;
esac
