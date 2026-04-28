#!/bin/sh
# Kindle Touch-Enabled Launcher - CLEAN UI VERSION
# Uses compiled touch_reader binary for real touch input

SCRIPT_DIR="$(dirname "$0")"
FBINK="/mnt/us/koreader/fbink"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Global state variables
FRONTLIGHT_ENABLED=0
FRONTLIGHT_LAST_LEVEL=600  # Default to 50% brightness (600/1200)

# Detect frontlight device path
detect_frontlight() {
    if [ -f /sys/class/backlight/max77696-bl/brightness ]; then
        echo "/sys/class/backlight/max77696-bl/brightness"
    elif [ -f /sys/class/backlight/fp9967-bl1/brightness ]; then
        echo "/sys/class/backlight/fp9967-bl1/brightness"
    elif [ -f /sys/class/backlight/mxc_msp430.0/brightness ]; then
        echo "/sys/class/backlight/mxc_msp430.0/brightness"
    else
        echo ""
    fi
}

FL_PATH=$(detect_frontlight)

# Stop Kindle services (KOReader method - use SIGSTOP to prevent auto-restart)
stop_services() {
    # Check if we're in boot mode (framework never started)
    if [ "$GIVINGTREE_BOOT_MODE" = "1" ]; then
        # Boot mode: Framework never started, just prevent screensaver
        FRAMEWORK_WAS_RUNNING=0
        lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
        return
    fi
    
    # Check if framework is actually running
    if pidof cvm >/dev/null 2>&1; then
        # Framework is running, suspend it
        FRAMEWORK_WAS_RUNNING=1
        
        # Prevent screen saver
        lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
        
        # Suspend (SIGSTOP) all framework processes
        # Using SIGSTOP instead of SIGKILL prevents init from restarting them
        killall -STOP cvm 2>/dev/null
        killall -STOP lipc-wait-event 2>/dev/null
        killall -STOP webreader 2>/dev/null
        killall -STOP kfxreader 2>/dev/null
        killall -STOP kfxview 2>/dev/null
        killall -STOP mesquite 2>/dev/null
        killall -STOP browserd 2>/dev/null
        
        # Suspend background services (from KOReader's TOGGLED_SERVICES)
        killall -STOP stored 2>/dev/null
        killall -STOP todo 2>/dev/null
        killall -STOP tmd 2>/dev/null
        killall -STOP rcm 2>/dev/null
        killall -STOP archive 2>/dev/null
        killall -STOP scanner 2>/dev/null
        killall -STOP otav3 2>/dev/null
        killall -STOP otaupd 2>/dev/null
        killall -STOP volumd 2>/dev/null
        
        # Ensure clean framebuffer
        echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
        
        # Small delay to ensure processes are fully stopped
        sleep 0.5
    else
        # Framework not running (we're in boot mode)
        FRAMEWORK_WAS_RUNNING=0
        lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
    fi
}

# Restore Kindle services (resume suspended processes)
restore_services() {
    # Signal watchdog NOT to restart (permanent exit to KindleOS)
    echo "EXIT" > /var/tmp/givingtree-state
    
    # Kill touch reader
    killall -TERM touch_reader 2>/dev/null
    
    # Check if we're in boot mode
    if [ "$GIVINGTREE_BOOT_MODE" = "1" ]; then
        # Boot mode: Don't restore framework, we're staying in GivingTree
        # Just clean up
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
        return
    fi
    
    # Check if framework was actually running before
    if [ "$FRAMEWORK_WAS_RUNNING" = "1" ]; then
        # Framework was running, restore it
        
        # Re-enable screen saver
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
        
        # Resume (SIGCONT) all suspended processes
        killall -CONT cvm 2>/dev/null
        killall -CONT lipc-wait-event 2>/dev/null
        killall -CONT webreader 2>/dev/null
        killall -CONT kfxreader 2>/dev/null
        killall -CONT kfxview 2>/dev/null
        killall -CONT mesquite 2>/dev/null
        killall -CONT browserd 2>/dev/null
        killall -CONT stored 2>/dev/null
        killall -CONT todo 2>/dev/null
        killall -CONT tmd 2>/dev/null
        killall -CONT rcm 2>/dev/null
        killall -CONT archive 2>/dev/null
        killall -CONT scanner 2>/dev/null
        killall -CONT otav3 2>/dev/null
        killall -CONT otaupd 2>/dev/null
        killall -CONT volumd 2>/dev/null
        
        # Refresh display
        echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
    else
        # Framework wasn't running, don't restore anything
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
    fi
}

