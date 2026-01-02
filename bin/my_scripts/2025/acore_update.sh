#!/usr/bin/env bash

ORIG_DIR="$(pwd)"

cd $HOME/Code2/C++

ACORE_DIR="AzerothCore-wotlk-with-NPCBots"
if [ -d "$ACORE_DIR" ]; then
    cd "$ACORE_DIR" || exit 1

    if [ -f /etc/arch-release ]; then
        echo "Arch Linux detected, checking out 'linux' branch..."
        git checkout linux || { echo "Failed to checkout linux branch"; exit 1; }
    fi

    sleep 0.5
    git pull
    sleep 0.5

    echo "Fetching latest non-merge commit from AzerothCore..."

    ACORE_COMMIT=$(git log --no-merges --grep='Merge branch' --invert-grep -1 --format="%H")
    ACORE_DATE=$(git show -s --format=%ci "$ACORE_COMMIT")
    echo "Latest non-merge AzerothCore commit: $ACORE_COMMIT ($ACORE_DATE)"

    ELUNA_DIR="modules/mod-eluna"
    if [[ -d "$ELUNA_DIR" ]]; then
        cd "$ELUNA_DIR" || exit 1

        sleep 0.5
        git pull
        sleep 0.5

        echo "Checking latest mod-eluna commit..."
        ELUNA_LATEST_COMMIT=$(git rev-parse HEAD)
        ELUNA_LATEST_DATE=$(git show -s --format=%ci "$ELUNA_LATEST_COMMIT")
        echo "Latest mod-eluna commit: $ELUNA_LATEST_COMMIT ($ELUNA_LATEST_DATE)"

        if [[ "$ELUNA_LATEST_DATE" < "$ACORE_DATE" ]]; then
            echo "mod-eluna is already older than AzerothCore. No checkout needed."
        else
            echo "Searching for a mod-eluna commit before $ACORE_DATE..."
            ELUNA_TARGET_COMMIT=$(git log --before="$ACORE_DATE" -1 --format="%H")
            if [ -n "$ELUNA_TARGET_COMMIT" ]; then
                echo "Checking out mod-eluna commit $ELUNA_TARGET_COMMIT"
                git checkout "$ELUNA_TARGET_COMMIT" || { echo "Failed to checkout commit"; exit 1; }
            else
                echo "No earlier mod-eluna commit found before $ACORE_DATE"
            fi
        fi

        cd ../..
    else
        echo "Skipping eluna update since dir doesn't exist: '$ELUNA_DIR' in $(pwd)"
    fi
else
    echo "Directory $ACORE_DIR does NOT exist."
fi

#cd "$ORIG_DIR" || exit 1
#echo "Returned to original directory: $(pwd)"

