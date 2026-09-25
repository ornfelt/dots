#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi
if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi
if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

setxkbmap -option caps:escape

# Multiple monitors
# xrandr --output eDP-1 --auto --primary --output HDMI-1 --auto --right-of eDP-1
# Multiple monitors (PC)
#xrandr --output DP-3 --primary --mode 1920x1080 --rate 240.00 --output DP-1 --mode 1920x1080 --rate 144.00 --right-of DP-3

#xrdb ~/.Xresources

xhost si:localuser:root
# Give services that D-Bus starts through systemd (e.g. dunst for notify-send)
# the X display, otherwise they can't open it. Arch does this in xinitrc.d,
# Debian doesn't.
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
# (Re)start dunst on this X server. When X restarts (e.g. switching dwm/dwmr),
# a notification sent in between can D-Bus-start dunst before the new display
# is up; it then fails ("Cannot open X11 display") and the statusbar popups'
# notify-send --wait hang, so weather/battery/cputemp clicks show nothing.
systemctl --user reset-failed dunst.service 2>/dev/null
systemctl --user restart dunst.service &

# set some env vars
# Terminal for the statusbar scripts' click actions (dwmblocks inherits it via dwm)
export TERMINAL="wezterm"
export my_notes_path="$HOME/Documents/my_notes"
export code_root_dir="$HOME"

# Opt the wezterm integrations (nvim_server.lua, bg_status.lua) into linux; must be session-level, not .zshrc
export WEZ_ENABLE_ON_LINUX=0
#export WEZ_ENABLE_ON_LINUX=1

# Headless nvim servers, one switch for wezterm + .zshrc `vim` + the PowerShell profile; 0/off/false/no = off
export WEZ_NVIM_SERVERS=0
#export WEZ_NVIM_SERVERS=1

exec clipmenud &

# Disable screen blanking / DPMS / bell (must be BEFORE the exec below,
# since `exec` replaces this shell and nothing after it would run)
xset s off
xset s noblank
xset -dpms
xset -b

# Window manager to start: awesome | i3 | dwmr | dwm (anything else falls back to dwm).
# Override for one session without editing this file: WM=awesome startx
#WM="${WM:-dwm}"
WM="${WM:-dwmr}"
#WM="${WM:-awesome}"

# To start with logging:
# startx > $HOME/startx.log 2>&1
# or:
# startx >> ~/.startx_dwm.log 2>&1 &

# The WM must be exec'd as the last, foreground command: quitting it ends the
# X session.
case "$WM" in
  awesome|awesomewm)
    # awesome starts picom etc. itself (run_once in rc.lua)
    exec awesome
    ;;
  i3)
    exec i3
    ;;
  dwmr)
    # dwmr: the Rust port of dwm (config in ~/.config/dwmr/config.toml)
    sh ~/.dwm/autostart.sh &
    picom -b
    exec dwmr
    ;;
  *)
    sh ~/.dwm/autostart.sh &
    #sh ~/.dwm/autostart.sh >> ~/.dwm/autostart.log 2>&1 &

    # -b: run picom in the background so the session is tied to dwm, not picom
    picom -b

    exec dwm
    ;;
esac

