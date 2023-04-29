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
    function itemTable.action.getCurrentRecord()
        if(itemTable.tableData.currentRecordKey) then
            return itemTable.recordHashMap.get(itemTable.tableData.currentRecordKey)
        else
            return nil
        end
    end
    function itemTable.action.calculateFreeSpace(record)
        return itemConstants[itemTable.name].stackSize - record.itemCount
    end
    function itemTable.action.getRecordWithFreeSpace()
        local currentRecord = itemTable.action.getCurrentRecord()
        if(currentRecord and currentRecord.itemCount < itemConstants[itemTable.name].stackSize) then
            return currentRecord, itemTable.action.calculateFreeSpace(currentRecord)
        else
            return nil
        end
    end
    function itemTable.action._removeRecordWithKey(key)
        local record = itemTable.recordHashMap.get(key)
        if(record)then
            itemTable.recordHashMap.remove(key)
            itemTable.tableData.slotCount = itemTable.tableData.slotCount - 1
            itemTable.tableData.itemCount = itemTable.tableData.itemCount - record.itemCount
            itemTable.tableData.currentRecordKey = nil
        end
    end
    function itemTable.action._removeRecord(record)
        local key = itemTable.action.generateKeyFromRecord(record)
        itemTable.action._removeRecordWithKey(key)
    end
    function itemTable.action.removeRecord(chestName, chestSlot)
        local key = itemTable.action.generateKey(chestName, chestSlot)
        itemTable.action._removeRecordWithKey(key)
    end
    function itemTable.action.addToRecord(record, itemCount)
        if(itemCount + record.itemCount >= itemConstants[itemTable.name].stackSize) then
            --filled up slot
            local itemsToAdd = itemConstants[itemTable.name].stackSize - record.itemCount
            record.itemCount = itemConstants[itemTable.name].stackSize
            itemTable.tableData.itemCount = itemTable.tableData.itemCount + itemsToAdd
            itemTable.tableData.currentRecordKey = nil
            return itemsToAdd
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
            return true
        else
            --slot still has items
            record.itemCount = record.itemCount - itemCount
            itemTable.tableData.itemCount = itemTable.tableData.itemCount - itemCount
            itemTable.tableData.currentRecordKey = itemTable.action.generateKeyFromRecord(record)
            return false
        end
    end
    function itemTable.action.setRecordItemCount(record, itemCount)
        if(itemCount > record.itemCount) then
            itemTable.action.addToRecord(record, itemCount - record.itemCount)
        elseif(itemCount < record.itemCount) then
            itemTable.action.removeFromRecord(record, record.itemCount - itemCount)
        end
    end
    function itemTable.action.fixRecord(record)
        local pWrapChest = peripheral.wrap(record.chestName)
        if(not pWrapChest) then
            error("record for chest that does not exist: " + record.chestName)
        end

        local item = pWrapChest.getItemDetail(record.chestSlot)
        if(not item or item.count == 0) then
            --remove record
            itemTable.action._removeRecord(record)
            return 0 --item count
        end
        itemTable.action.setRecordItemCount(record, item.count)
        return item.count
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
storageSystem.chestGroups.inputHopperGroup = storageSystem.chestGroups.createChestGroup("s1-storage-input-hoppers")
storageSystem.chestGroups["c1-storage-input-chests"] = storageSystem.chestGroups.createChestGroup("c1-storage-input-chests")
storageSystem.chestGroups["c1-storage-output-chests"] = storageSystem.chestGroups.createChestGroup("c1-storage-output-chests")
storageSystem.chestGroups.allRasChestList = storageSystem.chestGroups.createChestGroup("s1-storage-all-ras-chests")

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

function storageSystem.chestGroups.findFreeRasChestSlot()
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
    local function addToRASRecord(itemName, sourceChestObj, sourceChestSlot, sourceItemCount)
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
            local chestObj, slotIndex = storageSystem.chestGroups.findFreeRasChestSlot()
            local key = nil
            key, targetRecord = itemTable.action.addNewRecord(chestObj.name, slotIndex, 0)
            freeSpace = itemConstants[itemName].stackSize - targetRecord.itemCount 
        end

        local itemsToTransfer = freeSpace
        if(itemsToTransfer > sourceItemCount) then
            itemsToTransfer = sourceItemCount
        end
        local itemCountInSlotBeforeTransfer = targetRecord.itemCount

        --add to db record
        local itemsPushingCount = itemTable.action.addToRecord(targetRecord, itemsToTransfer)

        --do transfer between chests
        local itemsTransferedCount = sourceChestObj.pWrap.pushItems(targetRecord.chestName,sourceChestSlot, itemsPushingCount, targetRecord.chestSlot)
        if(itemsTransferedCount ~= itemsPushingCount) then
            itemTable.action.fixRecord(targetRecord)
        end

        --only after successful transfer do we save
        itemTable.save()
        return itemsTransferedCount
    end

    local itemsTransferedCount = 0
    local previousItemsTransferedCount = 0
    while true do
        previousItemsTransferedCount = itemsTransferedCount
        itemsTransferedCount = itemsTransferedCount + addToRASRecord(itemName, sourceChestObj, sourceChestSlot, sourceItemCount)
        if(itemsTransferedCount >= sourceItemCount) then
            --all good
            return 200
        elseif(previousItemsTransferedCount == itemsTransferedCount) then
            --unable to transfer? return as error
            if(itemsTransferedCount > 0) then
                --partial success
                return 206, {errorMessage = "unable to add all of the items to the RAS storage", itemsTransferedCount = itemsTransferedCount}
            else
                return 500, {errorMessage = "unable to add any of the items to the RAS storage"}
            end
        end
    end
