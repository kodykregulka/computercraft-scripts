local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()

--highly suggested to use the return_home startup script
--that way if something goes wrong you should be able to 
--make your turtle return home after reloading it (leave server for a few mins and come back)

local HEIGHT_LIMIT = arg[1] or error("needs a height limit")


local function placeFillBlock(placeFunc)
    for i = 1, 16, 1
    do
        local slot = robox.getItemDetail(i)
        if(slot)
        then
            robox.select(i)
            if(slot.name == "minecraft:cobblestone" or slot.name == "minecraft:netherrack")
            then
                print("placing fill block")
                placeFunc()
                return
            else
                robox.dropDown()
            end
        end
    end
end

local function ensureBlockIsFill()
    local success, block = robox.inspect()
    if(not success)
    then
        print("nothing detected, placing fill block")
        placeFillBlock(robox.place)
    elseif(block.name == "minecraft:cobblestone" or block.name == "minecraft:netherrack")
    then
        print("already a good block")
        return
    else
        print("replace block")
        robox.dig()
        placeFillBlock(robox.place)
    end
end

for i = 1, HEIGHT_LIMIT - 1, 1
do
    placeFillBlock(robox.placeUp)
    print("start spin")
    for side = 1, 4, 1
    do
        ensureBlockIsFill()
        robox.turnLeft()
    end
    print("going up")
    robox.upWithDig()
end