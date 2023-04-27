--non gui server that grabs items from input chests
-- and puts them into storage chests
-- it also listens on the wired network for commands from 
-- an inventory terminal. It can retrieve items from storage, 
-- resort/regenerate contents, report contents, and more
--item slots are handled like a stack

local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")
local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local stackBuilder = require(settings.get("require.api_path") .. "utils.stack")
local databaseBuilder = require(settings.get("require.api_path") .. "utils.disk-database")
local logBuilder = require(settings.get("require.api_path") .. "utils.log")
local itemConstants = require(settings.get("require.api_path") .. "constants.minecraft-items")

print("setting up item DB")
local itemDBDirName = "/data/storage-server/item-db"
local itemDB = nil
if(fs.exists(fs.combine(itemDBDirName, databaseBuilder.configFileName))) then
    itemDB = databaseBuilder.load(itemDBDirName)
else
    itemDB = databaseBuilder.new(itemDBDirName)
end

function itemDB.action.createRecord(chestName, chestSlot, itemCount)
    local record = {}
    record.chestName = chestName
    record.chestSlot = chestSlot
    record.itemCount = itemCount
    return record
end

function itemDB.initItemTableActions(itemTable)
    function itemTable.action.generateKey(chestName, chestSlot)
        return chestName .. ":" .. chestSlot
    end
    function itemTable.action.generateKeyFromRecord(record)
        return itemTable.action.generateKey(record.chestName, record.chestSlot)
    end
    function itemTable.action.addRecord(record)
        local key = itemTable.action.generateKeyFromRecord(record)
        itemTable.recordHashMap.insert(key, record)
        itemTable.tableData.slotCount = itemTable.tableData.slotCount + 1
        itemTable.tableData.itemCount = itemTable.tableData.itemCount + record.itemCount
        return key, record
    end
    function itemTable.action.addNewRecord(chestName, chestSlot, itemCount)
        local record = itemDB.action.createRecord(chestName, chestSlot, itemCount)
        return itemTable.action.addRecord(record)
    end
    function itemTable.action.getRecord(chestName, chestSlot)
        local key = itemTable.action.generateKey(chestName, chestSlot)
        return key, itemTable.recordHashMap.get(key)
    end
    function itemTable.action.calculateFreeSpace(record)
        return itemConstants[itemTable.name].stackSize - record.itemCount
    end
    function itemTable.action.getRecordWithFreeSpace()
        if(itemTable.tableData.currentRecordKey) then
            local currentRecord = itemTable.recordHashMap.get(itemTable.tableData.currentRecordKey)
            if(currentRecord and currentRecord.itemCount < itemConstants[itemTable.name].stackSize) then
                return currentRecord, itemTable.action.calculateFreeSpace(currentRecord)
            end
        end
        return nil
    end
    function itemTable.action._removeRecord(record)
        local key = itemTable.action.generateKeyFromRecord(record)
        itemTable.recordHashMap.remove(key)
    end
    function itemTable.action.removeRecord(chestName, chestSlot)
        local key = itemTable.action.generateKey(chestName, chestSlot)
        itemTable.recordHashMap.remove(key)
    end
    function itemTable.action.addToRecord(record, itemCount)
        if(itemCount + record.itemCount >= itemConstants[itemTable.name].stackSize) then
            --filled up slot
            record.itemCount = record.itemCount + itemConstants[itemTable.name].stackSize
            itemTable.tableData.itemCount = itemTable.tableData.itemCount + itemConstants[itemTable.name].stackSize
            itemTable.tableData.currentRecordKey = nil
            return itemConstants[itemTable.name].stackSize
        else
            --not filled up
            record.itemCount = record.itemCount + itemCount
            itemTable.tableData.itemCount = itemTable.tableData.itemCount + itemCount
            itemTable.tableData.currentRecordKey = itemTable.action.generateKeyFromRecord(record)
            return itemCount
        end
    end
    function itemTable.action.removeFromRecord(record, itemCount)
        if(record.itemCount - itemCount < 0) then
            error("unable to remove items from this record due to underflow: " ..textutils.serialize(record) .. " " .. itemCount)
        elseif(record.itemCount - itemCount == 0) then
            --freed up a slot
            itemTable.action._removeRecord(record)
            itemTable.tableData.itemCount = itemTable.tableData.itemCount - itemCount
            itemTable.tableData.currentRecordKey = nil
        else
            --slot still has items
            record.itemCount = record.itemCount - itemCount
            itemTable.tableData.itemCount = itemTable.tableData.itemCount - itemCount
            itemTable.tableData.currentRecordKey = itemTable.action.generateKeyFromRecord(record)
        end
    end
    function itemTable.action.setRecordItemCount(record, itemCount)
        if(itemCount > record.itemCount) then
            itemTable.action.addToRecord(record, itemCount - record.itemCount)
        elseif(itemCount < record.itemCount) then
            itemTable.action.removeFromRecord(record, record.itemCount - itemCount)
        end
    end
