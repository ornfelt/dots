#!/usr/bin/env bash
set -euo pipefail

# Names treated as path-list variables (colon-separated)
path_list_vars=("PATH" "MANPATH" "INFOPATH" "XDG_DATA_DIRS" "XDG_CONFIG_DIRS")

usage() {
  cat <<'EOF'
Usage:
  search_env.sh <name>            # Print value for given env var
  search_env.sh -Search <text>    # Search in names and values (substring)
  search_env.sh -List             # List all env vars
Examples:
  ./search_env.sh USERNAME
  ./search_env.sh "PATH"
  ./search_env.sh -Search python
  ./search_env.sh -List
EOF
}

is_path_list_var() {
  local name="$1"
  for pv in "${path_list_vars[@]}"; do
    [[ "$name" == "$pv" ]] && return 0
  done
  return 1
}

print_path_entries() {
  local name="$1" value="$2"
  local i=0
  printf '%s:\n' "$name"
  while IFS= read -r -d ':' p || [[ -n "$p" ]]; do
    [[ -z "$p" ]] && continue
    i=$((i + 1))
    printf '  [%d] %s\n' "$i" "$p"
  done <<< "$value:"
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

# Gather all environment variables, sorted by name
declare -a env_keys env_values
while IFS='=' read -r k v; do
  [[ -z "$k" ]] && continue
  env_keys+=("$k")
  env_values+=("$v")
done < <(env -0 | tr '\0' '\n' | sort)

# ── List mode ────────────────────────────────────────────────────────
if [[ $list -eq 1 ]]; then
  # Print non-path-list vars first
  for i in "${!env_keys[@]}"; do
    if ! is_path_list_var "${env_keys[$i]}"; then
      printf '%s: %s\n' "${env_keys[$i]}" "${env_values[$i]}"
    fi
  done

  # Print path-list vars at the end, expanded
  printed_sep=0
  for i in "${!env_keys[@]}"; do
    if is_path_list_var "${env_keys[$i]}"; then
      if [[ $printed_sep -eq 0 ]]; then
        printf '\n'
        printed_sep=1
      fi
      print_path_entries "${env_keys[$i]}" "${env_values[$i]}"
    fi
  done
  exit 0
fi

# ── Search mode ──────────────────────────────────────────────────────
if [[ -n "$search" ]]; then
  found=0

  # Standard matches on non-path-list vars
  for i in "${!env_keys[@]}"; do
    k="${env_keys[$i]}"
    v="${env_values[$i]}"
    if is_path_list_var "$k"; then
      continue
    fi
    if [[ "$k" == *"$search"* || "$v" == *"$search"* ]]; then
      printf '%s: %s\n' "$k" "$v"
      found=1
    fi
  done

  # Search inside path-list vars (individual entries)
  for i in "${!env_keys[@]}"; do
    k="${env_keys[$i]}"
    v="${env_values[$i]}"
    if ! is_path_list_var "$k"; then
      continue
    fi
    # Check if var name itself matches
    name_match=0
    [[ "$k" == *"$search"* ]] && name_match=1

    # Collect individual path hits
    hits=()
    while IFS= read -r -d ':' p || [[ -n "$p" ]]; do
      [[ -z "$p" ]] && continue
      if [[ "$p" == *"$search"* ]]; then
        hits+=("$p")
      fi
    done <<< "$v:"

    if [[ ${#hits[@]} -gt 0 ]]; then
      printf '\n%s (matching entries):\n' "$k"
      local_i=0
      for h in "${hits[@]}"; do
        local_i=$((local_i + 1))
        printf '  [%d] %s\n' "$local_i" "$h"
      done
      found=1
    elif [[ $name_match -eq 1 ]]; then
      # Name matched but no individual path hit; show expanded
      printf '\n'
      print_path_entries "$k" "$v"
      found=1
    fi
  done

  if [[ $found -eq 0 ]]; then
    printf "No entries matching search string: '%s'\n" "$search"
  fi
  exit 0
fi

# ── Default mode: get value for a specific env var ───────────────────
if [[ -n "$key" ]]; then
  for i in "${!env_keys[@]}"; do
    if [[ "${env_keys[$i]}" == "$key" ]]; then
      if is_path_list_var "$key"; then
        print_path_entries "$key" "${env_values[$i]}"
      else
        printf '%s\n' "${env_values[$i]}"
      fi
      exit 0
    fi
  done
  printf "Environment variable not found: '%s'\n" "$key"
  exit 1
fi

# ── No arguments: brief usage ───────────────────────────────────────
usage
exit 0
