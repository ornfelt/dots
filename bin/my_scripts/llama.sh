#!/bin/bash

# Ensure the environment variable `code_root_dir` is set
if [[ -z "$code_root_dir" ]]; then
    echo "Error: Environment variable 'code_root_dir' is not set."
    exit 1
fi

# Define the binary directory based on `code_root_dir`
BINARY_DIR="${code_root_dir}/Code/ml/llama.cpp/build/bin"

# Check if the binary directory exists
if [[ ! -d "$BINARY_DIR" ]]; then
    echo "Error: Binary directory not found at $BINARY_DIR"
    exit 1
fi

# Define a list of potential model paths
MODELPATHS=(
    "../../../models/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
    "../../../models/meta-llama-3.1-8b-instruct-q4_k_m-gguf/meta-llama-3.1-8b-instruct-q4_k_m.gguf"
    "../../../models/Meta-Llama-3.1-8B/Meta-Llama-3.1-8B-ggml-model-Q4_K_M.gguf"
    "$HOME/Documents/local/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    "$HOME/Documents/local/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf"
    "$HOME/Documents/local/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
    "$HOME/Documents/local/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
    "/media/my_files/my_docs/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    "/media/my_files/my_docs/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf"
    "/media/my_files/my_docs/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
    "/media/my_files/my_docs/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
    "/media2/my_files/my_docs/ai/models/bartowski_Llama-3.2-3B-Instruct-GGUF_Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    "/media2/my_files/my_docs/ai/models/ggml-org_gemma-3-1b-it-GGUF_gemma-3-1b-it-Q4_K_M.gguf"
    "/media2/my_files/my_docs/ai/models/unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
    "/media2/my_files/my_docs/ai/models/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
    "/mnt/new/2024/llama/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"
)

# Check which models exist and print them
AVAILABLE_MODELS=()
echo "Checking available models:"
for path in "${MODELPATHS[@]}"; do
    # Check if the path is absolute (starts with / or ~), otherwise treat it as relative to $BINARY_DIR
    if [[ "$path" = /* || "$path" = ~* ]]; then
        resolved_path="$path"
    else
        resolved_path="$BINARY_DIR/$path"
    fi

    if [[ -f "$resolved_path" ]]; then
        echo "- Model available: $resolved_path"
        AVAILABLE_MODELS+=("$resolved_path")
    fi
done

# Ensure at least one model is available
if [[ ${#AVAILABLE_MODELS[@]} -eq 0 ]]; then
    echo "Error: No model files found in the provided paths."
    exit 1
fi

# Get index from arguments (optional second argument)
MODEL_IDX="${2:-0}"

# Validate the model index
if ! [[ "$MODEL_IDX" =~ ^[0-9]+$ ]] || [[ "$MODEL_IDX" -ge "${#AVAILABLE_MODELS[@]}" ]]; then
    echo "Error: Invalid model index '$MODEL_IDX'. Valid indices: 0 to $((${#AVAILABLE_MODELS[@]} - 1))"
    exit 1
fi

MODEL_PATH="${AVAILABLE_MODELS[$MODEL_IDX]}"
echo "Selected model: $MODEL_PATH"

# Command-line arguments for llama-cli and llama-server
COMMON_ARGS="--threads $(nproc) -c 2048"

# Handle arguments passed to the script
if [[ $# -eq 0 ]]; then
    echo "Usage: .llama [cli|chat|server|help] [model_index]"
    exit 1
fi

# Check if the model exists
#if [[ ! -f "$MODEL_PATH" ]]; then
#    echo "Error: Model file not found at $MODEL_PATH"
#    exit 1
#fi

case $1 in
    cli | chat)
        echo "Running llama in CLI mode..."
        "${BINARY_DIR}/llama-cli" -m "$MODEL_PATH" $COMMON_ARGS -cnv -p "You are a helpful assistant"
        ;;
    server)
        echo "Running llama in Server mode..."
        "${BINARY_DIR}/llama-server" -m "$MODEL_PATH" $COMMON_ARGS
        #"${BINARY_DIR}/llama-server" -m "$MODEL_PATH" $COMMON_ARGS --host $(ip addr show | grep -v 'inet6' | grep -v 'inet 127' | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d/ -f1)
        ;;
    help)
        echo "Usage: .llama [cli|chat|server|help] [model_index]"
        echo "Commands:"
        echo "  cli    Run llama in CLI mode"
        echo "  chat   Alias for CLI mode"
        echo "  server Run llama in Server mode"
        echo "  help   Show this help message"
        echo "  model_index Optional, 0-based index to select model."
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: .llama [cli|chat|server|help] [model_index]"
        exit 1
        ;;
esac

