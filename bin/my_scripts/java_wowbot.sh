#! /usr/bin/bash

export DISPLAY=:0

if grep -qEi 'debian|raspbian' /etc/os-release; then
    # Check if dir $HOME/eclipse exists
    if [ ! -d "$HOME/eclipse" ]; then
        echo "$HOME/eclipse directory does not exist. Exiting."
        exit 1
    fi

    # Find eclipse.ini file in a dir that matches the pattern "java-.*"
    eclipse_ini=$(find "$HOME/eclipse" -type f -path "*/java-*/eclipse/eclipse.ini")

    # Check if the eclipse.ini file was found
    if [ -z "$eclipse_ini" ]; then
        echo "No eclipse.ini file found in a directory matching java-.*. Exiting."
        exit 1
    fi

    # Extract java path that ends with /bin/java from the eclipse.ini file
    java_path=$(grep -E '^/.*bin/java$' "$eclipse_ini")

    # Check if java path was found
    if [ -z "$java_path" ]; then
        echo "No java path found ending with /bin/java in $eclipse_ini. Exiting."
        exit 1
    fi
else
    java_path="java"
fi

if [ -d "/mnt/new/jar_files" ]; then
  JAR_DIR="/mnt/new/jar_files"
else
  JAR_DIR="$HOME/Downloads/jar_files"
fi
CLASSPATH="$JAR_DIR/jna-5.13.0.jar:$JAR_DIR/jna-platform-5.13.0.jar:$JAR_DIR/sql-jars/mariadb-java-client-3.2.0.jar:$JAR_DIR/mysql/mysql-connector-j-9.0.0/mysql-connector-j-9.0.0.jar"
JAVA_COMMAND="$java_path -jar $HOME/Code2/C#/WowBot/java/wowbot.jar 1 1"

# When running in bash script, directly running the jar doesn't seem to work...
# Run compiled classes instead:
cd "$HOME/Code2/C#/WowBot/java"
javac -d . -cp $CLASSPATH $(find . -name "*.java" ! -name "WowTabFinder_windows.java")

JAVA_COMMAND="$java_path -cp .:$CLASSPATH wowbot.Main 1 1" # acore
#JAVA_COMMAND="$java_path -cp .:$CLASSPATH wowbot.Main 1 0" # tcore

# Copy run command instead?
#echo "$JAVA_COMMAND 1 1" | xclip -selection clipboard

echo "Running java command: $JAVA_COMMAND"
$JAVA_COMMAND

