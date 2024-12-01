#!/bin/bash

# TODO: fix...
# Fail if no model is found

# Example: Handle arguments passed to the script
if [[ $# -eq 0 ]]; then
    echo "Usage: .llama [cli|server|help]"
    exit 1
fi

case $1 in
    cli)
        echo "Running llama in CLI mode..."
        ;;
    chat)
        echo "Running llama in CLI mode..."
        ;;
    server)
        echo "Running llama in Server mode..."
        ;;
    help)
        echo "Usage: .llama [cli|server|help]"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: .llama [cli|chat|server|help]"
        exit 1
        ;;
esac

