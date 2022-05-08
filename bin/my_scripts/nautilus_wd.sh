#!/bin/bash
WHEREAMI=$(cat /tmp/whereami)
nautilus -w --no-desktop "$WHEREAMI"
