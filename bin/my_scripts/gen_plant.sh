#!/bin/bash

Recursive=false

if [ -z "$1" ]; then
    echo "Usage: plantuml_script.sh <input_file>/all/*"
    exit 1
fi

InputFile="$1"

# Handle "all" or "*" to process all .txt and .puml files
if [[ "$InputFile" == "all" ]] || [[ "$InputFile" == "*" ]]; then
    echo "Generating PlantUML diagrams for all .txt and .puml files..."
    
    if [ "$Recursive" = true ]; then
        find . -type f \( -name "*.txt" -o -name "*.puml" \) -exec "$0" {} \;
    else
        find . -maxdepth 1 -type f \( -name "*.txt" -o -name "*.puml" \) -exec "$0" {} \;
    fi
    
    exit 0
fi

# Append .txt if no extension present
if [[ "$InputFile" != *.* ]]; then
    InputFile="${InputFile}.txt"
    echo "No extension detected; trying input file '$InputFile'..."
fi

# Check that the file exists
if [ ! -f "$InputFile" ]; then
    echo "Error: Input file '$InputFile' not found."
    exit 1
fi

if [ -z "$my_notes_path" ]; then
    echo "Error: Environment variable 'my_notes_path' is not set."
    exit 1
fi

plantUmlJar="$my_notes_path/scripts/plants/plantuml.jar"

if [ ! -f "$plantUmlJar" ]; then
    echo "Error: PlantUML jar not found at $plantUmlJar."
    exit 1
fi

#echo "Running command: java -jar $plantUmlJar $InputFile"
echo "Running command: java -jar \"$plantUmlJar\" \"$InputFile\""
java -jar "$plantUmlJar" "$InputFile"

if [ $? -eq 0 ]; then
    echo "PlantUML diagram generated for $InputFile."
else
    echo "Error: Failed to generate PlantUML diagram."
    exit 1
fi

