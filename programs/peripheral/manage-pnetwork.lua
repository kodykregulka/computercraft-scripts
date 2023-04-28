
local newPList = {}
local config = {}
config.groupList = {}
local pList = {}
--local pList = {} -- a table where the key = pname and value = pointer to config object in group table
--local groups = {}

local DEFAULT_CONFIG_FILENAME = "pnetwork_config.json"
local configFileName = ""

local function printHelp()
    print("")
    print("commands avalible: ")
    print(" - load        : load a pnetwork-config.json")
    print(" - save        : save your changes made in a pnetwork-config.json, newPList is not saved")
    print(" - verify      : verify that all peripherals in config exist, does not modify")
    print(" - help|h      : print avalible commands")
    print(" - quit|q      : exit program")
    print("")
    print("-- managing groups --")
    print(" - printGroups : print all groups with their registered peripherals from the config file")
    print(" - createGroup : creates a new group")
    print(" - renameGroup : rename a group")
    print(" - removeGroup : remove a group, all peripherals in group will be unregistered(removed from pList)")
    print("")
    print("press enter to continue")
    read()
    print("")
    print("-- managing new peripherals  --")
    print(" - scan            : check network for all connected peripherals and adds new peripherals to newPList. newPList is erased before scanning")
    print(" - printNew        : print all peripherals in the newPList, peripherals will be removed once added to a group in the config")
    print(" - printRegistered : print all registered peripherals")
    print(" - assignNew       : cycle through newPList, print contents, and assign to a group. Leave blank to skip")
    print("")
    print("-- managing peripherals that are in groups  --")
    print(" - addToGroup       : peripheral is removed from it's current group and added to this one")
    print(" - addAllToGroup    : peripheral is removed from it's current group (or newPList) and added to this one")
    print(" - removeFromGroup  : peripheral is removed from it's current group and added to the newPList")
    print(" - removePeripheral : remove peripheral by permName")
    print(" - renamePeripheral : peripheral reference name is renamed")
    print(" - printPeripheral  : print contents of a specific peripheral")
    print("")
end

local function printConfig(myConfig)

end

local function printList(myList)
    for key, value in pairs(myList) do
        print(key .. " - " .. textutils.serialize(value))
        print("press enter to scroll")
        local input = read()
        if(input == "q")then return  end
    end
end

local function printTable(myTable)
    print(textutils.serialize(myTable))
end

local function printPeripheral(pObject)
    local pWrap = peripheral.wrap(pObject.permName)
    local pType = peripheral.getType(pWrap)
    print(pType)
    if(pType == "minecraft:chest" or pType == "minecraft:trapped_chest")
    then
        printList(pWrap.list())
    end
    --TODO
end

local function loadConfigFile(fileName)
    config = {}
    if(fs.exists(fileName))
    then
        local configFile = fs.open(fileName, "r")
        config = textutils.unserialize(configFile.readAll())
        if(not config or not config.groupList)then
            print("unable to parse config")
            return
        end
        pList = {}
        for groupName, group in pairs(config.groupList) do
            for memberName, member in pairs(group.members) do
                pList[member.permName] = member
            end
        end
        configFile.close()
        if(pList and config.groupList)
        then
            configFileName = fileName
            return true
        else
            return false
        end
    else
        return false
    end
end

local function command_load()
    print("Enter filename: ")
    local filename = shell.resolve(read())
    if(loadConfigFile(filename))
    then
        print("successfully loaded config file from: " .. filename)
    else
        print("Unable to locate a config file at: " .. filename)
    end
end

local function command_save()
    if(configFileName == "")
    then
        print("saving to ./" .. DEFAULT_CONFIG_FILENAME .. ", please move and rename on your own")
        configFileName = shell.resolve(DEFAULT_CONFIG_FILENAME)
    else
        configFileName = configFileName
        print("Overwriting previous save file at: " .. configFileName)
    end
    
    local configFile = fs.open(configFileName, "w")
    configFile.write(textutils.serialize(config))
    configFile.close()
    print("Successfully saved")
end

local function command_verify()
    error("TODO")

end

local function command_createGroup()
    print("Enter name for new group: ")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end
    if(config.groupList[groupName])
    then
        print("Name already exists")
        return
    end

    --name is good, create group
    config.groupList[groupName] = {}
    config.groupList[groupName].groupName = groupName
    config.groupList[groupName].members = {}
    print("group " .. groupName .. " has been created. Add peripherals with command addToGroup")
end

