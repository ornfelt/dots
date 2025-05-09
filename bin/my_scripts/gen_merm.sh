#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: mermaid_script.sh <input_file>"
    exit 1
fi

InputFile="$1"

# Append .md if no extension present
if [[ "$InputFile" != *.* ]]; then
    InputFile="${InputFile}.md"
    echo "No extension detected; trying input file '$InputFile'..."
fi

# Check that the file exists
if [ ! -f "$InputFile" ]; then
    echo "Error: Input file '$InputFile' not found."
    exit 1
fi

# Ensure npx/mermaid-cli is available
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

