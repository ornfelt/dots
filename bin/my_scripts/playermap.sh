#!/usr/bin/env bash

# grab and normalize inputs
srv="$1"
lang="${2:-py}"

if [[ -z $srv ]]; then
  echo "Usage: playermap <server> [js|ts|py|php]"
  exit 1
fi

case "$srv" in
  acore) norm=acore ;;
  tcore) norm=tcore ;;
  cmangos) norm=cmangos ;;
  cmangos-tbc|mangos-tbc|tbc) norm=cmangos-tbc ;;
  vmangos) norm=vmangos ;;
  mangoszero|mangos0) norm=mangoszero ;;
  *)
    echo "Error: Unknown server '$srv'"
    exit 1
    ;;
esac

export SELECTED_SERVER="$norm"
base="$HOME/Code2/Python/wander_nodes_util"

# PHP only on acore/tcore
if [[ "$lang" == php ]]; then
  if [[ $norm != acore && $norm != tcore ]]; then
    echo "Error: PHP only supported for acore/tcore."
    exit 1
  fi
  echo "Launching ${norm^} PHP playermap on port 8000..."
  ip=$(ip addr show | grep -v 'inet6' \
      | grep -v 'inet 127' \
      | grep 'inet ' \
      | head -n1 \
      | awk '{print $2}' \
      | cut -d/ -f1)
  cd "$HOME/Code2/Python/wander_nodes_util/${norm}_map/playermap" \
    && php -S "${ip}:8000"
  exit $?
fi

# non-PHP
if [[ $norm == acore || $norm == tcore ]]; then
  case "$lang" in
    js) cd "$base/js_map" && echo " -> JS dev" && npm run dev ;;
    ts) cd "$base/ts_map" && echo " -> TS watch" && npm run dev:watch ;;
    py) cd "$base/py_map" && echo " -> Python app" && /usr/bin/python3 app.py ;;
    *) echo "Error: Unsupported language '$lang'" && exit 1 ;;
  esac
else
  case "$lang" in
    js) cd "$base/js_map_tbc" && echo " -> JS dev (TBC)" && npm run dev ;;
    ts) cd "$base/ts_map_tbc" && echo " -> TS watch (TBC)" && npm run dev:watch ;;
    py) cd "$base/py_map" && echo " -> Python cmangos" && /usr/bin/python3 app_cmangos.py ;;
    *) echo "Error: Unsupported language '$lang' for mangos" && exit 1 ;;
  esac
fi

