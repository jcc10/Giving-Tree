   _______       _            ______             
  / ____(_)   __(_)___  ____ /_  __/_______  ___ 
 / / __/ / | / / / __ \/ __ `// / / ___/ _ \/ _ \
/ /_/ / /| |/ / / / / / /_/ // / / /  /  __/  __/
\____/_/ |___/_/_/ /_/\__, //_/ /_/   \___/\___/ 
                     /____/                      

Giving Tree is a script designed for kindles to direct-boot into KO Reader skipping over the Kindle Framework.

The code for this is based on OpenReader, however this does not rely on having touchscreen input functionality and may be better for devices in something approaching a kiosk mode.

To prevent device lockouts / bricking, GivingTree relies on a pair of patches to attempt to detect when things break.

## Anti-Lockout Flow

1. Kindle Starts
2. Giving Tree Starts
3. If file `/mnt/us/.treestump` has the value of `1`, launch framework.
4. If file `/mnt/us/.treestump` has the value of `2`, launch framework.
7. Write to file `/mnt/us/.treestump` the value `1`
8. Launch KO Reader
9. KO Reader runs patch `1-KO-Boot-Pass.lua`
10. If file `/mnt/us/.treestump` has the value of `0`, set value to `1`. (In case KO started outside the launcher)
10. If file `/mnt/us/.treestump` has the value of `1`, set value to `2`.
11. On KO Reader Close
12. KO Reader runs patch `9-KO-Close-Pass.lua`
13. Write to file `/mnt/us/.treestump` the value `0`