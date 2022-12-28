local robox = require(settings.get("require.api_path") .. "turtle.robox")

local FARM_LENGTH = 14
local FARM_WIDTH = 4

local WHEAT_CROP = 1
local CARROT_CROP = 2
local FULL_GROWN = 7


local function harvestBlock()
    local isBlock, crop = robox.inspectDown()
    if(isBlock)then
        if(crop.state.age == FULL_GROWN)then
            robox.digDown()
            robox.placeDown()
        end
    end
end

local function harvestFarm()
    robox.forward()
    robox.turnLeft()
    local currentCrop = WHEAT_CROP

    for col = 1, FARM_WIDTH, 1
    do
        if(col % 2 == 1) 
        then 
            currentCrop = WHEAT_CROP
        else
            currentCrop = CARROT_CROP
        end
        robox.select(currentCrop)
        harvestBlock()
        for row = 1, FARM_LENGTH, 1 
        do
            robox.forward()
            harvestBlock()
        end

        if(col ~= FARM_WIDTH)
        then
            if(col % 2 == 1)
            then
                robox.turnRight()
                robox.forward()
                robox.turnRight()
            else
                robox.turnLeft()
                robox.forward()
                robox.turnLeft()
            end
        end
    end

    --return home
    if(FARM_WIDTH % 2 == 1)
    then
        robox.turnRight(2)
        robox.forward(FARM_LENGTH)
    end
    robox.turnRight()
    robox.forward(FARM_WIDTH)
    robox.turnLeft(2)

    --dump resources
    for i = 3, 16, 1 do
        robox.select(i)
        robox.dropDown()
    end
end

while true do
    harvestFarm()

    --set a timer for 20 mins
    os.sleep(20*60)
end