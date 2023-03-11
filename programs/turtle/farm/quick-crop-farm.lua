local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()

local FARM_LENGTH = tonumber(arg[2]) or error("need a length") 
local FARM_WIDTH = tonumber(arg[3]) or error("need a width")

local CROP_TYPE_COUNT = tonumber(arg[4]) or 1

local FULL_GROWN = 7


local function harvestBlock()
    local isBlock, crop = robox.inspectDown()
    if(isBlock)then
        if(crop.state.age == FULL_GROWN or ( crop.name == "minecraft:beetroots" and crop.state.age == 3))then
            robox.digDown()
            robox.placeDown()
        end
    end
end

local function harvestFarm()

    robox.forward()

    for col = 1, FARM_WIDTH, 1
    do
        robox.select(((col-1) % CROP_TYPE_COUNT) + 1)
        harvestBlock()
        for row = 1, FARM_LENGTH - 1, 1 
        do
            robox.forward()
            harvestBlock()
        end

        print(col .. " out of " .. FARM_WIDTH)
        if(col ~= FARM_WIDTH)
        then
            print("not end of farm")
            if(col % 2 == 1)
            then
                print("odd turn")
                robox.turnRight()
                robox.forward()
                robox.turnRight()
            else
                print("even turn")
                robox.turnLeft()
                robox.forward()
                robox.turnLeft()
            end
        else
            print("end of farm, dont turn")
        end
    end

    --return home
    print("return home")
    if(FARM_WIDTH % 2 == 1)
    then
        print("odd width, starting farm length")
        robox.turnRight(2)
        robox.forward(FARM_LENGTH-1)
    end
    print("starting farm width")
    robox.turnRight()
    robox.forward(FARM_WIDTH - 1)
    print("going into chest spot")
    robox.turnLeft()
    robox.forward()

    --dump resources
    for i = CROP_TYPE_COUNT + 1, 16, 1 do
        robox.select(i)
        robox.drop() -- drop in chest in front
    end
    robox.turnLeft(2)
end

if(arg[1] == "cycle")
then
    while true do
        harvestFarm()

        --set a timer for 20 mins
        os.sleep(20*60)
    end
else
    harvestFarm()
end