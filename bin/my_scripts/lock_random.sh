#!/bin/sh
# Lock the screen. Uses i3lock with a random jpg/jpeg/png directly in
# ~/Pictures/lockscreens (subdirectories are not searched), or plain i3lock
# when there is no image. Images with "debian" in the name (any case) are only
# used on Debian, ones with "arch" only on Arch Linux; all others are always
# candidates.
#
# Usage: lock_random.sh [--pause] [--mute] [--suspend] [i3lock args...]
#   --pause    pause music before locking (every MPRIS player, e.g. spotify,
#              browsers, mpv; and mpd); players that aren't playing stay as is
#   --mute     mute the volume (amixer) before locking
#   --suspend  suspend once the screen is locked; never if locking failed
#
# i3lock only reads PNG and doesn't scale, so the image is converted to a PNG
# filling each monitor, cached in ~/.cache/lock_random/ (redone if the source
# or the monitor layout changes).
#
# Without i3lock, or if it fails, the other lockers below are tried in order
# (without an image). Problems are shown as notifications (dunst).

suspend=""
mute=""
pause=""
while :; do
    case "$1" in
        --suspend) suspend=1 ;;
        --pause) pause=1 ;;
        --mute) mute=1 ;;
        *) break ;;
    esac
    shift
done

dir="$HOME/Pictures/lockscreens"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/lock_random"

notify() { # urgency message
    notify-send -u "$1" -a lock_random "Lock screen" "$2" >/dev/null 2>&1 ||
        echo "lock_random: $2" >&2
}

if err=$(mktemp); then
    trap 'rm -f "$err"' EXIT
else
    err=/dev/null
fi
tried=""

locked() {
    [ -n "$suspend" ] && systemctl suspend
    exit 0
}

# Run a locker that returns once the screen is locked (i3lock forks only after
# it has grabbed the screen), if installed; exit when it locked
lock_with() { # command [args...]
    command -v "$1" >/dev/null || return 0
    tried="$tried $1"
    "$@" 2>"$err" && locked
    notify critical "$1 failed to lock: $(tail -n 1 "$err")"
}

# The same for a locker that stays in the foreground until unlocked. To
# suspend, it runs in the background: still running after 2 seconds means it
# has grabbed the screen (on failure, they give up within about a second).
lock_with_fg() { # command [args...]
    command -v "$1" >/dev/null || return 0
    tried="$tried $1"
    if [ -z "$suspend" ]; then
        "$@" 2>"$err" && exit 0
    else
        "$@" 2>"$err" &
        pid=$!
        sleep 2
        if kill -0 "$pid" 2>/dev/null; then
            systemctl suspend
            wait "$pid"
            exit 0
        fi
        wait "$pid" && exit 0
    fi
    notify critical "$1 failed to lock: $(tail -n 1 "$err")"
}

# The image for i3lock, or empty for none
lock_image() {
    distro=$(. /etc/os-release 2>/dev/null; echo "$ID")
    pic=$(find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null |
        awk -v distro="$distro" '
            { name = tolower($0); sub(/.*\//, "", name) }
            name ~ /debian/ && distro != "debian" { next }
            name ~ /arch/   && distro != "arch"   { next }
            { print }' |
        shuf -n 1)
    [ -n "$pic" ] || return

    # Monitors as WxH+X+Y, one per line (xrandr's "1920/309x1080/173+0+0");
    # without xrandr, the whole screen as one
    mons=$(xrandr --listactivemonitors 2>/dev/null |
        awk 'NR > 1 { split($3, g, /[\/x+]/); print g[1] "x" g[3] "+" g[5] "+" g[6] }')
    [ -n "$mons" ] || mons=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ { print $2 "+0+0"; exit }')
    if [ -z "$mons" ]; then
        problem="couldn't get the screen size (are xrandr/xdpyinfo installed?)"
    elif ! command -v magick >/dev/null; then
        problem="ImageMagick (magick) is not installed"
    else
        png="$cache/$(basename "$pic")-$(echo "$mons" | awk '{ printf "%s%s", sep, $0; sep = "_" }').png"
        if [ ! -f "$png" ] || [ "$pic" -nt "$png" ]; then
            mkdir -p "$cache"
            # The image fills each monitor, on a black canvas covering them all
            size=$(echo "$mons" | awk -F '[x+]' '
                $1 + $3 > w { w = $1 + $3 } $2 + $4 > h { h = $2 + $4 } END { print w "x" h }')
            set -- -size "$size" xc:black
            for m in $mons; do
                set -- "$@" "(" "$pic" -resize "${m%%+*}^" -gravity center -extent "${m%%+*}" ")" \
                    -gravity northwest -geometry "+${m#*+}" -composite
            done
            if magick "$@" "png:$png.tmp" 2>"$err"; then
                mv -f "$png.tmp" "$png"
            else
                rm -f "$png.tmp" "$png"
                notify normal "Converting $(basename "$pic") failed, locking without an image: $(tail -n 1 "$err")"
                return
            fi
        fi
        echo "$png"
        return
    fi

    # Can't convert: the original only works (unscaled) if it's a PNG
    case "$pic" in
        *.[Pp][Nn][Gg])
            notify normal "$problem; using $(basename "$pic") unscaled"
            echo "$pic" ;;
        *)
            notify normal "$problem; locking without an image" ;;
    esac
}

# MPRIS Pause does nothing when a player isn't playing. --print-reply waits
# for the player, so it has paused before a suspend
if [ -n "$pause" ]; then
    for player in $(dbus-send --session --print-reply --dest=org.freedesktop.DBus \
            /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null |
            grep -o 'org\.mpris\.MediaPlayer2\.[^"]*'); do
        dbus-send --session --print-reply --reply-timeout=1000 --dest="$player" \
            /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause >/dev/null 2>&1
    done
    command -v mpc >/dev/null && mpc -q pause
fi

if [ -n "$mute" ]; then
    if amixer -q set Master mute 2>"$err"; then
        pkill -44 -x 'dwmblocks[rc]?' # refresh the volume block
    else
        notify normal "Muting failed: $(tail -n 1 "$err")"
    fi
fi

if command -v i3lock >/dev/null; then
    img=$(lock_image)
    [ -n "$img" ] && set -- "$@" -i "$img"
    lock_with i3lock "$@"
else
    notify normal "i3lock is not installed; trying other lockers"
fi

lock_with_fg betterlockscreen -l
lock_with_fg slock
lock_with_fg xsecurelock
lock_with_fg xlock -mode blank
lock_with xscreensaver-command -lock
lock_with light-locker-command -l
lock_with dm-tool lock

[ -n "$suspend" ] && not_suspending=" Not suspending."
if [ -z "$tried" ]; then
    notify critical "No screen locker installed (i3lock, betterlockscreen, slock, xsecurelock, xlock, xscreensaver, light-locker, dm-tool). The screen is NOT locked.$not_suspending"
else
    notify critical "The screen is NOT locked: all lockers failed (${tried# }).$not_suspending"
fi
exit 1