end
--load table actions for preexisting tables
for itemName, itemTable in pairs(itemDB.tableHashMap._data) do
    itemDB.initItemTableActions(itemTable)
end

function itemDB.action.createTable(itemName)
    local itemTable = itemDB.createTable(itemName)
    itemTable.tableData.itemCount = 0
    itemTable.tableData.slotCount = 0
    itemTable.tableData.currentRecordKey = nil
    itemDB.initItemTableActions(itemTable)
    return itemTable
end
function itemDB.action.getTable(itemName)
    return itemDB.tableHashMap.get(itemName)
end
function itemDB.action.removeTable(itemName)
    itemDB.removeTable(itemName)
end

print("load pnetwork config")
--load pnetwork chest config
local pnetworkFile = fs.open("/data/storage-server/pnetwork_config.json", "r")
local pnetworkConfig = textutils.unserialize(pnetworkFile.readAll())
pnetworkFile.close()

local storageSystem = {}
storageSystem.chestGroups = {}
function storageSystem.chestGroups.createChest(permName, pWrap, length, lastSlot)
    local chest = {
        name = permName,
        pWrap = pWrap,
        length = length,
        lastSlot = lastSlot or 0
    }
    return chest
end
function storageSystem.chestGroups.createChestGroup(pName)
    local chestList = listBuilder.new(pName)
    local i = 1
    for _name, configChest in pairs(pnetworkConfig.groupList[pName].members) do
        if(configChest)
        then
            local tempWrap = peripheral.wrap(configChest.permName)
            chestList.add(
                storageSystem.chestGroups.createChest(
                    configChest.permName, 
                    tempWrap, 
                    tempWrap.size()
                )
            )
        end
    end
    return chestList
end
storageSystem.chestGroups.inputChestList = storageSystem.chestGroups.createChestGroup("input-chests") --input
storageSystem.chestGroups.outputChestList = storageSystem.chestGroups.createChestGroup("output-chests") --output
storageSystem.chestGroups.allRasChestList = storageSystem.chestGroups.createChestGroup("all-ras-chests") --ras

function storageSystem.chestGroups.initChestTableActions(chestTable)
    function chestTable.action.addChest(chestName, allRasIndex)
        chestTable.recordHashMap.insert(chestName, allRasIndex)
    end
    function chestTable.action.removeChest(chestName)
        chestTable.recordHashMap.remove(chestName)
    end
end
local chestDBDirName = "/data/storage-server/chest-db"
if(fs.exists(fs.combine(chestDBDirName, databaseBuilder.configFileName))) then
    storageSystem.chestGroups.chestDB = databaseBuilder.load(chestDBDirName)
    --load table actions for preexisting tables
    for chestName, chestTable in pairs(storageSystem.chestGroups.chestDB.tableHashMap._data) do
        storageSystem.chestGroups.initChestTableActions(chestTable)
    end
