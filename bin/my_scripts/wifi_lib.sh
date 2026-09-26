# Shared wifi helpers for sb-network, wifi_menu.sh and the wifi_preset_*
# scripts (bash). Source it:
#   . ~/.local/bin/my_scripts/wifi_lib.sh
#
# Backend: NetworkManager (nmcli) when it runs, else iwd (iwctl).
#   wifi_backend              nm, iwd, or nothing (and status 1)
#   wifi_need_backend         exit with a notification and an install tip
#                             when there is none
#   wifi_service              the systemd service of the backend
#   wifi_dev                  the first wifi interface
#   wifi_scan                 scan once; SIGNAL<TAB>SECURITY<TAB>INUSE<TAB>SSID
#                             lines, one per SSID (its strongest access point),
#                             strongest first. SECURITY is "open" for open
#                             networks, INUSE "*" for the connected one, else
#                             "-" (read with IFS=tab merges empty fields)
#   wifi_current              the connected SSID
#   wifi_known SSID           the backend has a saved profile for SSID
#   wifi_secret SSID          the saved password of SSID (NetworkManager only)
#   wifi_connect SSID [PW]    connect; prints the error on failure
#   wifi_forget SSID          delete the backend's saved profile of SSID
#
# Presets: SSID<TAB>password lines in $WIFI_PRESETS, encrypted with gpg to the
# key $WIFI_KEY, which has a passphrase that gpg-agent caches.
#   presets_need_gpg          exit with an install tip when gpg is missing
#   presets_key               create the key when it doesn't exist (asks for
#                             the new passphrase)
#   presets_read              print the lines (asks for the passphrase when
#                             the agent doesn't have it); nothing if there's
#                             no file yet
#   presets_add SSID PW       add a preset, or replace the one of SSID
#
#   wifi_notify [NOTIFY_SEND_ARGS...] SUMMARY [BODY]
#   wifi_esc TEXT             TEXT with its markup escaped
#   pkg_tip DEBIAN_PKG ARCH_PKG   how to install a package here

WIFI_PRESETS_DIR="$HOME/Documents/local/wifi_presets"
WIFI_PRESETS="$WIFI_PRESETS_DIR/presets.gpg"
WIFI_KEY="wifi-presets"

wifi_notify() {
    command -v notify-send >/dev/null && notify-send -a network "$@"
}

wifi_esc() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

pkg_tip() {
    local id=
    [ -r /etc/os-release ] && id=$(. /etc/os-release; echo "$ID $ID_LIKE")
    case " $id " in
        *" arch "*) echo "sudo pacman -S $2" ;;
        *" debian "* | *" ubuntu "*) echo "sudo apt install $1" ;;
        *) echo "sudo apt install $1 (Debian) or sudo pacman -S $2 (Arch)" ;;
    esac
}

wifi_backend() {
    if command -v nmcli >/dev/null && nmcli -t -f RUNNING general 2>/dev/null | grep -q running; then
        echo nm
    elif command -v iwctl >/dev/null && pgrep -x iwd >/dev/null; then
        echo iwd
    else
        return 1
    fi
}

wifi_need_backend() {
    WIFI_BACKEND=$(wifi_backend) && return
    if command -v nmcli >/dev/null; then
        wifi_notify -u critical "Wifi: NetworkManager isn't running" "sudo systemctl start NetworkManager"
    elif command -v iwctl >/dev/null; then
        wifi_notify -u critical "Wifi: iwd isn't running" "sudo systemctl start iwd"
    else
        wifi_notify -u critical "Wifi: no NetworkManager or iwd" \
            "Install one: $(pkg_tip network-manager networkmanager), or $(pkg_tip iwd iwd)"
    fi
    exit 1
}

wifi_service() {
    case ${WIFI_BACKEND:-$(wifi_backend)} in
        nm) echo NetworkManager ;;
        iwd) echo iwd ;;
        *) return 1 ;;
    esac
}

wifi_dev() {
    local d
    for d in /sys/class/net/*; do
        [ -d "$d/wireless" ] || [ -e "$d/phy80211" ] || continue
        echo "${d##*/}"
        return
    done
    return 1
}

# iwctl prints tables with colors and fixed-width columns: a title, dashes,
# the header, dashes, the rows. iwd_table 'COL1|COL2|...' prints each row as
# MARKER<TAB>COL1<TAB>COL2..., cut at the header's column positions (names
# may have spaces); MARKER is what comes before the first column (">" for the
# connected network)
iwd_table() {
    sed 's/\x1b\[[0-9;]*m//g' | awk -v cols="$1" '
        BEGIN { n = split(cols, name, "|") }
        /^-+ *$/ { d++; next }
        d == 1 { for (i = 1; i <= n; i++) pos[i] = index($0, name[i]); next }
        d >= 2 && NF && pos[1] {
            f = substr($0, 1, pos[1] - 1); gsub(/ /, "", f); out = f
            for (i = 1; i <= n; i++) {
                f = i < n ? substr($0, pos[i], pos[i + 1] - pos[i]) : substr($0, pos[i])
                gsub(/^ +| +$/, "", f); out = out "\t" f
            }
            print out
        }'
}

