#!/bin/sh
# Kindle Touch-Enabled Launcher - CLEAN UI VERSION
# Uses compiled touch_reader binary for real touch input
echo "RUNNING" > /var/tmp/givingtree-state

SCRIPT_DIR="$(dirname "$0")"
FBINK="/mnt/us/koreader/fbink"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"
ASCII_SPLASH="$SCRIPT_DIR/ascii-splash.sh"
ASCII_ART="$SCRIPT_DIR/ascii/"

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
    
    # Check if we're in boot mode
    if [ "$GIVINGTREE_BOOT_MODE" = "1" ]; then
        # Boot mode: Don't restore framework, we're staying in GivingTree
        # Just clean up
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
        return
    fi
    
    # Signal watchdog NOT to restart (permanent exit to KindleOS)
    echo "EXIT" > /var/tmp/givingtree-state
    
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
    
    # ═══════════════════════════════════════════════════
    # BANNER - Centered with padding (lines 5-16)
    # ═══════════════════════════════════════════════════
    sh "$ASCII_SPLASH" "$ASCII_ART/giving-tree" 15 "It's Not E-Waste" "Until It's Dead."

    
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
        BATTERY="Unknown"
    fi

    $FBINK -y 17 -pmb ""
    $FBINK -y 18 -pmb "Hardware Info:"
    $FBINK -y 19 -pmb "Device:  Kindle $MODEL"
    $FBINK -y 20 -pmb "Kernel:  $KERNEL"
    $FBINK -y 21 -pmb "Battery: $BATTERY"
    $FBINK -y 23 -pmb "Uptime:  $UPTIME"
    $FBINK -y 24 -pmb "Memory:  $MEMORY"
    $FBINK -y 25 -pmb "Storage: $STORAGE"

    $FBINK -s
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
        
        # Don't show launching message, It's the only thing we *can* do.
        # # Show launching message
        # $FBINK -c
        $FBINK -y 31 -pmhb " "
        $FBINK -y 32 -pmhb "Launching KOReader..."
        $FBINK -y 33 -pmhb " "
        $FBINK -s
        sleep 1
        
        chmod +x $SCRIPT_DIR/launch-koreader.sh
        
        # Launch in background, detached from this process
        sh $SCRIPT_DIR/launch-koreader.sh </dev/null >/dev/null 2>&1 &
        
        # Exit launcher IMMEDIATELY - critical to free up resources
        exit 0
    else
        $FBINK -c
        $FBINK -y 10 -pmh "KOReader not installed!"
        $FBINK -y 12 -pm "Install from: koreader.rocks"
        $FBINK -y 14 -pm "Stealing the axe!"
        $FBINK -y 14 -pm "And running a full reboot..."
        sleep 15
        rm /mnt/us/.axe
        reboot_system
    fi
}

# Reboot system
reboot_system() {
    sh "$ASCII_SPLASH" "$ASCII_ART/reload" 32 "⚠️  REBOOTING KINDLE..." "Please wait..."
    sleep 2
    restore_services
    /sbin/reboot
}

# Power off system
poweroff_system() {
    sh "$ASCII_SPLASH" "$ASCII_ART/switch-off" 32 "⚠️  POWERING OFF..." "Goodbye!"
    sleep 2
    restore_services
    /sbin/poweroff
}

trigger_safemode() {
    sh "$ASCII_SPLASH" "$ASCII_ART/keys" 15 "⚠️  REBOOTING KINDLE..." ".axe file deleted!"
    sleep 5
    rm /mnt/us/.axe
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

        sleep 5
        
        TS=$(cat /tmp/.treestump 2>/dev/null || echo "0")

        #$FBINK -y 26 -pm "Dbg-TS: '$TS'"
        case "$TS" in
            0)
                $FBINK -y 29 -pm "Treestump Safe"
                echo "1" > /tmp/.treestump
                wait 10
                launch_koreader;;
            1)
                $FBINK -y 29 -pm "Treestump Launch Crashed"
                trigger_safemode;;
            2)
                $FBINK -y 29 -pm "Treestump Close Crashed"
                echo "3" > /tmp/.treestump
                wait 15
                launch_koreader;;
            3)
                $FBINK -y 29 -pm "Treestump Second Crash"
                echo "4" > /tmp/.treestump
                wait 15
                launch_koreader;;
            4)
                $FBINK -y 29 -pm "Treestump Safe Mode"
                trigger_safemode;;
            safemode|safe|framework)
                $FBINK -y 29 -pm "Treestump Manual Safe Mode"
                trigger_safemode
                reboot_system;;
            80)
                $FBINK -y 29 -pm "Treestump Restarting"
                reboot_system;;
            90)
                $FBINK -y 29 -pm "Treestump Shutting Down"
                poweroff_system;;
            *)
                $FBINK -y 29 -pm "Treestump Unknown Safe Mode"
                trigger_safemode
                reboot_system;;
        esac
    done
}

main