else
    storageSystem.chestGroups.chestDB = databaseBuilder.new(chestDBDirName)
    local avaRasChestsTable = storageSystem.chestGroups.chestDB.createTable("avalible-ras-chests")
    storageSystem.chestGroups.initChestTableActions(avaRasChestsTable)

    --add all avalible chests in rasChestList
    local startIndex = storageSystem.chestGroups.allRasChestList.currentIndex
    local currentIndex = storageSystem.chestGroups.allRasChestList.currentIndex
    repeat
        local chestObj = storageSystem.chestGroups.allRasChestList.get(currentIndex)
        if(#chestObj.pWrap.list() < chestObj.pWrap.size())then
            --only if there is an open slot
            avaRasChestsTable.action.addChest(chestObj.name, currentIndex)
        end
        currentIndex = storageSystem.chestGroups.allRasChestList.nextIndex()
    until currentIndex == startIndex
    avaRasChestsTable.save()
end
function storageSystem.chestGroups.chestDB.action.getAvalibleRasChests()
    return storageSystem.chestGroups.chestDB.tableHashMap.get("avalible-ras-chests")
end

function storageSystem.findFreeChestSlot()
    local avaRasChestTable = storageSystem.chestGroups.chestDB.action.getAvalibleRasChests()
    for chestName, allRasIndex in pairs(avaRasChestTable.recordHashMap._data) do
        local chestObj = storageSystem.chestGroups.allRasChestList.get(allRasIndex)
        local chestData = chestObj.pWrap.list()
        if(#chestData < chestObj.pWrap.size()) then
            --there are some free slots, find them
            if(#chestData == 0) then
                return chestObj, 1
            end
            for slotIndex, item in pairs(chestData) do
                if(chestData[slotIndex] == nil or chestData[slotIndex].count == 0) then
                    return chestObj, slotIndex
                end
            end
        end
    end
    error("no free chest slots!!!!!")
end

function storageSystem.addToRAS(itemName, sourceChestObj, sourceChestSlot, sourceItemCount)
    --check if there is already a table for this item
    local itemTable = itemDB.action.getTable(itemName)
    if(itemTable == nil) then
        --create a new table
        itemTable = itemDB.action.createTable(itemName)
    end

    --local itemsLeftToTransfer = sourceItemCount
    local targetRecord, freeSpace = itemTable.action.getRecordWithFreeSpace()
    if(not targetRecord or freeSpace == 0) then
        --find a new chest slot
        local chestObj, slotIndex = storageSystem.findFreeChestSlot()
        local key = nil
        key, targetRecord = itemTable.action.addNewRecord(chestObj.name, slotIndex, 0)
    end

    local itemsToTransfer = itemConstants[itemName].stackSize - targetRecord.itemCount
    local itemCountInSlotBeforeTransfer = targetRecord.itemCount

    --add to db record
    local itemsPushingCount = itemTable.action.addToRecord(targetRecord, itemsToTransfer)

    --do transfer between chests
    local itemsTransferedCount = sourceChestObj.pWrap.pushItems(targetRecord.chestName,sourceChestSlot, itemsPushingCount, targetRecord.chestSlot)
    if(itemsTransferedCount ~= itemsPushingCount) then
        itemTable.action.setRecordItemCount(targetRecord, itemsTransferedCount + itemCountInSlotBeforeTransfer)
    end

    --only after successful transfer do we save
    itemTable.save()
end

local function removeItemsFromDB(itemName, chestName, chestSlot, itemCount) --old
    expect(1, itemName, "string")
    expect(2, chestName, "string")
    expect(3, chestSlot, "number")
    expect(4, itemCount, "number")

    local itemTable = itemDB.action.getTable(itemName)
    if(not itemTable) then
        error("unable to find a table for " .. itemName)
    end

    local key, record = itemTable.action.getRecord(chestName, chestSlot)
    if(not record) then
        error("no record found matching: " .. key .. " for item: " .. itemName)
    end
    
    if(itemCount > record.itemCount) then
        error("unable to remove more items then what is held in the record for " .. itemTable.name .. " " .. key)
    elseif(itemCount == record.itemCount) then
        --remove record
        itemTable.action.removeRecord(chestName, chestSlot)
    else
        --deduct from record
        record.itemCount = record.itemCount - itemCount
    end
    itemTable.save()
end



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

local function isEmptySlot(slotObj)
    return slotObj == nil or slotObj.count == 0
end
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

--needs editing since we need to know which chest it puts stuff into
local function dropIntoChestList(chestList, sourceName, sourceSlot, desiredAmount)
    local startPoint = chestList.lastIndex
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


print("starting normal operations")
while true do
    local inputChestIndex, inputChestSlotIndex, avalibleItemCount, itemName = findNextChestSlotWithCriteria(storageSystem.chestGroups.inputChestList, isNonEmptySlot)
    if((not (inputChestIndex == -1)) and avalibleItemCount > 0) then
        storageSystem.addToRAS(itemName,storageSystem.chestGroups.inputChestList.get(inputChestIndex), inputChestSlotIndex, avalibleItemCount)
        --do I need to make this work in parallel? saving the file will have to be in series
    end
end