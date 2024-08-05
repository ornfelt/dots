#!/bin/bash

if grep -qEi 'debian|raspbian' /etc/os-release; then
    # Check if the directory $HOME/eclipse exists
    if [ ! -d "$HOME/eclipse" ]; then
        echo "$HOME/eclipse directory does not exist. Exiting."
        exit 1
    fi

    # Find the eclipse.ini file in a directory that matches the pattern "java-.*"
    eclipse_ini=$(find "$HOME/eclipse" -type f -path "*/java-*/eclipse/eclipse.ini")

    # Check if the eclipse.ini file was found
    if [ -z "$eclipse_ini" ]; then
        echo "No eclipse.ini file found in a directory matching java-.*. Exiting."
        exit 1
    fi

    # Extract the java path that ends with /bin/java from the eclipse.ini file
    java_path=$(grep -E '^/.*bin/java$' "$eclipse_ini")

    # Check if the java path was found
    if [ -z "$java_path" ]; then
        echo "No java path found ending with /bin/java in $eclipse_ini. Exiting."
        exit 1
    fi
else
    java_path="java"
fi

# Construct the java command
java_command="$java_path -jar $HOME/wowbot.jar"

# Print and execute the java command
echo "Running java command: $java_command 1 1"
$java_command

