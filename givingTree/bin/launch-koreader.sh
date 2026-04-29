#!/bin/sh
# Wait for GivingTree to fully exit
sleep 3

# This puts up a neat splash screen while KO Reader is launching
SCRIPT_DIR="$(dirname "$0")"
sh $SCRIPT_DIR/ascii-splash.sh "$SCRIPT_DIR/axe-splash.ascii" 32 "KOReader Is Launching..."  </dev/null >/dev/null 2>&1

# Create a stub 'start' command that does nothing
# This prevents koreader.sh from hanging when trying to restart services
cat > /tmp/start << 'STUBEOF'
#!/bin/sh
# Stub start command - does nothing
exit 0
STUBEOF
chmod +x /tmp/start
export PATH="/tmp:$PATH"

# Launch KOReader in background so we can monitor it
cd /mnt/us/koreader
./koreader.sh &

KOREADER_PID=$!



cat $KOREADER_PID > /tmp/ko_ps

# Wait for KOReader to actually start (reader.lua to appear)
STARTUP_WAIT=0
while [ $STARTUP_WAIT -lt 15 ]; do
    if pgrep -f "reader.lua" >/dev/null 2>&1; then
        break
    fi
    sleep 1
    STARTUP_WAIT=$((STARTUP_WAIT + 1))
done

if [ $STARTUP_WAIT -ge 15 ]; then
    kill -9 $KOREADER_PID 2>/dev/null
    echo "RESTART" > /var/tmp/givingtree-state
    rm -f /var/tmp/koreader-pause-keeper
    rm -f /var/tmp/launch-koreader.sh
    exit 1
fi

# Now monitor for exit

while true; do
    sleep 2
    
    # Check if koreader.sh is still running
    if ! kill -0 $KOREADER_PID 2>/dev/null; then
        sh $SCRIPT_DIR/ascii-splash.sh "$SCRIPT_DIR/axe-splash.ascii" 32 "KOReader Is Closing..."  </dev/null >/dev/null 2>&1
        break
    fi
    
    # Check if reader.lua is running
    if ! pgrep -f "reader.lua" >/dev/null 2>&1; then
        sh $SCRIPT_DIR/ascii-splash.sh "$SCRIPT_DIR/axe-splash.ascii" 32 "KOReader Is Cleaning Up..."  </dev/null >/dev/null 2>&1
        
        # Wait 5 seconds to see if it's just slow cleanup
        sleep 5
        
        if ! pgrep -f "reader.lua" >/dev/null 2>&1; then
            # Still no reader.lua - KOReader has exited but script is hung
            
            # Force kill everything
            kill -9 $KOREADER_PID 2>/dev/null
            killall -9 koreader 2>/dev/null
            killall -9 reader.lua 2>/dev/null
            break
        fi
    fi
done

# Additional cleanup

killall -9 reader.lua 2>/dev/null

killall -9 koreader 2>/dev/null

# Remove stub commands
rm -f /tmp/start

# Signal restart FIRST (before any fbink that might hang)
echo "RESTART" > /var/tmp/givingtree-state

# Remove keeper pause flag
rm -f /var/tmp/koreader-pause-keeper

# DON'T show any fbink message - just exit immediately
# The watchdog will show the message

# Force exit - no delays, no fbink, nothing
exec 1>&-
exec 2>&-
exit 0