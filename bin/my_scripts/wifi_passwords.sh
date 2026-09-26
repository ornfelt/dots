#!/usr/bin/env bash

# List every saved NetworkManager wifi profile with its password
# Passwords kept in a user keyring are only readable from the desktop session

command -v nmcli >/dev/null || { echo "nmcli not found" >&2; exit 1; }

# Print one value of a profile, secrets included, without escaping ':'
get() {
	nmcli -s --escape no -g "$2" connection show uuid "$1" 2>/dev/null
}

rows=()
while IFS=: read -r uuid type; do
	[ "$type" = "802-11-wireless" ] || continue

	ssid=$(get "$uuid" 802-11-wireless.ssid)
	[ -n "$ssid" ] || ssid=$(get "$uuid" connection.id)
	sec=$(get "$uuid" 802-11-wireless-security.key-mgmt)

	case "$sec" in
	"") sec="open" pass="-" ;;
	none) pass=$(get "$uuid" 802-11-wireless-security.wep-key0) ;;
	wpa-eap*) pass="$(get "$uuid" 802-1x.identity) / $(get "$uuid" 802-1x.password)" ;;
	*) pass=$(get "$uuid" 802-11-wireless-security.psk) ;;
	esac
	[ -n "$pass" ] || pass="(not readable)"

	rows+=("$ssid"$'\t'"$sec"$'\t'"$pass")
done < <(nmcli -t -f UUID,TYPE connection show)

[ ${#rows[@]} -gt 0 ] || { echo "No saved wifi networks"; exit 0; }

{
	printf 'SSID\tSECURITY\tPASSWORD\n'
	printf '%s\n' "${rows[@]}" | sort -f
} | column -t -s $'\t'
