#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: mermaid_script.sh <input_file>"
    exit 1
fi

InputFile="$1"

if ! command -v npx &> /dev/null; then
    echo "Error: npx is not installed. Install Node.js and Mermaid CLI."
    exit 1
fi

outputFile="${InputFile%.*}.png"
outputFileAlt="${outputFile}-1"

echo "Running command: npx @mermaid-js/mermaid-cli@latest -i \"$InputFile\" -o \"$outputFile\""
npx @mermaid-js/mermaid-cli@latest -i "$InputFile" -o "$outputFile"

if [ -f "$outputFile" ] || [ -f "$outputFileAlt" ]; then
    echo "Mermaid diagram generated: $outputFile or $outputFileAlt"
else
    echo "Error: Failed to generate Mermaid diagram."
    exit 1
fi

