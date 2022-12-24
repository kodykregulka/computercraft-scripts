--kelp-crafter startup
--only starts up when you have 9 stacks in the input chest 

local failCount = 0
local FAIL_LIMIT = 6
local STACK_LIMIT = 64
local logFile = fs.open("kelp-crafter.log", "w")
local hasSucceeded = false

local getItem = turtle.suckUp
local returnItem = turtle.dropUp
local putItem = turtle.dropDown
local throwItem = turtle.drop

print("")
print("- kelp-crafter program -")
print("hold down ctr + T to exit program without shutdown")

local function logMessage(message)
    print(message) 
    logFile.write(message .. "\n")
end

-- 6,7,8,10,11,12,14,15,16
local function craftBlockLow()
    --crafts a block in the bottom right corner
    --remainder items go in the bottom right slot

    local itemCount = turtle.getItemCount(1) + turtle.getItemCount(16)
    local craftableCount = math.floor(itemCount/9)

    if(itemCount <= 64)
    then
        turtle.select(16)
        turtle.transferTo(1)
    end

    turtle.select(1)
    for i = 6, 16, 1
    do
        if((i) % 4 ~= 1)then
            if(i == 8) --after second transfer it is safe to empty remainder slot into source
            then
                turtle.select(16)
                turtle.transferTo(1)
                turtle.select(1)
            end
            turtle.transferTo(i, craftableCount)
        end
    end
    turtle.transferTo(16) --transfer remainder of source to last slot

    turtle.craft()
    turtle.select(1) --crafted block should be here
    putItem() --put dried kelp block into return chest

end


while failCount < FAIL_LIMIT do
    --assemble items
    for i = 1, 11, 1
    do
        if((i) % 4 ~= 0)then
            turtle.select(i)
            local currentCount = 0
            local slot = turtle.getItemDetail(i)
            if(slot == nil)
            then
                currentCount = 0
            elseif(slot.name == "minecraft:dried_kelp")
            then
                currentCount = slot.count
            else
                --cant craft with this item, just pass it through
                putItem()
            end

            if(currentCount < STACK_LIMIT) then
                local success, reason = getItem(STACK_LIMIT - currentCount)
                if(not success)then
                    failCount = failCount + 1
                    logMessage("failed to pull stack down " ..  reason)
                    break
                end
                slot = turtle.getItemDetail(i)
                if(slot == nil)then
                    failCount = failCount + 1
                    logMessage("nothing in slot after pulling")
                    break
                end
                if(slot.name ~= "minecraft:dried_kelp") then
                    putItem() --get rid of it
                    failCount = failCount + 1
                    logMessage("pulled down an incorrect item of type: " .. slot.name)
                    break
                end
                currentCount = slot.count
                if(currentCount < STACK_LIMIT) then
                   failCount = failCount + 1
                   logMessage("Did not pull enough items in: " .. slot.count)
                   break
                end
            end
        end
    end

    --craft
    local success, reason = turtle.craft()
    if(not success) then
        local EMPTYSLOTS = {}
        EMPTYSLOTS[1] = 4
        EMPTYSLOTS[2] = 8
        EMPTYSLOTS[3] = 12
        EMPTYSLOTS[4] = 13
        EMPTYSLOTS[5] = 14
        EMPTYSLOTS[6] = 15
        EMPTYSLOTS[7] = 16
        --try to fix
        for i = 1, 7, 1 do
            --remove any items in these slots
            turtle.select(EMPTYSLOTS[i])
            local slot = turtle.getItemDetail()
            if(slot == nil)then
                --good, it is empty
            elseif(slot.name == "minecraft:dried_kelp")
            then
                local success, returnMessage = returnItem()
                if(not success) then
                    logMessage("failed to return item due to: " .. returnMessage)
                    local success, putMessage = putItem()
                    if(not success)then
                        logMessage("failed to pass item along due to: " .. putMessage)
                        local success, throwMessage = throwItem()
                        if(not success)then
                            logMessage("Unable to get rid of item due to: " .. throwMessage)
                            break
                        end
                    end
                end
            end
        end
        --try one more time
        local success, reason = turtle.craft()
        if(not success) then
            logMessage("failed to craft due to: " .. reason)
            failCount = failCount + 1
        end
    end
end

if(failCount >= FAIL_LIMIT) then
    logMessage("Failed too many times: " .. failCount)
    os.sleep(5)
    logFile.close()
end
