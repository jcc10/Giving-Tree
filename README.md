```
   _______       _            ______             
  / ____(_)   __(_)___  ____ /_  __/_______  ___ 
 / / __/ / | / / / __ \/ __ `// / / ___/ _ \/ _ \
/ /_/ / /| |/ / / / / / /_/ // / / /  /  __/  __/
\____/_/ |___/_/_/ /_/\__, //_/ /_/   \___/\___/ 
                     /____/                      
```

Giving Tree is a script designed for kindles to direct-boot into KO Reader skipping over the Kindle Framework.

The code for this is based on OpenReader, however this does not rely on having touchscreen input functionality and may be better for devices in something approaching a kiosk mode.

To prevent device lockouts / bricking, GivingTree relies on a pair of patches to attempt to detect when things break so we can steal the axe if things go wrong.

# Installation
While it shouldn't be difficult to do, and should be hard to get yourself into a bricked kindle situation, I do recommend knowing how to get KUBRICK to get USB SSH access to your kindle for fixing stuff if anything goes wrong.

## 0. Jailbreak your legacy kindle
This is designed around older kindles. Namely k3g and k4 kindles. Said kindle must be jailbroken, have the updated dev-certs installed, and have KO Reader installed.

You should be able to have the SSH server running via KO Reader over WiFi prior to continuing.


## 1. Download project.
As we don't need to compile anything, just download the project.

## 2. Copy givingTree to the extensions folder.


## 3. Test Placement
To ensure it's in the right place, you should be able to run the axe-and-thief script from the kindle menu. (If you see some ASCII art, it should be correct.)

## 4. Get the Lumberjack Framework moved over.
You can do this using the install-lumberjack-boot script, or manually. (I recommend manually at this point in time.)

1. mount the root file system in read-write mode `mntfs rw`
2. copy original for comparason `cp /etc/init.d/framework /mnt/us/extensions/givingTree/bin/framework.this.device`
3. ***Check for discrepancies!*** I only have two k4 (Non-Touch) and one K3G to test on ATM. So please verify the framework launcher is the same as the expected one found in this repo.
  * `framework.original`
  * `framework.original.k4`
  * `framework.original.k4.older`
  * `framework.original.k3g`
4. Copy the replacement over the original. `cp /mnt/us/extensions/givingTree/bin/framework /etc/init.d/framework`

## 5: **ADD THE THIEF FILE**
run `touch /mnt/us/.thief` ensures the thief file will steal the `/mnt/us/.axe` file every launch until it's removed. This is to prevent bricking your device.
## 6: Add the axe
run `touch /mnt/us/.axe` to add the .axe file which will cause the framework launcher to instead launch the GivingTree launcher.
## 7: Reboot
using the cmd `reboot` or through the framework `menu > settings > menu > restart`

## 8: Done?
You should now launch directly into KO Reader through the Giving Tree framework replacement. If you reboot again, you should reboot into the normal kindle framework. Unless you manually add back in the `.axe` file. To prevent that behavior, delete the `.thief` file.

Note that you 

# Parts of the project
## framework
This is a modification to the framework script found on a Kindle 4th Gen (No-Touch) device. If it detects there is a file `/mnt/us/.axe` and a file `/mnt/us/extensions/givingTree/bin/boot-replacement.sh` (Remember `/mnt/us/` is the root when a kindle is mounted as a USB via framework!) It will skip running the Kindle Framework and instead run the `boot-replacement.sh` script.

## boot-replacement.sh
This sets-up the watchdog process that replaces the framework script. It launches the main launcher, waits for KO Reader to close, then re-launches the main launcher.

## launcher.sh
This displays some hardware information, tracks crashes in an attempt to prevent bricking your device, and launches KO Reader. It is not directly intractable at this time.

## launch-koreader.sh
Originally code within the launcher that would get written to a temp file before being ran. I felt it was less work to just pull it out into it's own script proper.

## ascii-splash.sh
Used for displaying splash ASCII images starting from the top line. Can also display a notification below the image.

## install-lumberjack-boot.sh
This *should* mount the root fs in read-write mode, copy `/etc/init.d/framework` to `/mnt/us/.framework.old` and then copy `/mnt/us/extensions/givingTree/bin/framework` to `/etc/init.d/framework` overwriting the original.

I don't reccomend it and instead reccomend doing it manually after verifying which lines were changed.

# Modifications to `/etc/init.d/framework`

* Line 38 added to point to .axe file
* no_framework_screen_axe function added
  * ensure it has the check for the boot-replacement script existing.
* Added if statement around lines ~296 and closing at line 306/307
  * This checks for the .axe file and if it's found runs the function above with an else statement wrapping the older code.

# Special files
## .axe
The axe file is what lets the patched `/etc/init.d/framework` file know to launch the `givingTree/bin/boot-replacement.sh` file instead of the normal framework on boot.

## .thief
The thief file will cause `givingTree/bin/boot-replacement.sh` to automatically delete the `.axe` file upon load. This is meant for testing when modifying the script as it should mostly prevent you from bricking yourself.

## .petrify
Speaking of preventing bricking yourself, the `.petrify` file is meant to prevent most of the automatic escape hatches from working.

## BOOT_KINDLEOS
This comes from the original OpenReader project, but I didn't feel like removing it. It removes the `.axe` file and triggers a reboot to drop you back to the normal kindle framework.

## `/tmp/givingtree-state`
This is part of the watchdog script taken (then modified) from the OpenReader launcher. Just don't mess with it and everything should be fine.

## `/tmp/.treestump`
This file is used to pass messages between KO Reader plugins and `givingTree/bin/launcher.sh`

### 0: KO Reader closed without errors
This is what the launcher expects. A empty/missing file will also act like a code 0.

This is also written if the patch `999-GivingTree-Crash-Detector.lua` sees a `0`, `1`, `2`, `3`, or `4` when it runs after settings are saved and is essentially one of the last scripts to run on closing KO Reader.

### 1: Crash During Launch
The givingTree launcher writes a 1 before it starts KO Reader. The patch `1-GivingTree-Crash-Detector.lua` expects for there to be a `0` or `1` there when it starts. If there is it writes a `2`, otherwise it leaves it as we found (or didn't) find it.

If givingTree launcher sees it it will remove the `.axe` file and reboot.

### 2 & 3: Crash Detection
If the GivingTree launcher sees a `2` it will change it to a `3`, if it sees a `3` it will change it to a `4`. It's meant to indicate a unknown crash while KO Reader was in the middle of running (As opposed to failing to launch at all.)

#### 4: Repeated Crashes
If the GivingTree launcher sees this, it presumes KO Reader has crashed 3 times without a proper close and will therefore delete the `.axe` file and reboot.

#### SAFEMODE, SAFE, FRAMEWORK: Manual Safemode Triggers
These are all ways to manually tell the GivingTree launcher that it should delete the `.axe` file and reboot.

#### 80: Reboot
This is meant to interact with additional plugins/patches to allow for adding in reboot and shutdown options into the KO Reader menus.

#### 90: Shutdown
This is meant to interact with additional plugins/patches to allow for adding in reboot and shutdown options into the KO Reader menus.

#### *: Anything Else
If it finds anything else? It assumes something has gone terribly wrong, deletes the `.axe` file, and reboots.

## Q&A:
### Q: Why are the docs this mess?
A: Because I mostly wrote them up while drowsy after finally finishing the initial code and I just wanted to get it pushed and to go to sleep.
### Q: Are you going to clean up the docs?
A: Probably sometime in the future? Right now I'm trying to write a couple of patches to provide a power menu and a wi-fi connection menu within KO Reader. (Also probably a timezone setting feature.)
### Q: How do I Restart / Shutdown the reader?
A: Write a 80 (restart) or 90 (shutdown) to `/tmp/.treestump` over ssh, then exit KO Reader. Or you can probably press & Hold thep power button long enough.

I'm working on a power-menu patch right now, but I'm taking a break to read some right now.
### Q: How do I load books over USB?
A: That's the neat part! You don't!

But seriously, mounting in USB mode *seems* to be incompatable with running KO Reader, so you really can't. I'll look into adding a "Switch to USB" mode to the power menu some-time in the future.

### Q: How do I configure Wi-Fi?
A: Wi-Fi can be controlled via the `wpa_cli` tool. I'm looking into writing a patch to allow for loading configs via said command through the KO Reader GUI, but for now, use a terminal / SSH to control.

### Q: I can't get SSH.
A: Use KUBRICK to get the diag menu and mount as USB-MSD and delete the `.axe` file. Then configure a intial Wi-Fi through the framework.

### Q: Why "GivingTree"?
The version of "The Giving Tree" I remember (IDK if there are variants or not) involved the tree eventually telling the child that used to play on it & read under it, that he should be fine cutting it down to build something new (or something to that extent). Given the boot image of someone reading under a tree and the fact we are cutting down the entire base software, it just fit.

### Q: How do I fix the timezone.
I DONT KNOW....

But seriously, I tried messing with it based on the instructions [HERE](https://www.mobileread.com/forums/showthread.php?t=353224), But I hit problems. I'm planning on writing a patch to auto-run the `settz` command during boot since I think it doesn't save if you don't set the root-fs to rw mode(?) along with adding a menu to change timezones. (And automatically changing between DST and non-DST offsets depending on the date.)

Seriously though. Fuck Time-Zones. And I'm considering asking for a patch to KO Reader to permit easer timezone offet patching.
