#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: plantuml_script.sh <input_file>"
    exit 1
fi

InputFile="$1"

if [ -z "$my_notes_path" ]; then
    echo "Error: Environment variable 'my_notes_path' is not set."
    exit 1
fi

plantUmlJar="$my_notes_path/scripts/plants/plantuml.jar"

if [ ! -f "$plantUmlJar" ]; then
    echo "Error: PlantUML jar not found at $plantUmlJar."
    exit 1
fi

echo "Running command: java -jar $plantUmlJar $InputFile"
java -jar "$plantUmlJar" "$InputFile"

if [ $? -eq 0 ]; then
    echo "PlantUML diagram generated for $InputFile."
else
    echo "Error: Failed to generate PlantUML diagram."
    exit 1
fi