# Get screen dimensions
get_screen_size() {
    # Default to Legacy Resolution 3G / 4th Gen (600x800)
    SCREEN_WIDTH=600
    SCREEN_HEIGHT=800
    
    # Try to detect actual dimensions
    if [ -f /sys/class/graphics/fb0/virtual_size ]; then
        DIMS=$(cat /sys/class/graphics/fb0/virtual_size)
        SCREEN_WIDTH=$(echo "$DIMS" | cut -d',' -f1)
        SCREEN_HEIGHT=$(echo "$DIMS" | cut -d',' -f2)
    fi
}

# Draw the menu (OPTIMIZED FOR 600x800 - FULL SCREEN)
draw_launcher() {
    
    $FBINK -c
    
    # ═══════════════════════════════════════════════════
    # BANNER - Centered with padding (lines 5-16)
    # ═══════════════════════════════════════════════════
    $FBINK -y 2 -pm "   _______       _            "
    $FBINK -y 3 -pm "  / ____(_)   __(_)___  ____ _"
    $FBINK -y 4 -pm " / / __/ / | / / / __ \\/ __ \`/"
    $FBINK -y 5 -pm "/ /_/ / /| |/ / / / / / /_/ / "
    $FBINK -y 6 -pm "\\____/_/ |___/_/_/ /_/\\__, /  "
    $FBINK -y 7 -pm "                     /____/   "
    $FBINK -y 8 -pm "  ______             "
    $FBINK -y 9 -pm " /_  __/_______  ___ "
    $FBINK -y 10 -pm "  / / / ___/ _ \\/ _ \\"
    $FBINK -y 11 -pm " / / / /  /  __/  __/"
    $FBINK -y 12 -pm "/_/ /_/   \\___/\\___/ "
    $FBINK -y 13 -pm "                     "
    
    # # Random tagline (centered) - using case for sh compatibility
    # RANDOM_NUM=$(($(date +%s) % 11))
    # case $RANDOM_NUM in
    #     0) TAGLINE="Open Source The World!" ;;
    #     1) TAGLINE="Sorry, Jeff :(" ;;
    #     2) TAGLINE="It's Free!" ;;
    #     3) TAGLINE="Whatcha Readin?" ;;
    #     4) TAGLINE="Welcome Back!" ;;
    #     5) TAGLINE="terpinedream was here" ;;
    #     6) TAGLINE="For books and stuff" ;;
    #     7) TAGLINE="Now Without Two Day Shipping." ;;
    #     8) TAGLINE="Wow!" ;;
    #     9) TAGLINE="Is this thing on?" ;;
    #     10) TAGLINE="Thank Your Local Devs!" ;;
    # esac
    
    # $FBINK -y 18 -pm ""
    # $FBINK -y 19 -pm "            $TAGLINE"
    
    $FBINK -y 14 -pm ""
    $FBINK -y 15 -pm " It's Not E-Waste"
    $FBINK -y 26 -pm " Until It's Dead."

    # Get system information
    MODEL=$(cat /proc/usid 2>/dev/null | cut -c4- || echo "Unknown")
    KERNEL=$(uname -r)
    UPTIME=$(uptime | awk '{print $3}' | sed 's/,//')
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f/%.0f MB", $3,$2}')
    STORAGE=$(df -h /mnt/us | tail -n 1 | awk '{print $3" / "$2" ("$5" Free)"}')


    # Battery info
    # Doesn't work on Kindle 4'th gen?
    if [ -f /sys/class/power_supply/bd71827_bat/capacity ]; then
        BATTERY=$(cat /sys/class/power_supply/bd71827_bat/capacity 2>/dev/null || echo "N/A")
        BATTERY="$BATTERY%"
    else
        BATTERY="N/A"
    fi

    $FBINK -y 17 -pm ""
    $FBINK -y 18 -pm "Hardware Info:"
    $FBINK -y 19 -pm "Device:  Kindle $MODEL"
    $FBINK -y 20 -pm "Kernel:  $KERNEL"
    $FBINK -y 21 -pm "Battery: $BATTERY"
    $FBINK -y 23 -pm "Uptime:  $UPTIME"
    $FBINK -y 24 -pm "Memory:  $MEMORY"
    $FBINK -y 25 -pm "Storage: $STORAGE"
}

