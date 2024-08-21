#! /bin/sh

WHEREAMI=$(cat /tmp/whereami)

# Check if the directory exists
if [ -d "$WHEREAMI" ]; then
    case $1 in
        "st") st -d "$WHEREAMI" || st ;;
        "urxvt") urxvt -cd "$WHEREAMI" || urxvt ;;
        "alacritty") alacritty --working-directory "$WHEREAMI" || alacritty ;;
        "wezterm") wezterm start --cwd "$WHEREAMI" || wezterm ;;
    esac
else
    case $1 in
        "st") st ;;
        "urxvt") urxvt ;;
        "alacritty") alacritty ;;
        "wezterm") wezterm ;;
    esac
fi