local function command_renameGroup()
    print("which group would you like to rename?")
    local currentGroupName = read()
    if(currentGroupName == "")then
        print("Not a valid input")
        return
    end
    if(not config.groupList[currentGroupName])
    then
        print("group did not exist")
        return
    end

    print("What would you like to rename it to?")
    local newGroupName = read()
    if(newGroupName == "")then
        print("Not a valid input")
        return
    end
    if(config.groupList[newGroupName])
    then
        print("Name already exists")
        return
    end

    local groupTable = config.groupList[currentGroupName]
    config.groupList[currentGroupName] = nil
    config.groupList[newGroupName] = groupTable

    --update pList
    for key, value in pairs(config.groupList[currentGroupName].members) do
        pList[value.permName].groupName = newGroupName
    end
    print("Successfully renamed group")
end

local function command_removeGroup()
    print("which group would you like to remove?")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end
    if(not config.groupList[groupName])
    then
        print("Group not found")
        return
    end

    --remove from pList
    for key, value in pairs(config.groupList[groupName].members) do
        pList[value.permName].groupName = nil
        newPList[value.permName] = pList[value.permName]
        pList[value.permName] = nil
    end

    config.groupList[groupName] = nil
end

local function command_scan()
    newPList = {}
    local scannedList = peripheral.getNames()

    print("scanning for peripherals on network")
    for i = 1, #scannedList, 1 
    do
        local sname = scannedList[i]
        if(not pList[sname])
        then
            local pWrap = peripheral.wrap(sname)
            newPList[sname] = {name = sname, permName = sname, ptype = peripheral.getType(pWrap), size = pWrap.size()}
        end
    end

    print("found these peripherals:")
    --printTable(newPList)
    printList(newPList)
end

local function command_assignNew()
    --cycle through newPList, print contents, and assign to a group. Leave blank to skip
    for permName, pObject in pairs(newPList) do
        print(textutils.serialize(pObject))
        printPeripheral(pObject)
        print("which group should this be assigned to? (leave blank to skip")
        local groupName = read()
        if(groupName ~= "")
        then
            if(not config.groupList[groupName])
            then
                print("No group with that name. Skipping peripheral")
            elseif(config.groupList[groupName].members[pObject.name])
            then
                print("already a peripheral in that group with that name")
            else
                pObject.groupName = groupName
                pList[permName] = pObject
                config.groupList[groupName].members[pObject.name] = pObject
                newPList[permName] = nil
                print("Added " .. pObject.name .. " (" .. permName .. ") to " .. groupName)
            end
        end
        print("Next")
    end
end

local function command_addToGroup()
    print("which peripherals from the newPList would you like to add to a group? Please use permName")
    local permName = read()
    if(permName == "")then
        print("Not a valid input")
        return
    end

    if(not newPList[permName])
    then
        print("must select a peripheral from the newPList, use scan to add new peripherals")
        return
    end

    print("found this peripheral in the newPList:")
    print(textutils.serialize(newPList[permName]))
    print("which group do you want to assign it to?")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end

    if(not config.groupList[groupName])
    then
        print("no group with that name")
        return
    end

    if(config.groupList[groupName].members[newPList[permName].name])
    then
        print("group already has peripheral with that name. Please change one of their names")
        return
    end

    newPList[permName].groupName = groupName
    local newP = newPList[permName]
    config.groupList[groupName].members[newP.name] = newP
    pList[newP.permName] = newP
    newPList[permName] = nil
    print("successfully added to group")
    --printTable(config.groupList[groupName])
    printList(config.groupList[groupName].members)
end

local function command_addAllToGroup()
    print("which group do you want to assign all of the peripheralsin to?")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end

    if(not config.groupList[groupName])
    then
        print("no group with that name")
        return
    end

    for permName, pObject in pairs(newPList) do
        if(not pList[permName] and not config.groupList[groupName].members[pObject.name])
        then
            pObject.groupName = groupName
            pList[permName] = pObject
            config.groupList[groupName].members[pObject.name] = pObject
            newPList[permName] = nil
            print("Added " .. pObject.name .. " (" .. permName .. ") to " .. groupName)
        else
            print("Unable to add " .. permName .. " due to naming conflict")
        end
    end
end

local function command_removeFromGroup()
    print("Which group would you like to remove a peripheral from?")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end
    if(not config.groupList[groupName])then
        print("group not found with a matching name")
        return
    end

    print("group found")
    --printTable(config.groupList[groupName])
    printList(config.groupList[groupName])
    print("Which peripheral would you like to remove. It will be added to the newPList")
    local pName = read()
    if(pName == "")then
        print("not a valid input")
        return
    end
    if(not config.groupList[groupName].members[pName])then
        print("peripheral not found with that name in that group")
        return
    end

    local pObject = config.groupList[groupName].members[pName]
    pObject.group = nil
    pList[pObject.permName] = nil
    newPList[pObject.permName] = pObject
    print(pName .. " was removed from its group. It can be found in newPList until you scan")
