#! /bin/sh
WHEREAMI=$(cat /tmp/whereami)

case $1 in
	# "st") /bin/sh -c 'cd "$WHEREAMI" ; "st"' ;;
	"st") st -d $WHEREAMI ;;
	"urxvt") urxvt -cd "$WHEREAMI" ;;
esac

