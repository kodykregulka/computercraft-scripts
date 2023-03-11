local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()

if(#arg < 2)then
    error("not enough args (x,y)")
end


local X_LENGTH = tonumber(arg[1])
local Y_LENGTH = tonumber(arg[2])

if(X_LENGTH * Y_LENGTH == 0) then error("No zero values allowed")end

local isBehind = false
if(Y_LENGTH < 0) then
    isBehind = true
    Y_LENGTH = Y_LENGTH * -1
    robox.turnLeft(2)
    X_LENGTH = X_LENGTH * -1
end

local firstTurn = robox.turnRight
local secondTurn = robox.turnLeft
if(X_LENGTH < 0)
then
    X_LENGTH = X_LENGTH * -1
    firstTurn = robox.turnLeft
    secondTurn = robox.turnRight
end


local function selectItems()
    if(robox.getItemCount() < 1)
    then
        for i = 1, 16, 1 do
            if(robox.getItemCount(i)>0)then
                robox.select(i)
                return
            end
        end
        error("no more items", 2)
    end
end

local function placeDown()
    if(not robox.detectDown())then
        selectItems()
        robox.placeDown()
    end
end

for x = 1, X_LENGTH, 1 do
    
    for y = 1, Y_LENGTH-1, 1 do
        placeDown()
        robox.forward()
    end
    placeDown()
    if(x ~= X_LENGTH)
    then
        if(x%2==1)then
            firstTurn()
            robox.forward()
            firstTurn()
        else
            secondTurn()
            robox.forward()
            secondTurn()
        end
    else
        --the end
    end

end

--bring it on home
if(X_LENGTH %2 == 1)
then
    robox.turnLeft(2)
    robox.forward(Y_LENGTH-1)
end

firstTurn()
robox.forward(X_LENGTH-1)
if(isBehind)
then
    secondTurn()
else
    firstTurn()
end




