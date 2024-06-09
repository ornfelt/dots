#! /bin/sh
WHEREAMI=$(cat /tmp/whereami)

case $1 in
	# "st") /bin/sh -c 'cd "$WHEREAMI" ; "st"' ;;
	"st") st -d $WHEREAMI || st ;;
	"urxvt") urxvt -cd "$WHEREAMI" || urxvt ;;
	"alacritty") alacritty --working-directory "$WHEREAMI" || alacritty ;;
esac

