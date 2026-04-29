#!/bin/sh
# This sticks the axe and thief files for testing.
SCRIPT_DIR="$(dirname "$0")"
LIVE_FRAMEWORK="/etc/init.d/framework"
ASCII_SPLASH="$SCRIPT_DIR/ascii-splash.sh"
ASCII_ART="$SCRIPT_DIR/ascii"

sh "$ASCII_SPLASH" "$ASCII_ART/floppy" 32 "Installing the new framework!"

if ! cp "$LIVE_FRAMEWORK" "$SCRIPT_DIR/framework.this.device"; then
    sh "$ASCII_SPLASH" "$ASCII_ART/warning" 32 "Couldn't copy live framework!" "Manual intervention required!" "Exiting in 30s"
    echo "Couldn't backup framework"
    sleep 30
    exit 1
fi

if ! cmp -s "$SCRIPT_DIR/framework.original" "$SCRIPT_DIR/framework.this.device"; then
    sh "$ASCII_SPLASH" "$ASCII_ART/warning" 32 "framework file doesn't match sample!" "Manual intervention required!" "Exiting in 30s"
    echo "Backup framework didn't match!"
    sleep 30
    exit 1
fi

if ! mntroot rw; then
    sh "$ASCII_SPLASH" "$ASCII_ART/warning" 32 "Couldn't mount rootfs in rw mode!" "Manual intervention required!" "Exiting in 30s"
    echo "mntroot rw failed!"
    sleep 30
    exit 1
fi

if ! cp "$SCRIPT_DIR/framework" "$LIVE_FRAMEWORK"; then
    sh "$ASCII_SPLASH" "$ASCII_ART/warning" 32 "Couldn't copy new framework!" "Manual intervention required!" "Exiting in 30s"
    echo "couldn't copy new framework in!"
    sleep 30
    exit 1
fi

sleep 30
touch /mnt/us/.thief
touch /mnt/us/.axe
/sbin/reboot

