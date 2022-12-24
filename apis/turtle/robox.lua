--api wrapper for turtle functionality
--main changes are:
-- - most commands like movement commands can take an argument count (number) for the number of times that it should be done 
-- - movement commands will error instead of returning false

--future changes may include:
-- - better tool for turtle inventory management
-- - configurable refuel mechanics

local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local roboxBuilder = {}

local function standardActionWithForced(actionFunc, count)
    count = count or 1
    range(count, 1)

    local success = false
    local message = ""
    for i=1, count, 1
    do
        success, message = actionFunc()
    end
    return success, message
end
local function standardActionWithStop(actionFunc, count)
    count = count or 1
    range(count, 1)

    for i=1, count, 1
    do
        local success, reason = actionFunc()
        if(not success)
        then
            return success, reason
        end
    end
    return true
end
local function standardActionWithError(actionFunc, count, name)
    count = count or 1
    range(count, 1)
    for i=1, count, 1
    do
        local success, reason = actionFunc()
        if(not success)
        then
            error("Unable to complete" .. name .. " at count=" .. i .. " due to " .. reason, 2)
        end
    end
end

local function setupMoveWithDig(move, dig, tryCount)
    local function _moveWithDig()
        local success = false
        local message = ""
        for i = 1, tryCount, 1
        do
            dig()
            success, message = move()
            if(success)
            then
                return true
            end
        end
        return success, message
    end
    return _moveWithDig
end


local function setMovementMode(robox, actionMode)
    function robox.forward(count)
        return actionMode(turtle.forward, count, "forward")
    end
    robox.fw = robox.forward

    function robox.backward(count)
        return actionMode(turtle.backward, count, "backward")
    end
    robox.bw = robox.backward

    function robox.up(count)
        return actionMode(turtle.up, count, "up")
    end
    
    function robox.down(count)
        return actionMode(turtle.down, count, "down")
    end
    robox.dw = robox.down
    
    function robox.turnLeft(count)
        return actionMode(turtle.turnLeft, count, "left")
    end
    robox.tl = robox.turnLeft
    
    function robox.turnRight(count)
        return actionMode(turtle.turnRight, count, "right")
    end
    robox.tr = robox.turnRight

    function robox.forwardWithDig(count, tryCount)
        return actionMode(setupMoveWithDig(turtle.forward, turtle.dig, tryCount or robox.DIG_TRY_LIMIT), count, "forwardWithDig")
    end

    function robox.upWithDig(count, tryCount)
        return actionMode(setupMoveWithDig(turtle.up, turtle.digUp, tryCount or robox.DIG_TRY_LIMIT), count, "upWithDig")
    end

    function robox.downWithDig(count, tryCount)
        return actionMode(setupMoveWithDig(turtle.down, turtle.digDown, tryCount or robox.DIG_TRY_LIMIT), count, "downWithDig")
    end
end


function roboxBuilder.configure(config)
    expect(1, config, "table", "nil")
    local robox = {}
    robox.configReadOnly = config
    if(config and config.DIG_TRY_LIMIT)
    then
        robox.DIG_TRY_LIMIT = config.DIG_TRY_LIMIT
    else
        robox.DIG_TRY_LIMIT = 30
    end
    if(config and config.MOVEMENT_MODE)
    then
        local switch = {
            ["forced"] = function () setMovementMode(robox, standardActionWithForced) end,
            ["stop"] = function () setMovementMode(robox, standardActionWithStop) end,
            ["error"] = function () setMovementMode(robox, standardActionWithError) end,
        }
        local result = switch(config.MOVEMENT_MODE)
        if(result) then result()
        else error("Not a valid movementMode: " .. config.MOVEMENT_MODE, 2) end
    else
        setMovementMode(robox, standardActionWithError)
    end

    --may write more configuration code in the future

    robox.dig = turtle.dig
    robox.digUp = turtle.digUp
    robox.digDown = turtle.digDown
    robox.attack = turtle.attack
    robox.attackUp = turtle.attackUp
    robox.attackDown = turtle.attackDown

    robox.equiptLeft = turtle.equiptLeft
    robox.equiptRight = turtle.equiptRight

    robox.place = turtle.place
    robox.placeUp = turtle.placeUp
    robox.placeDown = turtle.placeDown

    robox.suck = turtle.suck
    robox.suckUp = turtle.suckUp
    robox.suckDown = turtle.suckDown
    robox.drop = turtle.drop
    robox.dropUp = turtle.dropUp
    robox.dropDown = turtle.dropDown

    robox.detect = turtle.detect
    robox.detectUp = turtle.detectUp
    robox.detectDown = turtle.detectDown

    robox.select = turtle.select
    robox.getSelectedSlot = turtle.getSelectedSlot
    robox.getItemCount = turtle.getItemCount
    robox.getItemSpace = turtle.getItemSpace
    robox.getItemDetail = turtle.getItemDetail
    robox.transferTo = turtle.compareTo
    robox.compare = turtle.compare
    robox.compareUp = turtle.compare
    robox.compareDown = turtle.compareDown
    robox.compareTo = turtle.compareTo
    robox.craft = turtle.craft

    robox.inspect = turtle.inspect
    robox.inspectUp = turtle.inspectUp
    robox.inspectDown = turtle.inspectDown

    robox.getFuelLevel = turtle.getFuelLevel
    robox.getFuelLimit = turtle.getFuelLimit
    robox.refuel = turtle.refuel --may want to configure this

    return robox
end
local defaultRobox = roboxBuilder.configure()
return defaultRobox, roboxBuilder