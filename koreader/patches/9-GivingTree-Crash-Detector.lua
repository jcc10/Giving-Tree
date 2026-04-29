--[[
    This is meant to detect if KO-Reader crashes prior to a safe close.
]]--
local file_path = "/tmp/.treestump"
local diag_path = "/tmp/.woodchips"

local treestump = "safemode"
local woodchips = "Close Log"

local file = io.open(file_path, "r")
if file then
    treestump = file:read("*l") -- Read the first line
    file:close()
else
    woodchips = woodchips .. " - Couldn't read file"
end


-- Ensures if .treestump was assigned something other than a normal number, we don't clobber it.
-- Such as a manually set safemode.
if treestump == "0" then
    treestump = "0"
end
if treestump == "1" then
    treestump = "0"
end
if treestump == "2" then
    treestump = "0"
end
if treestump == "3" then
    treestump = "0"
end
if treestump == "4" then
    treestump = "0"
end
if treestump ~= "0" then
    woodchips = woodchips .. " - Stump isn't 0? it's '" .. treestump .."'"
end

-- Open the file in write mode ("w" overwrites, "a" appends)
local file, err = io.open(file_path, "w")

if file then
    file:write(treestump)
    file:close()
else
    woodchips = woodchips .. " - Couldn't write file?"
end

-- Open the file in write mode ("w" overwrites, "a" appends)
local file, err = io.open(diag_path, "w")

if file then
    file:write(woodchips)
    file:close()
else
    woodchips = woodchips .. " - Couldn't write axe?"
end