--scriptt to return home on startup
--designed to return back to the start 

local robox = require(settings.get("require.api_path") .. "turtle.robox").configure({MOVEMENT_MODE = "forced"})


local LIMIT = 255
local BOTTOM_BLOCK = "minecraft:dirt"

print("returning home")

for i = 1, LIMIT, 1
do
    local success, block = robox.inspectDown()
    if(success and (block.name == BOTTOM_BLOCK))
    then
        break
    end
    robox.digDown()
    robox.down()
end

print("arrived at home")