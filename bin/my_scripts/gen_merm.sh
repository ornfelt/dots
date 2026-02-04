#!/bin/bash

Recursive=false
#Recursive=true

if [ -z "$1" ]; then
    echo "Usage: mermaid_script.sh <input_file>/all/*"
    exit 1
fi

InputFile="$1"

# Handle "all" or "*" to process all .md and .mermaid files
if [[ "$InputFile" == "all" ]] || [[ "$InputFile" == "*" ]]; then
    echo "Generating Mermaid diagrams for all .md and .mermaid files..."
    
    if [ "$Recursive" = true ]; then
        find . -type f \( -name "*.md" -o -name "*.mermaid" \) -exec "$0" {} \;
    else
        find . -maxdepth 1 -type f \( -name "*.md" -o -name "*.mermaid" \) -exec "$0" {} \;
    fi
    
    exit 0
fi

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

#useScale="false"
useScale="true"

if [ "$useScale" = "true" ]; then
    echo "Running command: npx @mermaid-js/mermaid-cli@latest --scale 2 -i \"$InputFile\" -o \"$outputFile\""
    npx @mermaid-js/mermaid-cli@latest --scale 2 -i "$InputFile" -o "$outputFile"
else
    echo "Running command: npx @mermaid-js/mermaid-cli@latest -i \"$InputFile\" -o \"$outputFile\""
    npx @mermaid-js/mermaid-cli@latest -i "$InputFile" -o "$outputFile"
fi

if [ -f "$outputFile" ] || [ -f "$outputFileAlt" ]; then
    echo "Mermaid diagram generated: $outputFile or $outputFileAlt"
else
    echo "Error: Failed to generate Mermaid diagram."
    exit 1
fi

