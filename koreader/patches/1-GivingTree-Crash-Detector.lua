--[[
    This is meant to detect if KO-Reader crashes prior to the (Presumed) completion of boot.
]]--
local file_path = "/tmp/.treestump"
local diag_path = "/tmp/.woodchips"

local treestump = "safemode"
local woodchips = "Launch Log"
local read = false;

local file = io.open(file_path, "r")
if file then
    treestump = file:read("*l") -- Read the first line
    file:close()
    read = true;
else
    woodchips = woodchips .. " - Couldn't read file"
end


-- Ensures if .treestump was assigned something other than a normal number, we don't clobber it.
-- Such as a manually set safemode.
if treestump == "0" then
    treestump = "1"
end
if treestump == "1" then
    treestump = "2"
end
if treestump ~= "2" then
    woodchips = woodchips .. " - Stump isn't 2? it's '" .. treestump .."'"
end

-- Only write if we read the file in the first place.
if read then
    -- Open the file in write mode ("w" overwrites, "a" appends)
    local file, err = io.open(file_path, "w")

    if file then
        file:write(treestump)
        file:close()
    else
        woodchips = woodchips .. " - Couldn't write file?"
    end
end

-- Open the file in write mode ("w" overwrites, "a" appends)
local file, err = io.open(diag_path, "w")

if file then
    file:write(woodchips)
    file:close()
else
    woodchips = woodchips .. " - Couldn't write axe?"
end