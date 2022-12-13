--imports
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

--args
local X_LIMIT = 8
local Y_LIMIT = 5
local Z_LIMIT = 6

--clockwise
local firstRotationFunct = turtle.turnRight
--counter clockwise
local secondRotationFunct = turtle.turnLeft

local function moveForward()
    if(not turtle.forward())
    then
        error("turtle unable to move forward", 3)
    end
end

local function digForward(length)
    for i = 1, length, 1
    do
        turtle.dig()
        moveForward()
        turtle.digUp()
        turtle.digDown()
    end
end

local function digTurn(direction)
    direction()
    turtle.dig()
    moveForward()
    turtle.digUp()
    turtle.digDown()
    direction()
end

local function digLayer(x_limit, y_limit)
    for y = 1, y_limit-1, 1
    do
        digForward(x_limit)
        if(y % 2 == 1)
        then
            digTurn(firstRotationFunct)
        else
            digTurn(secondRotationFunct)
        end
    end
    digForward(x_limit)
end


--dig down

local forward_length = X_LIMIT
local sideward_length = Y_LIMIT

for z = 3, Z_LIMIT, 3
do
    digLayer(forward_length, sideward_length)
    
    if(z >= Z_LIMIT)
    then
        print("all done")
        return
    else
        for i = 1, 3, 1
        do
            turtle.digDown()
            if(not turtle.down())
            then
                error("unable to go down")
            end
        end
        turtle.digDown()
    end
                
    if(sideward_length % 2 == 1)
    then
        firstRotationFunct()
        firstRotationFunct()
    else
        firstRotationFunct()
        local temp = sideward_length
        sideward_length = forward_length
        forward_length = temp
    end
end
