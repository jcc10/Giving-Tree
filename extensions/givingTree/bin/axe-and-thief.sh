#!/bin/sh
# This sticks the axe and thief files for testing.
SCRIPT_DIR="$(dirname "$0")"
ASCII_SPLASH="$SCRIPT_DIR/ascii-splash.sh"
ASCII_ART="$SCRIPT_DIR/ascii/"


sh "$ASCII_SPLASH" "$ASCII_ART/keys" 32 "Placing .axe and .thief " "files in /mnt/us/"

touch /mnt/us/.thief
touch /mnt/us/.axe
sleep 5