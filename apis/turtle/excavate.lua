--v0.0.1
--for escavating large rectangular prisms

--assumes the turtle is starting at the 0,0,0 point of the rectangular prism
-- X, Y, and Z are all relative to the starting point of the turtle at 0,0,0
-- X is for right (+) and left (-)
-- Y is forward (+) and backward (-)
-- Z is up (+) and down (-)

local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()

local excavate = {}

--digging in virtical columns 2 long 1 wide
function excavate.digRectPrismV(X_LIMIT, Y_LIMIT, Z_LIMIT, GO_HOME)
    expect(1,X_LIMIT, "number")
    expect(2,Y_LIMIT, "number")
    expect(3,Z_LIMIT, "number")
    expect(4,GO_HOME, "boolean", "nil")
    if(GO_HOME == nil)then GO_HOME = true end

    if(X_LIMIT * Y_LIMIT * Z_LIMIT == 0)
    then
        error("zero is not an accepted value", 2)
    end

    local digFront = robox.dig
    local firstDig = {}
    local firstMove = {}
    local firstMoveWithDig = {}
    local secondDig = {}
    local secondMove = {}
    local secondMoveWithDig = {}
    if(Z_LIMIT > 0)
    then
        firstDig = robox.digUp
        firstMove = robox.up
        firstMoveWithDig = robox.upWithDig
        secondDig = robox.digDown
        secondMove = robox.down
        secondMoveWithDig = robox.downWithDig
    else
        Z_LIMIT = math.abs(Z_LIMIT) -- since we normalized the directions
        firstDig = robox.digDown
        firstMove = robox.down
        firstMoveWithDig = robox.downWithDig
        secondDig = robox.digUp
        secondMove = robox.up
        secondMoveWithDig = robox.upWithDig
    end

    local firstTurn = {}
    local secondTurn = {}
    local holeIsBehindYou = false

    if(Y_LIMIT > 0)
    then
        if(X_LIMIT > 0)
        then
            firstTurn = robox.turnRight
            secondTurn = robox.turnLeft
        else
            X_LIMIT = math.abs(X_LIMIT) -- since we normalized the directions
            firstTurn = robox.turnLeft
            secondTurn = robox.turnRight
        end
    else
        --turn around, hole is behind you
        holeIsBehindYou = true
        Y_LIMIT = math.abs(Y_LIMIT) -- since we normalized the directions
        robox.turnRight(2)
        if(X_LIMIT > 0)
        then
            firstTurn = robox.turnLeft
            secondTurn = robox.turnRight
        else
            X_LIMIT = math.abs(X_LIMIT) -- since we normalized the directions
            firstTurn = robox.turnRight
            secondTurn = robox.turnLeft
        end
    end

    local function singleDig(start, limit, moveWithDig)
        for i = start, limit, 1 
        do
            moveWithDig(1)
        end
    end
    local function doubleDig(start, limit, moveWithDig)
        for i = start, limit, 1 
        do
            digFront()
            moveWithDig(1)
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
            local moveWithDig = {}
            if(isAwayFromZ)
            then
                moveWithDig = secondMoveWithDig
            else
                moveWithDig = firstMoveWithDig
            end
            if(Y_POSITION == Y_LIMIT)
            then
                singleDig(1, Z_LIMIT-1, moveWithDig)
                Y_POSITION = Y_POSITION + 1 --TODO
            else
                doubleDig(1, Z_LIMIT-1, moveWithDig)
                Y_POSITION = Y_POSITION + 2
                robox.forwardWithDig(1)
                if(Y_POSITION <= Y_LIMIT)
                then
                    robox.forwardWithDig(1)
                end
            end
            isAwayFromZ = not isAwayFromZ
        end

        if(X_POSITION == X_LIMIT)
        then
            --we are done
            --return home
            if(GO_HOME)then
                if(isAwayFromZ)
                then
                    --return to z = 1
                    secondMove(Z_LIMIT-1)
                end
                if(X_LIMIT % 2 == 1 and Y_LIMIT > 1)
                then
                    --return to y = 1
                    firstTurn(2)
                    robox.forward( Y_LIMIT-1)
                end
                
                if(X_LIMIT > 1)
                then
                    firstTurn()
                    robox.forward(X_LIMIT-1)
                    firstTurn()
                end
                
                if(holeIsBehindYou)
                then
                    robox.turnRight(2)
                end
            end
            print("Done")
        elseif(X_POSITION % 2 == 1)
        then
            firstTurn()
            robox.forwardWithDig(1)
            firstTurn()
        else
            secondTurn()
            robox.forwardWithDig(1)
            secondTurn()
        end
    end
end