end

local function command_removePeripheral()
    print("Please enter the exact permenant name of the peripheral you wish to remove")
    local permName = read()
    if(permName == "")then
        print("not a valid input")
        return
    end
    if(not pList[permName])then
        print("peripheral not found with that exact permName")
        return
    end

    local pObject = pList[permName]
    local groupName = pObject.groupName
    config.groupList[groupName].members[pObject.name] = nil
    pObject.groupName = nil
    pList[permName] = nil
    newPList[pObject.permName] = pObject
    print("peripheral has been removed")
end

local function command_renamePeripheral()
    print("Which group is this peripheral from?")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end
    if(not config.groupList[groupName])then
        print("group not found with a matching name")
        return
    end

    print("group found")
    --printTable(config.groupList[groupName])
    printList(config.groupList[groupName])
    print("Which peripheral would you like to rename?")
    local pName = read()
    if(pName == "")then
        print("not a valid input")
        return
    end
    if(not config.groupList[groupName].members[pName])then
        print("peripheral not found with that name in that group")
        return
    end

    print("What would you like the new name to be?")
    local newName = read()
    if(pName == "")then
        print("not a valid input")
        return
    end
    if(config.groupList[groupName].members[newName])then
        print("A peripheral in that group already has that name")
        return
    end

    local pObject = config.groupList[groupName].members[pName]
    pObject.name = newName
    config.groupList[groupName].members[pName] = nil
    config.groupList[groupName].members[newName] = pObject
    pList[pObject.permName].name = newName
end

local function command_printPeripheral()
    print("Which group does the peripheral belong to?")
    local groupName = read()
    if(groupName == "")then
        print("Not a valid input")
        return
    end
    local currentGroup = {}
    if(groupName == "newPList")
    then
        currentGroup = newPList
    elseif(config.groupList[groupName])
    then
        currentGroup = config.groupList[groupName].members
    else
        print("group not found with a matching name")
        return
    end

    --printTable(config.groupList[groupName])
    local memberNameListString = ""
    for name, pObject in pairs(currentGroup)
    do
        memberNameListString =memberNameListString .. ", " .. name
    end
    print(memberNameListString)
    print("Which peripheral would you like to print out?")
    local pObject = {}
    local pName = read()
    if(pName == "")then
        print("not a valid input")
        return
    end
    
    if(not currentGroup[pName])then
        print("peripheral not found with that name in that group")
        return
    end
    pObject = currentGroup[pName]
    
    print("here is the config info:")
    print(textutils.serialize(pObject))
    print("press enter for current status")
    read()
    printPeripheral(pObject)
end



local quit = false
local function processCommand(command)
    local command = command and tonumber(command) or command --string or number
    local case = 
    {
        ["load"] = command_load,
        ["save"] = command_save,
        ["verify"] = command_verify,
        ["help"] = printHelp,
        ["h"] = printHelp,
        ["quit"] = function () quit = true end,
        ["q"] = function () quit = true end,

        ["printGroups"] = function () printList(config.groupList) end,
        ["createGroup"] = command_createGroup,
        ["renameGroup"] = command_renameGroup,
        ["removeGroup"] = command_removeGroup,

        ["scan"] = command_scan,
        ["printNew"] = function () printList(newPList) end,
        ["printRegistered"] = function () printList(pList) end,
        ["assignNew"] = command_assignNew,
        
        ["addToGroup"] = command_addToGroup,
        ["addAllToGroup"] = command_addAllToGroup,
        ["removeFromGroup"] = command_removeFromGroup,
        ["removePeripheral"] = command_removePeripheral,
        ["renamePeripheral"] = command_renamePeripheral,
        ["printPeripheral"] = command_printPeripheral,

        ["default"] = function () print("command not reconized") end,
    }

    if case[command] then
        case[command]()
    else
        case["default"]()
    end
end

--main
if(arg[1])
then
    local configFileName = shell.resolve(arg[1])
    if(loadConfigFile(configFileName))
    then
        print("successfully loaded config file from: " .. configFileName)
    else
        error("Unable to read config file: " .. configFileName)
    end
end

printHelp()
while quit == false do
    print("")
    print("Enter command: ")
    local command = read()
    processCommand(command)
end