end

function storageSystem.chestGroups.dropIntoChestList(chestList, sourceName, sourceSlot, desiredAmount)
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

function storageSystem.removeFromRAS(itemName, targetChestList, desiredItemCount)
    --return number of items transfered
    local itemTable = itemDB.action.getTable(itemName)
    if(not itemTable) then
        return 0, "unable to find a table for " .. itemName
    end

    local function removeFromRas(itemTable, targetChestList, currentRecord, desiredItemCount)
        --determine number of items
        local itemsToTransfer = currentRecord.itemCount
        if(itemsToTransfer > desiredItemCount) then
            itemsToTransfer = desiredItemCount
        end
        local itemCountInSlotBeforeTransfer = currentRecord.itemCount

        --do db transaction
        local isRecordRemoved = itemTable.action.removeFromRecord(currentRecord, itemsToTransfer)

        --do transfer between chests
        local itemsTransferedCount = storageSystem.chestGroups.dropIntoChestList(targetChestList, currentRecord.chestName, currentRecord.chestSlot, itemsToTransfer)
        if(itemsToTransfer ~= itemsTransferedCount) then
            --correct the record
            if(isRecordRemoved) then
                currentRecord.itemCount = 0
                itemTable.action.addRecord(currentRecord)
            end
            itemTable.action.fixRecord(currentRecord)
        end

        --only save after successful transfer
        itemTable.save()
        return itemsTransferedCount
    end

    local itemsTransferedInTotal = 0

    --try last/current record first, it may have a partially full slot that should go first
    local currentRecord = itemTable.action.getCurrentRecord()
    if(currentRecord and currentRecord.itemCount > 0) then
        itemsTransferedInTotal = removeFromRas(itemTable, targetChestList, currentRecord, desiredItemCount)
        if(itemsTransferedInTotal >= desiredItemCount) then
            return 200
        end
    end

    for key, record in pairs(itemTable.recordHashMap._data) do
        itemsTransferedInTotal = itemsTransferedInTotal + removeFromRas(itemTable, targetChestList, record, desiredItemCount - itemsTransferedInTotal)
        if(itemsTransferedInTotal >= desiredItemCount) then
            return 200
        end
    end

    if(itemsTransferedInTotal >= desiredItemCount) then
        return 200
    elseif(itemsTransferedInTotal > 0) then
        return 206, {errorMessage = "unable to complete the order due to insufficient items", itemsTransferedCount = itemsTransferedInTotal}
    else
        return 500, {errorMessage = "there were no items of that type in the RAS storage system"}
    end
end

function storageSystem.chestGroups.isEmptySlot(slotObj)
    return slotObj == nil or slotObj.count == 0
end
function storageSystem.chestGroups.isNonEmptySlot(slotObj)
    if(slotObj ~= nil) then
        return slotObj.count > 0
    end
    return false
end

function storageSystem.chestGroups.nextSlot(slotNumber, length)
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

function storageSystem.chestGroups.findNextSlotWithCriteria(iWrap, startSlot, criteriaFunc)
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
        slotIndex = storageSystem.chestGroups.nextSlot(slotIndex, inventorySize)
    until (slotIndex == startSlot)
    return -1
end
function storageSystem.chestGroups.findNextChestSlotWithCriteria(chestList, criteriaFunc)
    local startPoint = chestList.currentIndex
    local chestIndex = startPoint
    repeat
        local chest = chestList.get(chestIndex)
        local slotIndex, itemCount, itemName = storageSystem.chestGroups.findNextSlotWithCriteria(chest.pWrap, storageSystem.chestGroups.nextSlot(chest.lastSlot, chest.length), criteriaFunc)
        if(slotIndex > 0)
        then
            chest.lastSlot = slotIndex
            return chest, slotIndex, itemCount, itemName
        end
        chestIndex = chestList.nextIndex()
    until (chestIndex == startPoint)
    return nil
