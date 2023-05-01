local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")
local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local stackBuilder = require(settings.get("require.api_path") .. "utils.stack")
local databaseBuilder = require(settings.get("require.api_path") .. "utils.disk-database")
local logBuilder = require(settings.get("require.api_path") .. "utils.log")
local itemConstants = require(settings.get("require.api_path") .. "constants.minecraft-items")

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
storageSystem.chestGroups.inputChestGroup = storageSystem.chestGroups.createChestGroup("c1-storage-input-chests")
storageSystem.chestGroups.outputChestGroup = storageSystem.chestGroups.createChestGroup("c1-storage-output-chests")

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

storageSystem.comms = {}
storageSystem.comms.protocol = "kode.nis"
storageSystem.comms.hostname = "kode.mountainbase.nis_server"
storageSystem.comms.timeout = 100

peripheral.find("modem", rednet.open)
storageSystem.comms.serverID = rednet.lookup(storageSystem.comms.protocol, storageSystem.comms.hostname)

local function sendCommand(data)
    local success = rednet.send(storageSystem.comms.serverID, data, storageSystem.comms.protocol)
    if(not success) then
        print("unable to send command to server. please ensure your modem is connected.")
        return
    end

    local computerID, message = rednet.receive(storageSystem.comms.protocol, storageSystem.comms.timeout)
    if(not computerID) then
        print("timeout occured while trying to communicate with the server")
        return
    elseif(not message) then
        print("server message with blank body")
        return
    end

    if(message.code == 200) then
        print("successfully completed command")
        return
    elseif(message.code == 206) then
        print(message.data.errorMessage .. message.data.itemsTransferedCount)
        return
    elseif(message.code == 500) then
        print(message.data.errorMessage)
    else
        print("unreconnized response:")
        print(textutils.serialize(message))
    end
end

function storageSystem.chestGroups.checkIfChestContainsItems(chestList)
    local startPoint = chestList.currentIndex
    local chestIndex = startPoint
    repeat
        local chest = chestList.get(chestIndex)
        if(chest.pWrap and #chest.pWrap.list() > 0) then
            return true
        else
            chestIndex = chestList.nextIndex()
        end
    until (chestIndex == startPoint)
    return false
end

function storageSystem.chestGroups.dropIntoChestList(chestList, sourceChestObj, sourceSlot, desiredAmount)
    local startPoint = chestList.currentIndex
    local chestIndex = startPoint
    local transferedAmount = 0
    local sourceSlotInfo = sourceChestObj.pWrap.getItemDetail(sourceSlot)
    if(sourceSlotInfo == nil) 
    then
        --nothing left to do, it is already empty
        return 0
    end
    desiredAmount = desiredAmount or sourceSlotInfo.count
    repeat
        local transferedAmount = transferedAmount + chestList.get(chestIndex).pWrap.pullItems(sourceChestObj.name, sourceSlot, desiredAmount - transferedAmount)
        if(transferedAmount >= desiredAmount)then
            return transferedAmount
        else
            chestIndex = chestList.nextIndex()
        end
    until (chestIndex == startPoint)
    return transferedAmount
end

function storageSystem.chestGroups.moveAllItemsInGroup(sourceChestList, targetChestList)
    for _index, chest in pairs(sourceChestList._members) do
        for slotIndex, slotObj in pairs(chest.pWrap.list())do
            storageSystem.chestGroups.dropIntoChestList(targetChestList, chest, slotIndex)
        end
    end
end

local function handle_put(args)
    --just dump everything in input chests
    while(storageSystem.chestGroups.checkIfChestContainsItems(storageSystem.chestGroups.inputChestGroup)) do
        storageSystem.chestGroups.moveAllItemsInGroup(storageSystem.chestGroups.inputChestGroup, storageSystem.chestGroups.inputHopperGroup)
    end
end

local function handle_get(args)
    local dataMessage = {}
    dataMessage.command = "get"
    dataMessage.itemName = args[2]
    if(not dataMessage.itemName) then
        print("what item would you like to get?")
        dataMessage.itemName = read()
    end
    dataMessage.itemCount = args[3]
    if(dataMessage.itemCount)then
        dataMessage.itemCount = tonumber(dataMessage.itemCount)
    elseif(not dataMessage.itemCount) then
        print("how many of " .. dataMessage.itemName .. " do you want?")
        dataMessage.itemCount = tonumber(read())
    end
    dataMessage.targetChestGroupName = storageSystem.chestGroups.outputChestGroup.name

    sendCommand(dataMessage)
end

local function handle_read(args)

end

local quit = false
local function handle_quit(args)
    quit = true
end

local function splitString (inputstr, sep)
    if sep == nil then
       sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
       table.insert(t, str)
    end
    return t
 end

local function processCommand(command, args)

    local case = {
        ["put"] = handle_put,
        ["get"] = handle_get,
        ["read"] = handle_read,
        ["quit"] = handle_quit,
        ["q"] = handle_quit,

        ["default"] = function () print("command not reconized") end
    }

    if case[command] then
        case[command](args)
    else
        case["default"]()
    end
end


while not quit do
    print("Enter command: ")
    local input = read()
    if(input) then
        local args = splitString(input)
        local command = args[1]
        if(command)then
            processCommand(command, args)
        else
            print("bad input")
        end
    end
end