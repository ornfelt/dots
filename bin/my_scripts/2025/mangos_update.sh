#!/usr/bin/env bash

ORIG_DIR="$(pwd)"

cd $HOME/Code2/C++

if [ $# -gt 0 ]; then
    MANGOS_DIR="mangos-$1"
else
    MANGOS_DIR="mangos-classic"
fi

if [ -d "$MANGOS_DIR" ]; then
    cd "$MANGOS_DIR" || exit 1

    if [ -f /etc/arch-release ]; then
        echo "Arch Linux detected, checking out 'linux' branch..."
        git checkout linux || { echo "Failed to checkout linux branch"; exit 1; }
    fi

    sleep 0.5
    git pull
    sleep 0.5

    echo "Fetching latest non-merge commit from $MANGOS_DIR..."

    MANGOS_COMMIT=$(git log --no-merges --grep='Merge branch' --invert-grep -1 --format="%H")
    MANGOS_DATE=$(git show -s --format=%ci "$MANGOS_COMMIT")
    echo "Latest non-merge $MANGOS_DIR commit: $MANGOS_COMMIT ($MANGOS_DATE)"

    cd "src/modules/PlayerBots" || exit 1

    sleep 0.5
    git pull
    sleep 0.5

    echo "Checking latest PlayerBots commit..."
    PB_LATEST_COMMIT=$(git rev-parse HEAD)
    PB_LATEST_DATE=$(git show -s --format=%ci "$PB_LATEST_COMMIT")
    echo "Latest PlayerBots commit: $PB_LATEST_COMMIT ($PB_LATEST_DATE)"

    if [[ "$PB_LATEST_DATE" < "$MANGOS_DATE" ]]; then
        echo "PlayerBots is already older than $MANGOS_DIR. No checkout needed."
    else
        echo "Searching for a PlayerBots commit before $MANGOS_DATE..."
        PB_TARGET_COMMIT=$(git log --before="$MANGOS_DATE" -1 --format="%H")
        if [ -n "$PB_TARGET_COMMIT" ]; then
            echo "Checking out PlayerBots commit $PB_TARGET_COMMIT"
            git checkout "$PB_TARGET_COMMIT" || { echo "Failed to checkout commit"; exit 1; }
        else
            echo "No earlier PlayerBots commit found before $MANGOS_DATE"
        fi
    fi

    cd ../../../..
else
    echo "Directory $MANGOS_DIR does NOT exist."
fi

#cd "$ORIG_DIR" || exit 1
#echo "Returned to original directory: $(pwd)"

