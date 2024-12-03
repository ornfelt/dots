#!/bin/bash

# Ensure the environment variable `code_root_dir` is set
if [[ -z "$code_root_dir" ]]; then
    echo "Error: Environment variable 'code_root_dir' is not set."
    exit 1
fi

# Define the model path
MODEL_PATH="/mnt/new/2024/llama/Meta-Llama-3.1-8B-Instruct/Meta-Llama-3.1-8B-Instruct-ggml-model-Q4_K_M.gguf"

# Define the binary directory based on `code_root_dir`
BINARY_DIR="${code_root_dir}/Code/ml/llama.cpp/build/bin"

# Command-line arguments for llama-cli and llama-server
COMMON_ARGS="--threads $(nproc) -c 2048"

# Handle arguments passed to the script
if [[ $# -eq 0 ]]; then
    echo "Usage: .llama [cli|chat|server|help]"
    exit 1
fi

# Check if the model exists
if [[ ! -f "$MODEL_PATH" ]]; then
    echo "Error: Model file not found at $MODEL_PATH"
    exit 1
fi

# Check if the binary directory exists
if [[ ! -d "$BINARY_DIR" ]]; then
    echo "Error: Binary directory not found at $BINARY_DIR"
    exit 1
fi

case $1 in
    cli | chat)
        echo "Running llama in CLI mode..."
        "${BINARY_DIR}/llama-cli" -m "$MODEL_PATH" $COMMON_ARGS -cnv -p "You are a helpful assistant"
        ;;
    server)
        echo "Running llama in Server mode..."
        "${BINARY_DIR}/llama-server" -m "$MODEL_PATH" $COMMON_ARGS
        ;;
    help)
        echo "Usage: .llama [cli|chat|server|help]"
        echo "Commands:"
        echo "  cli    Run llama in CLI mode"
        echo "  chat   Alias for CLI mode"
        echo "  server Run llama in Server mode"
        echo "  help   Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: .llama [cli|chat|server|help]"
        exit 1
        ;;
esac

