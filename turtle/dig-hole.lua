--imports
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field


--positive numbers mean right(x)/forward(y)/up(z)
--negative numbers mean left(x)/back(y)/down(z)
--example: 3 4 -20
-- will dig a hole 3 to the right, 4 forward, and 20 down
--turtle assumes that it starts in the corner inside the box indicated by the coords

--args
local X_LIMIT = expect(1,tonumber(arg[1]), "number")
local Y_LIMIT = expect(2, tonumber(arg[2]), "number")
local Z_LIMIT = expect(3, tonumber(arg[3]), "number")

if(X_LIMIT * Y_LIMIT * Z_LIMIT == 0)
then
    error("zero is not an accepted value")
end

local digFront = turtle.dig
local firstDig = {}
local secondDig = {}
local firstMove = {}
local secondMove = {}
if(Z_LIMIT > 0)
then
    firstDig = turtle.digUp
    secondDig = turtle.digDown
    firstMove = turtle.up
    secondMove = turtle.down
else
    Z_LIMIT = Z_LIMIT * -1 -- since we normalized the directions
    firstDig = turtle.digDown
    secondDig = turtle.digUp
    firstMove = turtle.down
    secondMove = turtle.up
end

local firstTurn = {}
local secondTurn = {}
local holeIsBehindYou = false

if(Y_LIMIT > 0)
then
    if(X_LIMIT > 0)
    then
        firstTurn = turtle.turnRight
        secondTurn = turtle.turnLeft
    else
        X_LIMIT = X_LIMIT * -1 -- since we normalized the directions
        firstTurn = turtle.turnLeft
        secondTurn = turtle.turnRight
    end
else
    --turn around, hole is behind you
    holeIsBehindYou = true
    Y_LIMIT = Y_LIMIT * -1 -- since we normalized the directions
    turtle.turnRight()
    turtle.turnRight()
    if(X_LIMIT > 0)
    then
        firstTurn = turtle.turnLeft
        secondTurn = turtle.turnRight
    else
        X_LIMIT = X_LIMIT * -1 -- since we normalized the directions
        firstTurn = turtle.turnRight
        secondTurn = turtle.turnLeft
    end
end

local function singleDig(start, limit, dig, move)
    for i = start, limit, 1 
    do
        dig()
        move()
    end
end
local function doubleDig(start, limit, dig, move)
    for i = start, limit, 1 
    do
        dig()
        digFront()
        move()
    end
end

local function moveWithoutDigging(move, count)
    print("move call")
    for i = 1, count, 1
    do
        if(not move())
        then
            error("unable to move", 2)
        end
    end
end


local isAwayFromZ = false
for X_POSITION = 1, X_LIMIT, 1
do
    local Y_POSITION = 1
    while(Y_POSITION <= Y_LIMIT)
    do
        local dig = {}
        local move = {}
        if(isAwayFromZ)
        then
            dig = secondDig
            move = secondMove
        else
            dig = firstDig
            move = firstMove
        end
        if(Y_POSITION == Y_LIMIT)
        then
            singleDig(1, Z_LIMIT-1, dig, move)
            Y_POSITION = Y_POSITION + 1 --TODO
        else
            doubleDig(1, Z_LIMIT-1, dig, move)
            Y_POSITION = Y_POSITION + 2
            digFront()
            turtle.forward()
            if(Y_POSITION <= Y_LIMIT)
            then
                digFront()
                turtle.forward()
            end
        end
        isAwayFromZ = not isAwayFromZ
    end

    if(X_POSITION == X_LIMIT)
    then
        --we are done
        --return home
        if(isAwayFromZ)
        then
            --return to z = 1
            moveWithoutDigging(secondMove, Z_LIMIT-1)
        end
        if(X_LIMIT % 2 == 1)
        then
            --return to y = 1
            firstTurn()
            firstTurn()
            moveWithoutDigging(turtle.forward, Y_LIMIT-1)
        end
        firstTurn()
        moveWithoutDigging(turtle.forward, X_LIMIT-1)
        firstTurn()
        if(holeIsBehindYou)
        then
            turtle.turnRight()
            turtle.turnRight()
        end
        print("Done")

    elseif(X_POSITION % 2 == 1)
    then
        firstTurn()
        turtle.dig()
        turtle.forward()
        firstTurn()
    else
        secondTurn()
        turtle.dig()
        turtle.forward()
        secondTurn()
    end
end