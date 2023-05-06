local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")
local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local stackBuilder = require(settings.get("require.api_path") .. "utils.stack")
local databaseBuilder = require(settings.get("require.api_path") .. "utils.disk-database")
local logBuilder = require(settings.get("require.api_path") .. "utils.log")
local itemConstants = require(settings.get("require.api_path") .. "constants.minecraft-items")
local pnetworkBuilder = require(settings.get("require.api_path") .. "peripheral.pnetwork")
local lookupMapBuilder = require(settings.get("require.api_path") .. "utils.lookup-map")
local parallel = require(settings.get("require.api_path") .. "utils.parallel-timeout")

local version = "0.0.1"
local args = {...}
if(args and #args > 0 and args[1] == "-v" or args[1] == "--version")then print(version)end

local storageSystem = {}
storageSystem.config = {}
storageSystem.config.data = {}
storageSystem.config.fileName = "nis-client.config"
storageSystem.config.dirName = "/data/network-item-storage"
function storageSystem.config.setFileName(filename)
    local resolvedFileName = shell.resolve(filename)
    storageSystem.config.fileName = fs.getName(resolvedFileName)
    storageSystem.config.dirName = fs.getDir(resolvedFileName)
end
function storageSystem.config.getResolvedFileName()
    return shell.resolve(storageSystem.config.dirName .. "/" .. storageSystem.config.fileName)
end
function storageSystem.config.create()
    storageSystem.config.data = {}
    storageSystem.config.data.serverProtocol = "kode.nis.server"
    --storageSystem.config.data.clientProtocol = "kode.nis"
    storageSystem.config.data.timeout = 15
    --storageSystem.config.data.serverName
    --storageSystem.config.data.clientName
end
function storageSystem.config.load(filename)
    if(filename) then
        storageSystem.config.setFileName(filename)
    end
    local resolvedFileName = storageSystem.config.getResolvedFileName()
    if(not fs.exists(resolvedFileName)) then
        return false, "file did not exist at: " .. resolvedFileName
    end
    local file = fs.open(resolvedFileName, "r")
    storageSystem.config.data = textutils.unserialize(file.readAll())
    file.close()
end
function storageSystem.config.save(filename)
    if(filename) then
        storageSystem.config.setFileName(filename)
    end

    local resolvedFileName = storageSystem.config.getResolvedFileName()
    local file = fs.open(resolvedFileName, "w")
    file.write(textutils.serialize(storageSystem.config.data))
    file.close()
end

storageSystem.chestGroups = {}
storageSystem.chestGroups.pnetwork = pnetworkBuilder.new("/data/network-item-storage/", "pnetwork_config.json")

function storageSystem.chestGroups.createChest(name, pWrap, length, lastSlot)
    local chest = {
        name = name,
        pWrap = pWrap,
        length = length,
        lastSlot = lastSlot or 0
    }
    return chest
end
function storageSystem.chestGroups.createChestGroup(pName)
    local chestList = listBuilder.new(pName)
    local i = 1
    for _name, configChest in pairs(storageSystem.chestGroups.pnetwork.config.groupList[pName]._members) do
        if(configChest)
        then
            local tempWrap = peripheral.wrap(configChest.name)
            chestList.add(
                storageSystem.chestGroups.createChest(
                    configChest.name, 
                    tempWrap, 
                    tempWrap.size()
                )
            )
        end
    end
    return chestList
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

function storageSystem.chestGroups.getServerInputGroupName()
    return storageSystem.config.data.serverName .. "-input"
end
function storageSystem.chestGroups.getClientInputGroupName()
    return "nis-client-" .. storageSystem.config.data.clientName .. "-input"
end
function storageSystem.chestGroups.getClientOutputGroupName()
    return "nis-client-" .. storageSystem.config.data.clientName .. "-output"
end

--open rednet connection so comms can work
peripheral.find("modem", rednet.open)
if(not rednet.isOpen()) then
    print("Unable to reach rednet. Please ensure a modem is attached to the PC")
    print("Failed to launch")
    os.exit()
end

storageSystem.comms = {}
function storageSystem.comms.ensureGoodResponse(message)
    return message and message.code and message.code == 200 and message.data
end

function storageSystem.comms.sendAndReceive(targetID, message, protocol, timeout, wantWarnings)
    rednet.send(targetID, message, protocol)
    local id, message = rednet.receive(protocol, timeout)
    if(not message) then
        return false, {}, "No response"
    elseif(not message.code or not message.data) then
        return false, {}, "Bad response: " ..textutils.serialize(message)
    elseif(message.code == 400) then
        return false, {}, "Bad request: " .. message.code .. " : " .. (message.data.errorMessage or textutils.serialize(message))
    elseif(message.code == 500) then
        return false, {}, "Internal server error: " .. message.code .. " : " .. (message.data.errorMessage or textutils.serialize(message))
    elseif(not wantWarnings and message.code == 206) then
        return false, {}, "Unable to fully process the request: " .. message.code .. (message.data.errorMessage or textutils.serialize(message))
    else
        return true, message.data, (message.data.errorMessage or textutils.serialize(message))
    end
end

function storageSystem.comms.lookupHostNames(protocol)
    local serverLookupIndexIDMap = lookupMapBuilder.newFromMap({rednet.lookup(protocol)})
    local serverLookupNameIDMap = lookupMapBuilder.new()

    if(serverLookupIndexIDMap.size() == 0) then
        return false, serverLookupNameIDMap, "Unable to find any hosts under protocol: " .. protocol
    end

    local function sendGetHostNames()
        for index, id in pairs(serverLookupIndexIDMap._keyTable) do
            --ping all servers for a hostname
            rednet.send(id,{sType = "lookup", sProtocol = protocol}, "dns")
        end
    end
    local function receiveHostNames()
        while serverLookupNameIDMap.size() < serverLookupIndexIDMap.size() do
            local id, message = rednet.receive("dns", storageSystem.config.data.timeout)
            if((message ~= nil) and (type(message) == "table") and 
                    (message.sType ~= nil) and (message.sType == "lookup response") and 
                    (message.sHostname ~= nil) and (id ~= nil) and (serverLookupIndexIDMap.getKeyByVal(id) ~= nil)) then
                serverLookupNameIDMap.insert(message.sHostname, id)
            elseif(not id) then
                --timeout
            else
                print("Warning: Bad response from " .. id)
                print(textutils.serialize(message or ""))
            end
        end
    end

    local timeout = parallel.waitForAllWithTimeout(30, receiveHostNames, sendGetHostNames)
    if(timeout) then
        return false, serverLookupNameIDMap, "Timeout occured before finishing hostname search"
    else
        return true, serverLookupNameIDMap, ""
    end
end

function storageSystem.comms.sendGetClientProtocol()
    local success, data, errorMessage = storageSystem.comms.sendAndReceive(storageSystem.comms.serverID, {command="getClientProtocol"}, storageSystem.config.data.serverProtocol, storageSystem.config.data.timeout, false)
    if(success and data.clientProtocol) then
       return true, data.clientProtocol
    elseif(not data.clientProtocol) then
        return false, {}, "Unable to parse client protocol"
    else
        return false, {}, "Unable to get client protocol due to: " .. errorMessage
    end
end

function storageSystem.comms.sendGetClientList()
    local success, data, errorMessage = storageSystem.comms.sendAndReceive(storageSystem.comms.serverID, {command="getClientList"}, storageSystem.config.data.serverProtocol, storageSystem.config.data.timeout, false)
    if(success and data.clientList) then
        return true, data.clientList
    elseif(not data.clientList) then
        return false, {}, "Unable to parse client list"
    else
        return false, {}, "Unable to get client list due to: " .. errorMessage
    end
end

function storageSystem.comms.sendRegisterClientName(clientName)
    
    local success, data, errorMessage = storageSystem.comms.sendAndReceive(storageSystem.comms.serverID, {command="registerClientName", clientName=clientName}, storageSystem.config.data.serverProtocol, storageSystem.config.data.timeout, false)
    if(success) then
        rednet.host(storageSystem.config.data.clientProtocol, clientName)
        storageSystem.config.data.clientName = clientName
        return true
    else
        return false, {}, "Server refused client registration due to: " .. errorMessage
    end
end

function storageSystem.comms.sendRegisterClientChests()
    local data = {}
    data.command = "registerClientChests"
    data.clientName = storageSystem.config.data.clientName
    data.inputGroup = storageSystem.chestGroups.pnetwork.config.groupList[storageSystem.chestGroups.getClientInputGroupName()]
    data.outputGroup = storageSystem.chestGroups.pnetwork.config.groupList[storageSystem.chestGroups.getClientOutputGroupName()]
    local success, data, errorMessage = storageSystem.comms.sendAndReceive(storageSystem.comms.serverID, data, storageSystem.config.data.serverProtocol, storageSystem.config.data.timeout, false)
    if(success) then
        return true
    else
        return false, "Unable to register client chests due to: " .. errorMessage
    end

end

function storageSystem.comms.sendGetPnetwork()
    local success, data, errorMessage = storageSystem.comms.sendAndReceive(storageSystem.comms.serverID, {command="getPnetwork"}, storageSystem.config.data.serverProtocol,storageSystem.config.data.timeout, false)
    if(success and data.pnetworkconfig) then
        --local loadSuccess, loadMessage = storageSystem.chestGroups.pnetwork.loadConfigFile(data)
        return true, data.pnetworkconfig
    elseif(not data.pnetworkconfig) then
        return false, {}, "Unable to parse pnetwork file"
    else
        return false, {}, "Failed to get pnetwork file due to: " .. errorMessage
    end
end

function storageSystem.setupClientChests()
    local success, pnetworkconfig, errorMessage = storageSystem.comms.sendGetPnetwork()
    if(not success) then
        return false, "Unable to setup client chests due to: " .. errorMessage
    end
    
    local success, errorMessage = storageSystem.chestGroups.pnetwork.loadConfigFile(pnetworkconfig)
    if(not success) then
        return false, "Unable to load pnetwork config due to: " .. errorMessage
    end

    storageSystem.chestGroups.pnetwork.ui.command.scan()

    print("you need to assign the peripherials/chests to this client's input group (i), its output group (o), or leave blank to not assign to a group")
    
    local success, errorMessage = storageSystem.chestGroups.pnetwork.createGroup(storageSystem.chestGroups.getClientInputGroupName())
    if(not success) then return false, "Client input group failed to create due to: " .. errorMessage end
    local success, errorMessage = storageSystem.chestGroups.pnetwork.createGroup(storageSystem.chestGroups.getClientOutputGroupName())
    if(not success) then return false, "Client output group failed to create due to: " .. errorMessage end
    for pName, pObject in pairs(storageSystem.chestGroups.pnetwork.newPList) do
        print(pName)
        print(textutils.serialize(pObject))
        storageSystem.chestGroups.pnetwork.ui.printPeripheral(pObject)
        print("which group should this be assigned to? (input, output, or leave blank to skip")
        local groupName = read()
        if(groupName == "")
        then
            print("skipping")
        elseif(groupName == "q" or groupName == "quit")
        then
            print("stopping before finishing newPList, your progress is saved as long as you added to both groups")
            break
        elseif(groupName == "input" or groupName == "i") then
            print("adding to client input group")
            storageSystem.chestGroups.pnetwork.addNewPeripheralToGroup(pObject, storageSystem.chestGroups.pnetwork.config.groupList[storageSystem.chestGroups.getClientInputGroupName()])
        elseif(groupName == "output" or groupName == "o") then
            print("adding to output group")
            storageSystem.chestGroups.pnetwork.addNewPeripheralToGroup(pObject, storageSystem.chestGroups.pnetwork.config.groupList[storageSystem.chestGroups.getClientOutputGroupName()])
        else
            print("name not reconized, skipping this peripheral")
        end
    end

    storageSystem.chestGroups.clientInputChestGroup = storageSystem.chestGroups.createChestGroup(storageSystem.chestGroups.getClientInputGroupName())
    storageSystem.chestGroups.clientOutputChestGroup = storageSystem.chestGroups.createChestGroup(storageSystem.chestGroups.getClientOutputGroupName())
    if(#storageSystem.chestGroups.clientInputChestGroup._members > 0 and #storageSystem.chestGroups.clientOutputChestGroup._members > 0) then
        print("successfully added chest to input and output groups")
        print("registering client chests with server")
        local success, errorMessage = storageSystem.comms.sendRegisterClientChests()
        if(success) then
            return true
        else
            return false, errorMessage
        end
    else
        return false, "Failed because you did not add to both the input and output chest group"
    end
end

function storageSystem.setupNewClient()
    storageSystem.config.create()
    
    print("Searching for NIS servers")
    local success, serverLookupNameIDMap, errorMessage = storageSystem.comms.lookupHostNames(storageSystem.config.data.serverProtocol)
    if(not success) then
        print("Unable to find any NIS servers due to: " .. errorMessage)
        os.exit()
    end
    
    if(serverLookupNameIDMap.size()) then
        local hostname, id = next(serverLookupNameIDMap._keyTable)
        print("Found one NIS server called: " .. hostname)
        print("Would you like to configure to this server (y/n)?")
        local input = read()
        if(not (input == "y" or input == "yes")) then
            print("Unable to create a client without a server")
            os.exit()
        end
        storageSystem.config.data.serverName = hostname
        storageSystem.comms.serverID = id
    else
        print("Servers found:")
        for hostname, id in ipairs(serverLookupNameIDMap._keyTable) do
            print(hostname .. " : " .. id)
        end
        local isDone = false
        while not isDone do
            print("Which server do you want to connect to?")
            local input = read()
            if(input == "q") then
                print("exiting program")
                os.exit()
            elseif(serverLookupNameIDMap.getValByKey(input)) then
                storageSystem.config.data.serverName = input
                storageSystem.comms.serverID = serverLookupNameIDMap.getValByKey(input)
                isDone = true
            else
                print("Not a server name. Please enter a server name or 'q' to exit program")
            end
        end
    end

    --get clientProtocol
    local success, data, errorMessage = storageSystem.comms.sendGetClientProtocol()
    if(not success) then
        print("Closing program due to: " .. errorMessage)
        os.exit()
    end
    storageSystem.config.data.clientProtocol = data

    --now that a server is selected, we need to select a client name
    print("Here are the clients currently connected")
    local success, data, errorMessage = storageSystem.comms.sendGetClientList()
    if(not success) then
        print("Closing program due to: " .. errorMessage)
        os.exit()
    end
    local clientList = data
    for hostname, id in ipairs(clientList) do
        print(hostname .. " : " .. id)
    end

    local isDone = false
    while not isDone do
        print("What do you want this client to be called?")
        local input = read()
        if(input == "q")then
            print("exiting program")
            os.exit()
        elseif(not clientList[input])then
            local success, data, errorMessage = storageSystem.comms.sendRegisterClientName(input)
            if(success) then
                print("Client has been named: " .. input)
                isDone = true
            else
                print(errorMessage)
            end
        else
            print("Invalid hostname. Note that there cannot be repeat client hostnames connected to the same server")
        end
    end

    local success, errorMessage = storageSystem.setupClientChests()
    if(not success) then
        print("Failed to setup chest groups due to: " .. errorMessage)
        os.exit()
    end

    --save data
    storageSystem.config.save(storageSystem.config.getResolvedFileName())
    storageSystem.chestGroups.pnetwork.saveConfigFile()
end

--setup config if not already setup
if(fs.exists(storageSystem.config.getResolvedFileName()))then
    storageSystem.config.load()
    if(not storageSystem.config.data) then
        error("Unable to read config file at: " .. storageSystem.config.getResolvedFileName())
    end
    storageSystem.comms.serverID = rednet.lookup(storageSystem.config.data.serverProtocol, storageSystem.config.data.serverName)
else
    print("Client config not present")
    print("Would you like to setup a new client? (y/n)")
    local answer = read()
    if(answer == "y" or answer == "yes") then
        storageSystem.setupNewClient()
    else
        print("please fix client config and try again")
        os.exit()
    end
end

local success, errorMessage = storageSystem.chestGroups.pnetwork.loadConfigFile(storageSystem.chestGroups.pnetwork.configFileName)
if(not success) then
    print("Unable to load local pnetwork data due to: " .. errorMessage)
    print("Downloading pnetwork file from server")
    local success, data, errorMessage = storageSystem.comms.sendGetPnetwork()
    if(success) then
        local loadSuccess, loadMessage = storageSystem.chestGroups.pnetwork.loadConfigFile(data.config)
        if(not loadSuccess) then
            print("Unable to load pnetwork file due to: " .. loadMessage)
            os.exit()
        end
    else
        print("Unable to get pnetwork file from server due to: " .. errorMessage)
        os.exit()
    end
end

storageSystem.chestGroups.serverInputChestGroup = storageSystem.chestGroups.createChestGroup(storageSystem.chestGroups.getServerInputGroupName())
storageSystem.chestGroups.clientInputChestGroup = storageSystem.chestGroups.createChestGroup(storageSystem.chestGroups.getClientInputGroupName())
storageSystem.chestGroups.clientOutputChestGroup = storageSystem.chestGroups.createChestGroup(storageSystem.chestGroups.getClientOutputGroupName())


local function handle_put(args)
    --just dump everything in input chests
    while(storageSystem.chestGroups.checkIfChestContainsItems(storageSystem.chestGroups.clientInputChestGroup)) do
        storageSystem.chestGroups.moveAllItemsInGroup(storageSystem.chestGroups.clientInputChestGroup, storageSystem.chestGroups.serverInputChestGroup)
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
    dataMessage.targetChestGroupName = storageSystem.chestGroups.clientOutputChestGroup.name

    storageSystem.comms.sendAndReceive(storageSystem.comms.serverID, dataMessage, storageSystem.config.data.clientProtocol, storageSystem.config.data.timeout)
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