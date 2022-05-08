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
   
echo " ${*:-%artist% - %title%}" | sed "s/%artist%/$artist/g;s/%title%/$title/g;s/%album%/$album/g"i | sed "s/\&/\&/g" | sed "s#\/#\/#g"
}

case $BLOCK_BUTTON in
	1) rofi -theme "~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi" -e "Spotify clicked" ;;
	2) rofi -theme "~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi" -e "Spotify clicked 2" ;;
	3) pkill -RTMIN+12 dwmblocks ;;
	4) rofi -theme "~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi" -e "Spotify clicked 4" ;;
	5) rofi -theme "~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi" -e "Spotify clicked 5" ;;
	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
esac

main "$@"
