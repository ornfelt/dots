#!/usr/bin/env bash
set -euo pipefail

configPath="/home/jonas/Documents/local/config.txt"

usage() {
  cat <<'EOF'
Usage:
  search_conf.sh <key>            # Print value for given key
  search_conf.sh -Search <text>   # Search in keys and values (substring)
  search_conf.sh -List            # List all key/value pairs

Examples:
  ./search_conf.sh my_username
  ./search_conf.sh "my_username"
  ./search_conf.sh -Search local
  ./search_conf.sh -List
EOF
}

shopt -s extglob
trim() {
  local s="$1"
  s="${s##+([[:space:]])}"
  s="${s%%+([[:space:]])}"
  printf '%s' "$s"
}

key=""
search=""
list=0
extra=()

# Parse args (case-insensitive for -list / -search)
while [[ $# -gt 0 ]]; do
  arg="$1"
  lower="${arg,,}"   # bash lowercase (requires bash 4+)

  case "$lower" in
    -list|--list)
      list=1
      shift
      ;;
    -search|--search)
      shift
      if [[ $# -eq 0 || "${1:-}" == -* ]]; then
        echo "Missing argument for -Search" >&2
        exit 1
      fi
      search="$1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$key" ]]; then
        key="$arg"
      else
        extra+=("$arg")
      fi
      shift
      ;;
  esac
done

if [[ ${#extra[@]} -gt 0 ]]; then
  echo "Unexpected extra argument(s): ${extra[*]}" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$configPath" ]]; then
  echo "Config file not found: $configPath" >&2
  exit 1
fi

declare -a keys values
while IFS= read -r line || [[ -n "$line" ]]; do
  t="$(trim "$line")"
  [[ -z "$t" ]] && continue
  [[ "${t:0:1}" == "#" ]] && continue
  [[ "$t" != *:* ]] && continue

  k="$(trim "${t%%:*}")"
  v="$(trim "${t#*:}")"
  [[ -z "$k" ]] && continue

  keys+=("$k")
  values+=("$v")
done < "$configPath"

if [[ $list -eq 1 ]]; then
  for i in "${!keys[@]}"; do
    printf '%s: %s\n' "${keys[$i]}" "${values[$i]}"
  done
  exit 0
fi

if [[ -n "$search" ]]; then
  found=0
  for i in "${!keys[@]}"; do
    k="${keys[$i]}"
    v="${values[$i]}"
    if [[ "$k" == *"$search"* || "$v" == *"$search"* ]]; then
      printf '%s: %s\n' "$k" "$v"
      found=1
    fi
  done

  if [[ $found -eq 0 ]]; then
    printf "No entries matching search string: '%s'\n" "$search"
  fi
  exit 0
fi

if [[ -n "$key" ]]; then
  for i in "${!keys[@]}"; do
    if [[ "${keys[$i]}" == "$key" ]]; then
      printf '%s\n' "${values[$i]}"
      exit 0
    fi
  done
  printf "Key not found: '%s'\n" "$key"
  exit 1
fi

usage
exit 0

