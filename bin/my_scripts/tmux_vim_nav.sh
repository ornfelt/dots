#!/usr/bin/env bash

direction="$1"
check_both=true # Check both directions or not

pane_status=""
pane_cmd=""
vim_keys=""

# Determine primary direction params
case "$direction" in
  h)
    pane_status=$(tmux display-message -p '#{pane_at_left}')
    pane_cmd="select-pane -L"
    vim_keys="C-w h"
    ;;
  j)
    pane_status=$(tmux display-message -p '#{pane_at_bottom}')
    pane_cmd="select-pane -D"
    vim_keys="C-w j"
    ;;
  k)
    pane_status=$(tmux display-message -p '#{pane_at_top}')
    pane_cmd="select-pane -U"
    vim_keys="C-w k"
    ;;
  l)
    pane_status=$(tmux display-message -p '#{pane_at_right}')
    pane_cmd="select-pane -R"
    vim_keys="C-w l"
    ;;
  *)
    # If invalid direction, just exit
    exit 1
    ;;
esac

is_zoomed=$(tmux list-panes -F '#F' | grep -q 'Z' && echo 1 || echo 0)

# If check_both is true, we also determine the opposite direction's pane status.
if [ "$check_both" = true ]; then
    case "$direction" in
      h)
        # Opposite direction is right
        opposite_pane_status=$(tmux display-message -p '#{pane_at_right}')
        ;;
      l)
        # Opposite direction is left
        opposite_pane_status=$(tmux display-message -p '#{pane_at_left}')
        ;;
      j)
        # Opposite direction is top
        opposite_pane_status=$(tmux display-message -p '#{pane_at_top}')
        ;;
      k)
        # Opposite direction is bottom
        opposite_pane_status=$(tmux display-message -p '#{pane_at_bottom}')
        ;;
    esac
else
    opposite_pane_status=1 # If we're not checking both, set to 1 (blocked) so it doesn't affect logic.
fi

# Now we decide what to do:
# We move via tmux pane command if:
# - not zoomed
# - and (primary direction is available or opposite direction is available)
#
# If both directions are blocked or zoomed, send vim keys.
if [ "$is_zoomed" -eq 0 ] && ( [ "$pane_status" -eq 0 ] || [ "$opposite_pane_status" -eq 0 ] ); then
    tmux $pane_cmd
else
    tmux send-keys $vim_keys
fi