wifi_scan() {
    local dev
    dev=$(wifi_dev) || return 1
    case ${WIFI_BACKEND:-$(wifi_backend)} in
        nm)
            # SSID last: it may contain colons (--escape no)
            nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list ifname "$dev" --rescan yes 2>/dev/null |
                awk -F: '{
                    ssid = $0; sub(/^[^:]*:[^:]*:[^:]*:/, "", ssid)
                    if (ssid == "") next
                    sec = $3 == "" || $3 == "--" ? "open" : $3
                    if (!(ssid in sig) || $2 + 0 > sig[ssid]) { sig[ssid] = $2 + 0; secs[ssid] = sec }
                    if ($1 == "*") use[ssid] = "*"
                }
                END { for (s in sig) printf "%d\t%s\t%s\t%s\n", sig[s], secs[s], (s in use) ? "*" : "-", s }' |
                sort -t "$(printf '\t')" -k1,1nr
            ;;
        iwd)
            iwctl station "$dev" scan >/dev/null 2>&1
            sleep 3
            # the signal is 0 to 4 stars
            iwctl station "$dev" get-networks 2>/dev/null | iwd_table 'Network name|Security|Signal' |
                awk -F '\t' '$2 != "" {
                    printf "%d\t%s\t%s\t%s\n", gsub(/\*/, "", $4) * 25, $3, index($1, ">") ? "*" : "-", $2
                }' | sort -t "$(printf '\t')" -k1,1nr
            ;;
        *) return 1 ;;
    esac
}

wifi_current() {
    local dev
    dev=$(wifi_dev) || return 1
    case ${WIFI_BACKEND:-$(wifi_backend)} in
        nm) nmcli -t --escape no -f IN-USE,SSID device wifi list ifname "$dev" --rescan no 2>/dev/null |
                sed -n 's/^\*://p' | head -n 1 ;;
        iwd) iwctl station "$dev" show 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
                sed -n 's/^ *Connected network  *//p' | sed 's/ *$//' ;;
    esac
}

wifi_known() {
    case ${WIFI_BACKEND:-$(wifi_backend)} in
        nm)
            local uuid type
            while IFS=: read -r uuid type; do
                [ "$type" = 802-11-wireless ] || continue
                [ "$(nmcli --escape no -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null)" = "$1" ] && return 0
            done < <(nmcli -t -f UUID,TYPE connection show 2>/dev/null)
            return 1 ;;
        iwd)
            iwctl known-networks list 2>/dev/null | iwd_table 'Name|Security|Hidden' |
                awk -F '\t' -v s="$1" '$2 == s { f = 1 } END { exit !f }' ;;
        *) return 1 ;;
    esac
}

wifi_secret() {
    [ "${WIFI_BACKEND:-$(wifi_backend)}" = nm ] || return 1
    local uuid type
    while IFS=: read -r uuid type; do
        [ "$type" = 802-11-wireless ] || continue
        [ "$(nmcli --escape no -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null)" = "$1" ] || continue
        nmcli -s --escape no -g 802-11-wireless-security.psk connection show uuid "$uuid" 2>/dev/null
        return
    done < <(nmcli -t -f UUID,TYPE connection show 2>/dev/null)
    return 1
}

wifi_connect() {
    local dev out
    dev=$(wifi_dev) || { echo "no wifi device"; return 1; }
    case ${WIFI_BACKEND:-$(wifi_backend)} in
        nm)
            # no ifname: it would tie the new profile to this interface name
            if [ -n "$2" ]; then
                out=$(nmcli --wait 40 device wifi connect "$1" password "$2" 2>&1)
            else
                out=$(nmcli --wait 40 device wifi connect "$1" 2>&1)
            fi ;;
        iwd)
            if [ -n "$2" ]; then
                out=$(timeout 40 iwctl --passphrase "$2" station "$dev" connect "$1" 2>&1)
            else
                out=$(timeout 40 iwctl station "$dev" connect "$1" 2>&1)
            fi ;;
        *) echo "no NetworkManager or iwd"; return 1 ;;
    esac || { printf '%s\n' "$out" | sed 's/\x1b\[[0-9;]*m//g' | grep -v '^ *$' | tail -n 1; return 1; }
}

wifi_forget() {
    case ${WIFI_BACKEND:-$(wifi_backend)} in
        nm) nmcli connection delete id "$1" >/dev/null 2>&1 ;;
        iwd) iwctl known-networks "$1" forget >/dev/null 2>&1 ;;
    esac
}

presets_need_gpg() {
    command -v gpg >/dev/null && return
    local tip
    tip="gpg is missing: $(pkg_tip gnupg gnupg)"
    [ -t 2 ] && echo "$tip" >&2
    wifi_notify -u critical "Wifi presets" "$tip"
    exit 1
}

presets_key() {
    gpg --list-secret-keys "$WIFI_KEY" >/dev/null 2>&1 && return
    # asks for the passphrase of the new key (pinentry)
    gpg --quiet --quick-generate-key "$WIFI_KEY" default default never
}

presets_read() {
    [ -f "$WIFI_PRESETS" ] || return 0
    gpg --quiet --no-tty --decrypt "$WIFI_PRESETS" 2>/dev/null
}

presets_add() {
    local old tmp
    umask 077
    presets_key || return 1
    mkdir -p "$WIFI_PRESETS_DIR" && chmod 700 "$WIFI_PRESETS_DIR"
    if [ -f "$WIFI_PRESETS" ]; then
        old=$(presets_read) || return 1
    fi
    tmp="$WIFI_PRESETS.tmp.$$"
    {
        [ -n "$old" ] && printf '%s\n' "$old" | awk -F '\t' -v s="$1" '$1 != s'
        printf '%s\t%s\n' "$1" "$2"
    } | gpg --quiet --no-tty --batch --yes --trust-model always --encrypt -r "$WIFI_KEY" -o "$tmp" &&
        mv "$tmp" "$WIFI_PRESETS" || { rm -f "$tmp"; return 1; }
}