--digs rectangular prisms in 3 high 1 wide horizontal tunnels
function excavate.digRectPrismH(X_LIMIT, Y_LIMIT, Z_LIMIT, GO_HOME)
    expect(1,X_LIMIT, "number")
    expect(2,Y_LIMIT, "number")
    expect(3,Z_LIMIT, "number")
    expect(4,GO_HOME, "boolean", "nil")
    if(GO_HOME == nil)then GO_HOME = true end

    local firstTurn = {}
    local secondTurn = {}
    local firstZMove = {}
    local secondZMove = {}
    local firstZDig = {}
    local secondZDig = {}
    local firstZMoveWithDig = {}

    if(X_LIMIT * Y_LIMIT * Z_LIMIT == 0)
    then
        error("zero is not an accepted value", 2)
    end

    --define some functions
    local function digTunnel3(count)
        for i = 1, count, 1
        do
            robox.forwardWithDig(1)
            robox.digUp()
            robox.digDown()
        end
    end
    local function digTunnel2High(count)
        for i = 1, count, 1
        do
            robox.forwardWithDig(1)
            robox.digUp()
        end
    end
    local function digTunnel2Low(count)
        for i = 1, count, 1
        do
            robox.forwardWithDig(1)
            robox.digDown()
        end
    end
    local function digTunnel1(count)
        robox.forwardWithDig(count)
    end

    local function digLevel(digTunnel)
        for x = 1, X_LIMIT-1, 1
        do
            digTunnel(Y_LIMIT-1)
            if(x%2 == 1)
            then
                firstTurn()
                digTunnel(1)
                firstTurn()
            else
                secondTurn()
                digTunnel(1)
                secondTurn()
            end
        end
        digTunnel(Y_LIMIT-1)
    end

    --setup moving and digging functions based on desired shape relative to starting point
    if(Y_LIMIT > 0)
    then
        if(X_LIMIT > 0)
        then
            firstTurn = robox.turnRight
            secondTurn = robox.turnLeft
        else
            X_LIMIT = math.abs(X_LIMIT)
            firstTurn = robox.turnLeft
            secondTurn = robox.turnRight
        end
    else
        --turn around, the rectPrisim is behind you
        robox.turnRight(2)
        Y_LIMIT = math.abs(Y_LIMIT)
        if(X_LIMIT > 0)
        then
            firstTurn = robox.turnLeft
            secondTurn = robox.turnRight
        else
            X_LIMIT = math.abs(X_LIMIT)
            firstTurn = robox.turnRight
            secondTurn = robox.turnLeft
        end
    end

    local digTunnel2
    if(Z_LIMIT > 0)
    then
        digTunnel2 = digTunnel2Low
        firstZMove = robox.up
        secondZMove = robox.down
        firstZDig = robox.digUp
        firstZMoveWithDig = robox.upWithDig
    else
        digTunnel2 = digTunnel2High
        Z_LIMIT = math.abs(Z_LIMIT)
        firstZMove = robox.down
        secondZMove = robox.up
        firstZDig = robox.digDown
        firstZMoveWithDig = robox.downWithDig
    end

    

    local Z_PASSES = 0
    local z = 0
    while(z < Z_LIMIT)
    do
        Z_PASSES = Z_PASSES + 1
        local z_diff = Z_LIMIT - z
        --get into position
        if(z_diff >= 2)
        then
            firstZMoveWithDig(1)
            firstZDig()
        end

        if(z_diff >= 3)
        then
            digLevel(digTunnel3)
            z = z + 3
            if(z < Z_LIMIT)
            then
                --get into position for next level
                firstZMoveWithDig(2)
            end
        elseif(z_diff == 2)
        then
            digLevel(digTunnel2)
            z = z + 2
        elseif(z_diff == 1)
        then
            digLevel(digTunnel1)
            z = z + 1
        else
            error("nothing to dig")
        end

        if(X_LIMIT %2 == 1)
        then
            secondTurn(2)
        else
            firstTurn(2)
            local temp = firstTurn
            firstTurn = secondTurn
            secondTurn = temp
        end

    end

    --go home
    if(GO_HOME)then
        if(Z_LIMIT > 1) then secondZMove(Z_LIMIT-1) end
        if(Z_PASSES % 2 == 1)
        then
            if(X_LIMIT % 2 == 1)
            then
                --at opposite corner
                if(Y_LIMIT > 1 )then robox.forward(Y_LIMIT-1) end
                firstTurn()
                if(X_LIMIT > 1) then robox.forward(X_LIMIT-1) end
                firstTurn()
            else
                --at adjacent corner
                firstTurn()
                if(X_LIMIT > 1) then robox.forward(X_LIMIT-1) end
                secondTurn()
            end
        end
    end
end

function excavate.digRectPrism(X_LIMIT, Y_LIMIT, Z_LIMIT, GO_HOME)
    expect(1,X_LIMIT, "number")
    expect(2,Y_LIMIT, "number")
    expect(3,Z_LIMIT, "number")
    expect(4,GO_HOME, "boolean", "nil")
    if(GO_HOME == nil)then GO_HOME = true end

    if(X_LIMIT * Y_LIMIT * Z_LIMIT == 0)
    then
        error("zero is not an accepted value", 2)
    end

    local z = math.abs(Z_LIMIT)
    if(math.abs(X_LIMIT) > z or math.abs(Y_LIMIT) > z)
    then
        excavate.digRectPrismH(X_LIMIT, Y_LIMIT, Z_LIMIT, GO_HOME)
    else
        excavate.digRectPrismV(X_LIMIT, Y_LIMIT, Z_LIMIT, GO_HOME)
    end
end

return excavate