end

function storageSystem.chestGroups.moveAllItemsInGroup(sourceChestList, targetChestList)
    for _index, chest in pairs(sourceChestList._members) do
        for slotIndex, slotObj in pairs(chest.pWrap.list())do
            storageSystem.chestGroups.dropIntoChestList(targetChestList, chest.name, slotIndex)
        end
    end
end

storageSystem.tasks = {}
storageSystem.tasks.todoQueue = queueBuilder.new()
storageSystem.tasks.doneQueue = queueBuilder.new()
storageSystem.tasks.chestSlotInUseHashMap = hashMapBuilder.new()

function storageSystem.tasks.newTask(funct, ...)
    local task = {}
    task.funct = funct
    task.response = {}
    --task.itemName = nil if present, the item type associated with this job
    --task.chestSlotInUse = nil --if present, remove this from chestSlotInUseHashMap after task is complete
    --task.responseComputerID = nil --if present, this is who should get a response
    --task.responseCode = nil --after funct is run: success == 200, partial success = 206, bad request structure = 400, internal error == 500
    --task.responseData = nil --any data or error messages that need to be returned after the task
    return task
end
function storageSystem.tasks.generateChestSlotInUseKey(chest, chestSlot)
    return chest.name .. ":" .. chestSlot
end


function storageSystem.tasks.handleInputChestsTask()
    --find slots in inventory chests that need to be deposited and create a task in the task queue for it
    print("handling input chests")
    while true do
        --get a non-empty slot from the input chests
        local inputChest, inputChestSlotIndex, avalibleItemCount, itemName = storageSystem.chestGroups.findNextChestSlotWithCriteria(storageSystem.chestGroups.inputHopperGroup, storageSystem.chestGroups.isNonEmptySlot)
        --make sure there is a non-empty chestSlot that isnt currently being used by another task
        if(not inputChest or avalibleItemCount == 0 ) then
            --nothing in the input chest, give it a second
            os.sleep(3)
        elseif(storageSystem.tasks.chestSlotInUseHashMap.get(storageSystem.tasks.generateChestSlotInUseKey(inputChest, inputChestSlotIndex))) then
            --slot currently in use
        else
            --create a task on the queue to add these items
            local task = storageSystem.tasks.newTask(function() return storageSystem.addToRAS(itemName,inputChest, inputChestSlotIndex, avalibleItemCount) end)
            task.itemName = itemName
            task.chestSlotInUse = storageSystem.tasks.generateChestSlotInUseKey(inputChest, inputChestSlotIndex)
            storageSystem.tasks.chestSlotInUseHashMap.insert(task.chestSlotInUse, task)
            storageSystem.tasks.todoQueue.push(task)
        end
    end
end

function storageSystem.tasks.checkAPIArguments(sentData, task, ...)
    local args = {...}
    for i, requirements in pairs(args) do
        if(sentData[requirements.fieldName] == nil) then
            task.response.code = 400
            task.response.data = {errorMessage = "missing required field: " .. requirements.fieldName}
            return false
        elseif(type(sentData[requirements.fieldName]) ~= requirements.type) then
            task.response.code = 400
            task.response.data = {errorMessage = "incorrect type for field: " .. requirements.fieldName .. 
                                ". Needs " .. requirements.type .. " not " .. type(sentData[requirements.fieldName])}
            return false
        end
    end
    return true
end

storageSystem.comms = {}
storageSystem.comms.protocol = "kode-storage-server"
storageSystem.comms.hostname = "kode-server-mountain"