# Launch KOReader (no framework version)
launch_koreader() {
    echo 
    if [ -f "/mnt/us/koreader/koreader.sh" ]; then
        
        # Signal watchdog NOT to restart (intentional exit for KOReader)
        echo "KOREADER" > /var/tmp/givingtree-state
        
        # CRITICAL: Tell framework keeper to stop interfering
        # KOReader needs framework services to NOT be continuously suspended
        touch /var/tmp/koreader-pause-keeper
        
        # Show launching message
        $FBINK -c
        $FBINK -y 12 -pmh "Launching KOReader..."
        sleep 1
        
        # Create a launcher script that will run after we exit
        cat > /var/tmp/launch-koreader.sh << 'KOREADER_EOF'
#!/bin/sh
# Wait for GivingTree to fully exit
sleep 3

# Clear screen
/mnt/us/koreader/fbink -c 2>/dev/null

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
        break
    fi
    
    # Check if reader.lua is running
    if ! pgrep -f "reader.lua" >/dev/null 2>&1; then
        
        # Wait 5 seconds to see if it's just slow cleanup
        sleep 5
        
        if ! pgrep -f "reader.lua" >/dev/null 2>&1; then
            # Still no reader.lua - KOReader has exited but script is hung
            
            # Force kill everything
            kill -9 $KOREADER_PID 2>/dev/null
            killall -9 koreader 2>/dev/null
            killall -9 reader.lua 2>/dev/null
            break
        else
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

# Clean up this script
rm -f /var/tmp/launch-koreader.sh

# Force exit - no delays, no fbink, nothing
exec 1>&-
exec 2>&-
exit 0
KOREADER_EOF
        
        chmod +x /var/tmp/launch-koreader.sh
        
        # Launch in background, detached from this process
        /var/tmp/launch-koreader.sh </dev/null >/dev/null 2>&1 &
        
        # Exit launcher IMMEDIATELY - critical to free up resources
        exit 0
    else
        $FBINK -c
        $FBINK -y 10 -pmh "KOReader not installed!"
        $FBINK -y 12 -pm "Install from: koreader.rocks"
        $FBINK -y 14 -pm "Touch anywhere to return..."
        "$TOUCH_READER" /dev/input/event1 2>/dev/null >/dev/null
    fi
}

# Reboot system
reboot_system() {
    $FBINK -c
    $FBINK -y 12 -pmh "⚠️  REBOOTING KINDLE..."
    $FBINK -y 14 -pm "Please wait..."
    sleep 2
    restore_services
    /sbin/reboot
}

# Power off system
poweroff_system() {
    $FBINK -c
    $FBINK -y 12 -pmh "⚠️  POWERING OFF..."
    $FBINK -y 14 -pm "Goodbye!"
    sleep 2
    restore_services
    /sbin/poweroff
}

trigger_safemode() {
    $FBINK -y 32 -pm "touched safeboot file"
    sleep 5
    touch /mnt/us/BOOT_KINDLEOS
    reboot_system
}

# Main loop
main() {
    stop_services
    get_screen_size
    
    
    # Trap exit to restore services
    trap 'restore_services; exit 0' INT TERM EXIT
    
    while true; do
        draw_launcher

        sleep 1
        
        TS=$(cat /mnt/us/.treestump 2>/dev/null)

        $FBINK -y 26 -pm "Dbg-TS: '$TS'"
        if [ -z "$TS" ]; then
            $FBINK -y 29 -pm "Treestump Not Found"
        else
            case "$TS" in
                0)
                    $FBINK -y 29 -pm "Treestump Safe"
                    echo "1" > /mnt/us/.treestump
                    wait 10
                    launch_koreader;;
                1)
                    $FBINK -y 29 -pm "Treestump Launch Crashed"
                    trigger_safemode;;
                2)
                    $FBINK -y 29 -pm "Treestump Close Crashed"
                    echo "3" > /mnt/us/.treestump
                    wait 15
                    launch_koreader;;
                3)
                    $FBINK -y 29 -pm "Treestump Second Crash"
                    echo "4" > /mnt/us/.treestump
                    wait 15
                    launch_koreader;;
                4)
                    $FBINK -y 29 -pm "Treestump Safe Mode"
                    trigger_safemode;;
                safemode|safe|framework)
                    $FBINK -y 29 -pm "Treestump Manual Safe Mode"
                    trigger_safemode;;
                *)
                    $FBINK -y 29 -pm "Treestump Unknown Safe Mode"
                    trigger_safemode;;
            esac
        fi
    done
}

main

