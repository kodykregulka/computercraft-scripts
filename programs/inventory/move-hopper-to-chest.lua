--hello
local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")
local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local logBuilder = require(settings.get("require.api_path") .. "utils.log")

local pnetworkFile = fs.open("/pnetwork_config.json", "r")
local pnetworkConfig = textutils.unserialize(pnetworkFile.readAll())

local chestBuilder = {}
function chestBuilder.new(permName, pWrap, length, lastSlot)
    local chest = {
        name = permName,
        pWrap = pWrap,
        length = length,
        lastSlot = lastSlot or 0
    }
    return chest
end

local function groupBuilder(pName)
    local chestList = listBuilder.new(pName)
    local i = 1
    for _name, configChest in pairs(pnetworkConfig.groupList[pName].members) do
        if(configChest)
        then
            local tempWrap = peripheral.wrap(configChest.permName)
            chestList.add(
                chestBuilder.new(
                    configChest.permName, 
                    tempWrap, 
                    tempWrap.size()
                )
            )
        end
    end
    return chestList
end

local inputChestList = groupBuilder("chest-input")
local outputChestList = groupBuilder("chest-output")
local waterHopperList = groupBuilder("water-hopper");

local function isNonEmptySlot(slotObj)
    if(slotObj ~= nil) then
        return slotObj.count > 0
    end
    return false
end

local function nextSlot(slotNumber, length)
    if(length == 0)
    then
        return 0
    elseif(slotNumber == length)
    then
        return 1
    else
        return slotNumber + 1
    end
end

local function findNextSlotWithCriteria(iWrap, startSlot, criteriaFunc)
    startSlot = startSlot or 1
    local slotIndex = startSlot
    local slotList = iWrap.list()
    local inventorySize = iWrap.size()

    repeat
        if(criteriaFunc(slotList[slotIndex]))
        then
            --found a match
            local slot = slotList[slotIndex]
            local itemName = nil
            local itemCount = 0
            if(slot) then
                itemCount = slot.count
                itemName = slot.name
            end
            return slotIndex, itemCount, itemName
        end
        slotIndex = nextSlot(slotIndex, inventorySize)
    until (slotIndex == startSlot)
    return -1
end
local function findNextChestSlotWithCriteria(chestList, criteriaFunc)
    local startPoint = chestList.currentIndex
    local chestIndex = startPoint
    repeat
        local chest = chestList.get(chestIndex)
        local slotIndex, itemCount, itemName = findNextSlotWithCriteria(chest.pWrap, nextSlot(chest.lastSlot, chest.length), criteriaFunc)
        if(slotIndex > 0)
        then
            chest.lastSlot = slotIndex
            return chestIndex, slotIndex, itemCount, itemName
        end
        chestIndex = chestList.nextIndex()
    until (chestIndex == startPoint)
    return -1, -1
end

local function dropIntoChestList(chestList, sourceName, sourceSlot, desiredAmount)
    local startPoint = chestList.currentIndex
    local chestIndex = startPoint
    local transferedAmount = 0
    local sourceWrap = peripheral.wrap(sourceName)
    local sourceSlotInfo = sourceWrap.getItemDetail(sourceSlot)
    if(sourceSlotInfo == nil) 
    then
        --nothing left to do, it is already empty
        return 0
    end
    desiredAmount = desiredAmount or sourceSlotInfo.count
    repeat
        local transferedAmount = transferedAmount + chestList.get(chestIndex).pWrap.pullItems(sourceName, sourceSlot, desiredAmount - transferedAmount)
        if(transferedAmount >= desiredAmount)then
            return transferedAmount
        else
            chestIndex = chestList.nextIndex()
        end
    until (chestIndex == startPoint)
    return transferedAmount
end


while true do
    local waterHopperIndex, waterHopperSlotIndex, avalibleItemCount, itemName = findNextChestSlotWithCriteria(waterHopperList, isNonEmptySlot)
    if((not (waterHopperIndex == -1)) and avalibleItemCount > 0) then
        print("transfer")
        dropIntoChestList(inputChestList, waterHopperList.get(waterHopperIndex).name,waterHopperSlotIndex)
        inputChestList.nextIndex()
    end
end
