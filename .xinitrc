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

#exec i3
#exec awesome
exec dwm &
# To start with logging:
# startx > $HOME/startx.log 2>&1
# or:
# startx >> ~/.startx_dwm.log 2>&1 &

sh ~/.dwm/autostart.sh &
#sh ~/.dwm/autostart.sh >> ~/.dwm/autostart.log 2>&1 &


if picom --help | grep -q "\-\-animations"; then
    picom --animations
else
    picom
fi

