#!/usr/bin/env bash
set -euo pipefail

IMG="$HOME/Pictures/Wallpapers/space.jpg"

X=2
Y=1
W=80
H=24

FIFO="$(mktemp -u)"
mkfifo "$FIFO"

cleanup() {
  rm -f "$FIFO"
}
trap cleanup EXIT

# Start ueberzugpp reading from the FIFO
#ueberzugpp layer --parser json < "$FIFO" &
ueberzug layer --parser json < "$FIFO" &
UZ_PID=$!

# IMPORTANT: keep the write-end open so ueberzugpp doesn't get EOF and exit
exec 3> "$FIFO"

# Give it a tiny moment to start
sleep 0.05

# Add image
printf '%s\n' \
  "{\"action\":\"add\",\"identifier\":\"wall\",\"path\":\"$IMG\",\"x\":$X,\"y\":$Y,\"width\":$W,\"height\":$H,\"scaler\":\"contain\"}" \
  >&3

# Wait for a keypress (always from the real terminal)
read -r -n 1 -s -p "Press any key to close..." </dev/tty
echo

# Remove image
printf '%s\n' \
  "{\"action\":\"remove\",\"identifier\":\"wall\"}" \
  >&3

# Close writer fd, then stop ueberzugpp
exec 3>&-
kill "$UZ_PID" 2>/dev/null || true

