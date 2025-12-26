#!/bin/bash
set -euo pipefail

# Ensure the environment variable `code_root_dir` is set
if [[ -z "${code_root_dir:-}" ]]; then
  echo "Error: Environment variable 'code_root_dir' is not set."
  exit 1
fi

# Binary directory (match your PS: build/bin/Release)
#BINARY_DIR="${code_root_dir}/Code/ml/llama.cpp/build/bin/Release"
BINARY_DIR="${code_root_dir}/Code/ml/llama.cpp/build/bin"

# Check if the binary directory exists
if [[ ! -d "$BINARY_DIR" ]]; then
  echo "Error: Binary directory not found at $BINARY_DIR"
  exit 1
fi

# Expand a leading "~" to $HOME (bash won't expand "~" inside variables by default)
expand_tilde() {
  local p="$1"
  if [[ "$p" == "~"* ]]; then
    printf '%s\n' "${p/#\~/$HOME}"
  else
    printf '%s\n' "$p"
  fi
}

# Prefer primary IPv4
get_local_ipv4_alt() {
  local ip=""
  # Best effort: default route source IP
  ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' || true)"
  if [[ -n "$ip" ]]; then
    echo "$ip"
    return
  fi
  # Fallback: first non-loopback inet
  ip="$(ip -4 addr show 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {sub(/\/.*/, "", $2); print $2; exit}' || true)"
  echo "${ip:-127.0.0.1}"
}

get_local_ipv4() {
  local ip=""
  ip="$(ip addr show \
        | grep -v 'inet6' \
        | grep -v 'inet 127' \
        | grep 'inet' \
        | head -n 1 \
        | awk '{print $2}' \
        | cut -d/ -f1 \
        || true)"

  echo "${ip:-127.0.0.1}"
}

# List of potential model paths
MODELPATHS=(
  "../../../models/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
  "../../../models/meta-llama-3.1-8b-instruct-q4_k_m-gguf/meta-llama-3.1-8b-instruct-q4_k_m.gguf"
  "../../../models/Meta-Llama-3.1-8B/Meta-Llama-3.1-8B-ggml-model-Q4_K_M.gguf"

  "$HOME/Documents/local/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf"
  "$HOME/Documents/local/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf"
  "$HOME/Documents/local/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
  "$HOME/Documents/local/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
  "$HOME/Documents/local/ai/models/llama3.2-1b-Instruct.gguf"
  "$HOME/Documents/local/ai/models/llama3.2-3b-Instruct.gguf"

  "/media/my_files/my_docs/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf"
  "/media/my_files/my_docs/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf"
  "/media/my_files/my_docs/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
  "/media/my_files/my_docs/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
  "/media/my_files/my_docs/ai/models/llama3.2-1b-Instruct.gguf"
  "/media/my_files/my_docs/ai/models/llama3.2-3b-Instruct.gguf"

  "/media2/my_files/my_docs/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf"
  "/media2/my_files/my_docs/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf"
  "/media2/my_files/my_docs/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
  "/media2/my_files/my_docs/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
  "/media2/my_files/my_docs/ai/models/llama3.2-1b-Instruct.gguf"
  "/media2/my_files/my_docs/ai/models/llama3.2-3b-Instruct.gguf"

  "/mnt/new/2024/llama/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
)

# Check which models exist and collect them
AVAILABLE_MODELS=()
echo "Checking available models:"
for path in "${MODELPATHS[@]}"; do
  path="$(expand_tilde "$path")"

  # Absolute path -> use directly; otherwise resolve relative to $BINARY_DIR
  if [[ "$path" = /* ]]; then
    resolved_path="$path"
  else
    resolved_path="$BINARY_DIR/$path"
  fi

  if [[ -f "$resolved_path" ]]; then
    echo "- Model available: $resolved_path"
    AVAILABLE_MODELS+=("$resolved_path")
  fi
done

if [[ ${#AVAILABLE_MODELS[@]} -eq 0 ]]; then
  echo "Error: No model files found in the provided paths."
  exit 1
fi

usage() {
  echo "Usage: .llama [cli|chat|server|serverlocal|local|localhost|list|help] [model_index]"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

COMMAND="$1"
MODEL_IDX="${2:-0}"

# Validate the model index (only needed for non-list/help)
is_number='^[0-9]+$'

# Common args
COMMON_ARGS=(--threads "$(nproc)" -c 2048)

case "${COMMAND,,}" in
  list)
    echo
    echo "Available models (found on disk):"
    for i in "${!AVAILABLE_MODELS[@]}"; do
      echo "  [$i] ${AVAILABLE_MODELS[$i]}"
    done
    echo
    echo "Usage examples:"
    echo "  .llama cli 0"
    echo "  .llama server 1"
    exit 0
    ;;
  help)
    usage
    echo "Commands:"
    echo "  cli         Run llama in CLI mode"
    echo "  chat        Alias for CLI mode"
    echo "  server      Run llama server bound to your primary IPv4"
    echo "  serverlocal Run llama server bound to localhost"
    echo "  local       Alias for serverlocal"
    echo "  localhost   Alias for serverlocal"
    echo "  list        List available models (existing files only)"
    echo "  help        Show this help message"
    echo "  model_index Optional, 0-based index to select model."
    exit 0
    ;;
esac

if ! [[ "$MODEL_IDX" =~ $is_number ]] || [[ "$MODEL_IDX" -ge "${#AVAILABLE_MODELS[@]}" ]]; then
  echo "Error: Invalid model index '$MODEL_IDX'. Valid indices: 0 to $((${#AVAILABLE_MODELS[@]} - 1))"
  exit 1
fi

MODEL_PATH="${AVAILABLE_MODELS[$MODEL_IDX]}"
echo "Selected model: $MODEL_PATH"

case "${COMMAND,,}" in
  cli|chat)
    echo "Running llama in CLI mode..."
    "$BINARY_DIR/llama-cli" -m "$MODEL_PATH" "${COMMON_ARGS[@]}" -cnv -p "You are a helpful assistant"
    ;;
  server|serverlocal|local|localhost)
    is_local=0
    if [[ "${COMMAND,,}" =~ ^(serverlocal|local|localhost)$ ]]; then
      is_local=1
    fi

    if [[ $is_local -eq 1 ]]; then
      host_ip="localhost"
    else
      #host_ip="$(get_local_ipv4_alt)"
      host_ip="$(get_local_ipv4)"
    fi

    echo "Running llama in Server mode on host $host_ip ..."
    "$BINARY_DIR/llama-server" -m "$MODEL_PATH" "${COMMON_ARGS[@]}" --host "$host_ip"
    ;;
  *)
    echo "Unknown command: $COMMAND"
    usage
    exit 1
    ;;
esac
