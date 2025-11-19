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
#systemctl --user import-environment DISPLAY

exec clipmenud &

#exec i3
#exec awesome
exec dwm &
# To start with logging:
# startx > $HOME/startx.log 2>&1
# or:
# startx >> ~/.startx_dwm.log 2>&1 &

sh ~/.dwm/autostart.sh &
#sh ~/.dwm/autostart.sh >> ~/.dwm/autostart.log 2>&1 &

xset s off
xset -dpms

if picom --help | grep -q "\-\-animations"; then
    picom --animations
else
    picom
fi