function storageSystem.tasks.handleNetworkItemStorageAPIMessages()
    --open rednet on all modems
    peripheral.find("modem", rednet.open)
    rednet.host(storageSystem.comms.protocol, storageSystem.comms.hostname)

    while true do
        local computerID, data = rednet.receive(storageSystem.comms.protocol)
        --create a task and put it on the task queue
        local task = storageSystem.tasks.newTask()
        task.responseComputerID = computerID

        if(not data or not data.command) then
            task.response.code = 400
            task.response.data = {errorMessage = "unable to process empty data or command"}
            storageSystem.tasks.doneQueue.push(task)
        elseif(data.command == "deposit") then
            if(not storageSystem.tasks.checkAPIArguments(data, task, 
                                                {fieldName = "itemName", type = "string"},
                                                {fieldName = "itemCount", type = "number"},
                                                {fieldName = "sourceChestName", type = "string"},
                                                {fieldName = "sourceChestSlot", type = "number"})) then
                storageSystem.tasks.doneQueue.push(task)
            else
                task.funct = function() return storageSystem.addToRAS(data.itemName,data.sourceChestName, data.sourceChestSlot, data.itemCount) end
                task.itemName = data.itemName
                task.chestSlotInUse = storageSystem.tasks.generateChestSlotInUseKey(data.sourceChestName, data.sourceChestSlot)
                storageSystem.tasks.chestSlotInUseHashMap.insert(task.chestSlotInUse, task)
                storageSystem.tasks.todoQueue.push(task)
            end
        elseif(data.command == "withdrawl") then
            if(not storageSystem.tasks.checkAPIArguments(data, task, 
                                                {fieldName = "itemName", type = "string"},
                                                {fieldName = "itemCount", type = "number"},
                                                {fieldName = "targetChestGroupName", type = "string"})) then
                storageSystem.tasks.doneQueue.push(task)
            else
                task.funct = function() return storageSystem.removeFromRAS(data.itemName, storageSystem.chestGroups[data.targetChestGroupName], data.itemCount) end
                task.itemName = data.itemName
                storageSystem.tasks.todoQueue.push(task)
            end
        end

        --deposit itemName, itemCount, sourceChestName, sourceChestSlot, -> amount transfered
        --withdrawl itemName, itemCount, targetChestName -? amount transfered
        --getInventory ->get entire inventory which includes all item types and how many we have of each
        --getInventory itemName -> only get inventory info for a specific item type
        --verify //verify data in database compared to chests, report where wrong
        --regenDB //delete DB and use current chest contents to generate a new DB
    end

end

function storageSystem.tasks.handleToDoQueueTask()
    while true do
        if(not storageSystem.tasks.todoQueue.hasNext()) then
            os.sleep(5)
        else
            local task = storageSystem.tasks.todoQueue.pop()

            local responseCode, responseData = task.funct()

            task.response.code = responseCode
            task.response.data = responseData

            storageSystem.tasks.doneQueue.push(task)
        end
    end
end

function storageSystem.tasks.handleDoneQueueTask()
    while true do
        if(not storageSystem.tasks.doneQueue.hasNext()) then
            os.sleep(5)
        else
            local task = storageSystem.tasks.doneQueue.pop()

            if(task.chestSlotInUse) then
                storageSystem.tasks.chestSlotInUseHashMap.remove(task.chestSlotInUse)
            end

            if(task.itemName) then
                --remove from itemNameHashMap TODO
            end

            if(task.response.code ~= 200) then
                --log
                print(textutils.serialize(task.response))
            end

            if(task.responseComputerID) then
                --respond to the computer that send the API request
                if(not rednet.send(task.responseComputerID, task.response, storageSystem.comms.protocol)) then
                    --log
                    print("message not sent to: " .. task.responseComputerID .. textutils.serialize(task.response))
                end
            end
        end
    end
end


--no longer will work
local function mainAddingLoop()
    print("starting normal operations")
    while true do
        local inputChest, inputChestSlotIndex, avalibleItemCount, itemName = storageSystem.chestGroups.findNextChestSlotWithCriteria(storageSystem.chestGroups.inputHopperGroup, storageSystem.chestGroups.isNonEmptySlot)
        if(inputChest and avalibleItemCount > 0) then
            storageSystem.addToRAS(itemName,inputChest, inputChestSlotIndex, avalibleItemCount)
            --do I need to make this work in parallel? saving the file will have to be in series
        end
    end
end

parallel.waitForAny(storageSystem.tasks.handleInputChestsTask, storageSystem.tasks.handleToDoQueueTask, storageSystem.tasks.handleDoneQueueTask)
--mainAddingLoop()
--os.sleep(5)
--storageSystem.removeFromRAS("minecraft:packed_ice", storageSystem.chestGroups.outputChestList, 2)
--storageSystem.chestGroups.moveAllItemsInGroup(storageSystem.chestGroups.allRasChestList, storageSystem.chestGroups.outputChestList)


--search input inventory thread --puts jobs in the job queue
--network item storage api thread --puts jobs in the job queue 
--process jobs queue thread
--process done jobs thread


--NIS api
--deposit itemName, itemCount, sourceChestName, sourceChestSlot, -> amount transfered
--withdrawl itemName, itemCount, targetChestName -? amount transfered
--getInventory ->get entire inventory which includes all item types and how many we have of each
--getInventory itemName -> only get inventory info for a specific item type
--verify //verify data in database compared to chests, report where wrong
--regenDB //delete DB and use current chest contents to generate a new DB


--responces
--statusCode = success == 200, partial success = 206, bad request structure = 400, internal error == 500
--error message if anything other than 200


--TODO finish writing API commands in handleAPITask thing