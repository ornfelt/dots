#!/bin/sh

main() {
  if ! pgrep -x spotify >/dev/null; then
    echo ""; exit
  fi  

  cmd="org.freedesktop.DBus.Properties.Get"
  domain="org.mpris.MediaPlayer2"
  path="/org/mpris/MediaPlayer2"

  meta=$(dbus-send --print-reply --dest=${domain}.spotify \
    /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:${domain}.Player string:Metadata)

  artist=$(echo "$meta" | sed -nr '/xesam:artist"/,+2s/^ +string "(.*)"$/\1/p' | tail -1  | sed 's/\&/\\&/g' | sed 's#\/#\\/#g')
  album=$(echo "$meta" | sed -nr '/xesam:album"/,+2s/^ +variant +string "(.*)"$/\1/p' | tail -1| sed 's/\&/\\&/g'| sed 's#\/#\\/#g')
  title=$(echo "$meta" | sed -nr '/xesam:title"/,+2s/^ +variant +string "(.*)"$/\1/p' | tail -1 | sed 's/\&/\\&/g'| sed 's#\/#\\/#g')
   
echo " ${*:-%artist% - %title%} " | sed "s/%artist%/$artist/g;s/%title%/$title/g;s/%album%/$album/g"i | sed "s/\&/\&/g" | sed "s#\/#\/#g"
}

# Sends an MPRIS command (PlayPause, Next, Previous) to spotify
player() {
  dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 \
    "org.mpris.MediaPlayer2.Player.$1" >/dev/null
}

# After changing track, give spotify a moment to update its metadata before
# dwmblocks refreshes the block
# Left click: one notification at a time, clicks are ignored while it is
# loading or shown (the lock is held until notify-send --wait returns)
case $BLOCK_BUTTON in
	1) exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sb-spotify.lock"; flock -n 9 || exit 0
	   notify-send --wait "Spotify" "$(main "%title%\n%artist%\n%album%")" ;;
	2) player PlayPause ;;
	3) pkill -RTMIN+12 -x 'dwmblocksr?' ;;
	4) player Previous; sleep 0.5 ;;
	5) player Next; sleep 0.5 ;;
	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
esac

main "$@"
