#! /bin/sh

WHEREAMI=$(cat /tmp/whereami 2>/dev/null || echo "")

DEFAULT_TERMINAL="wezterm"
DEFAULT_FILE_EXPLORER="yazi"

TERMINAL=${1:-$DEFAULT_TERMINAL}
FILE_EXPLORER=${2:-$DEFAULT_FILE_EXPLORER}

# Validate dir
if [ ! -d "$WHEREAMI" ]; then
    WHEREAMI="$HOME" # Fallback
fi

# Launch specified terminal and file explorer
case $TERMINAL in
    "st")
        case $FILE_EXPLORER in
            "ranger") st -e ranger -r ~/.config/ranger "$WHEREAMI" ;;
            "yazi") st -e yazi "$WHEREAMI" ;;
            *) echo "Unsupported file explorer: $FILE_EXPLORER" ;;
        esac
        ;;
    "urxvt")
        case $FILE_EXPLORER in
            "ranger") urxvt -e ranger -r ~/.config/ranger "$WHEREAMI" ;;
            "yazi") urxvt -e yazi "$WHEREAMI" ;;
            *) echo "Unsupported file explorer: $FILE_EXPLORER" ;;
        esac
        ;;
    "alacritty")
        case $FILE_EXPLORER in
            "ranger") alacritty --working-directory "$WHEREAMI" -e ranger -r ~/.config/ranger "$WHEREAMI" ;;
            "yazi") alacritty --working-directory "$WHEREAMI" -e yazi "$WHEREAMI" ;;
            *) echo "Unsupported file explorer: $FILE_EXPLORER" ;;
        esac
        ;;
    "wezterm")
        case $FILE_EXPLORER in
            "ranger") wezterm start --cwd "$WHEREAMI" -- ranger -r ~/.config/ranger "$WHEREAMI" ;;
            "yazi") wezterm start --cwd "$WHEREAMI" -- yazi "$WHEREAMI" ;;
            *) echo "Unsupported file explorer: $FILE_EXPLORER" ;;
        esac
        ;;
    *)
        echo "Unsupported terminal: $TERMINAL"
        ;;
esac

