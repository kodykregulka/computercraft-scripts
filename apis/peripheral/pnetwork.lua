local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local pnetworkBuilder = {}

function pnetworkBuilder.new(dirName, fileName)
    local pnetwork = {}

    pnetwork.newPList = {}
    pnetwork.config = {}
    pnetwork.config.groupList = {}
    pnetwork.pList = {}
    
    pnetwork.DEFAULT_CONFIG_FILENAME = "pnetwork_config.json"
    pnetwork.configFileName = fileName or pnetwork.DEFAULT_CONFIG_FILENAME
    pnetwork.configDirectory = dirName or "./"

    function pnetwork.getConfigFilePath()
        return shell.resolve(pnetwork.configDirectory .. "/" .. pnetwork.configFileName)
    end
    
    function pnetwork.loadConfigFile(input)
        if(input == nil or type(input) == "string") then
            pnetwork.configFileName = input or pnetwork.configFileName
            pnetwork.config = {}
            if(not fs.exists(pnetwork.getConfigFilePath()))
            then
                return false, "file did not exist"
            end
        
            local configFile = fs.open(pnetwork.getConfigFilePath(), "r")
            pnetwork.config = textutils.unserialize(configFile.readAll())
            configFile.close()
            if(not pnetwork.config or not pnetwork.config.groupList)then
                return false, "unable to parse pnetwork.config"
            end
        elseif(type(input) == "table") then
            pnetwork.config = input
        else
            error("Expecting string or table argument")
        end
        pnetwork.pList = {}
        for groupName, group in pairs(pnetwork.config.groupList) do
            for memberName, member in pairs(group._members) do
                pnetwork.pList[member.name] = member
            end
        end
        if(pnetwork.pList and pnetwork.config.groupList)
        then
            return true
        else
            return false, "pList or group list did not load properly"
        end
    end
    
    function pnetwork.saveConfigFile(configFileName)
        pnetwork.configFileName = configFileName or pnetwork.configFileName
        local resolvedDir = shell.resolve(pnetwork.configDirectory)
        if(not fs.exists(resolvedDir)) then
            fs.makeDir(resolvedDir)
        end
    
        local configFile = fs.open(pnetwork.getConfigFilePath(), "w")
        configFile.write(textutils.serialize(pnetwork.config))
        configFile.close()
        return true
    end
    
    function pnetwork.verifyConfig()
        error("TODO")
    
    end
    
    function pnetwork.createGroup(groupName)
        expect(1, groupName, "string")
        if(groupName == "") then
            return false, "group name cannot be a blank string"
        end
        if(pnetwork.config.groupList[groupName])
        then
            return false, "name already exists"
        end
    
        --name is good, create group
        pnetwork.config.groupList[groupName] = {}
        pnetwork.config.groupList[groupName].groupName = groupName
        pnetwork.config.groupList[groupName]._members = {}
        return true
    end
    
    function pnetwork.renameGroup(currentGroupObj, newGroupName)
        expect(1, currentGroupObj, "table")
        expect(2, newGroupName, "string")
    
        if(newGroupName == "")then
            return false, "Not a valid group name"
        elseif(pnetwork.config.groupList[newGroupName])
        then
            return false, "group name already exists"
        end
    
        pnetwork.config.groupList[currentGroupObj.groupName] = nil
        pnetwork.config.groupList[newGroupName] = currentGroupObj
        currentGroupObj.groupName = newGroupName
    
        --update pnetwork.pList
        for key, value in pairs(currentGroupObj._members) do
            pnetwork.pList[value.name].groupName = newGroupName
        end
        return true
    end
    
    function pnetwork.removeGroup(groupName)
        expect(1, groupName, "string")
        print("which group would you like to remove?")
        if(not pnetwork.config.groupList[groupName])
        then
            return false, "group not found"
        end
    
        --remove from pnetwork.pList
        for key, value in pairs(pnetwork.config.groupList[groupName]._members) do
            pnetwork.pList[value.name].groupName = nil
            pnetwork.newPList[value.name] = pnetwork.pList[value.permNnameame]
            pnetwork.pList[value.name] = nil
        end
    
        pnetwork.config.groupList[groupName] = nil
        return true
    end
    
    function pnetwork.scanForNewPeripherals()
        pnetwork.newPList = {}
        local scannedList = peripheral.getNames()
    
        for i = 1, #scannedList, 1 
        do
            local sname = scannedList[i]
            if(not pnetwork.pList[sname])
            then
                local pWrap = peripheral.wrap(sname)
                local size = 0
                if(pWrap.size) then
                    size = pWrap.size()
                end
                pnetwork.newPList[sname] = {name = sname, ptype = peripheral.getType(pWrap), size = size}
            end
        end
    end
    
    function pnetwork.addNewPeripheralToGroup(pObject, groupObj)
        expect(1, pObject, "table")
        expect(2, groupObj, "table")
    
        pObject.groupName = groupObj.groupName
        pnetwork.pList[pObject.name] = pObject
        groupObj._members[pObject.name] = pObject
        pnetwork.newPList[pObject.name] = nil
        return true
    end
    
    function pnetwork.removeFromGroup(pName, groupObj)
        expect(1, pName, "string")
        expect(2, groupObj, "table")
    
        if(not groupObj._members[pName])then
            return false, "peripheral not found with that name in that group"
        end
    
        local pObject = groupObj._members[pName]
        pObject.group = nil
        groupObj._members[pName] = nil
        pnetwork.pList[pName] = nil
        pnetwork.newPList[pName] = pObject
        return true
    end
    
    
    pnetwork.ui = {}
    
    function pnetwork.ui.printList(myList)
        for key, value in pairs(myList) do
            print(key .. " - " .. textutils.serialize(value))
            print("press enter to scroll")
            local input = read()
            if(input == "q")then return  end
        end
    end
    
    function pnetwork.ui.printTable(myTable)
        print(textutils.serialize(myTable))
    end
    
    function pnetwork.ui.printPeripheral(pObject)
        local pWrap = peripheral.wrap(pObject.name)
        local pType = peripheral.getType(pWrap)
        print(pType)
        if(pWrap.size) then
            print(pWrap.size())
        end
        if(pType == "minecraft:chest" or pType == "minecraft:trapped_chest")
        then
            pnetwork.ui.printList(pWrap.list())
        end
        --TODO
    end
    
    pnetwork.ui.command = {}
    function pnetwork.ui.command.load()
        print("Enter filename: ")
        local filename = shell.resolve(read())
        local success, errorMessage = pnetwork.loadConfigFile(filename)
        if(success)
        then
            print("successfully loaded config file from: " .. filename)
        else
            print("Unable to locate a config file at: " .. filename)
            print("due to: " .. errorMessage)
        end
    end
    
    function pnetwork.ui.command.save()
        print("saving to: " ..pnetwork.getConfigFilePath())
        
        pnetwork.saveConfigFile()
        print("Successfully saved")
    end
    
    function pnetwork.ui.command.verify()
        error("TODO")
    end
    
    function pnetwork.ui.command.createGroup()
        print("Enter name for new group: ")
        local groupName = read()
    
        local success, errorMessage = pnetwork.createGroup(groupName)
        if(success) then
            print("group " .. groupName .. " has been created. Add peripherals with command addToGroup")
        else
            print("failed to create group due to: " .. errorMessage)
        end
    end
    
    function pnetwork.ui.command.renameGroup()
        print("which group would you like to rename?")
        local currentGroupName = read()
        if(currentGroupName == "")then
            print("Not a valid input")
            return
        end
        local groupObj = pnetwork.config.groupList[currentGroupName]
        if(not groupObj)
        then
            print("group did not exist")
            return
        end
    
        print("What would you like to rename it to?")
        local newGroupName = read()
        local success, errorMessage = pnetwork.renameGroup(groupObj, newGroupName)
        if(success) then
            print("Successfully renamed group")
        else
            print("Unable to rename group due to: " .. errorMessage)
        end
    end
    
    function pnetwork.ui.command.removeGroup()
        print("which group would you like to remove?")
        local groupName = read()
        if(groupName == "")then
            print("Not a valid input")
            return
        end
    
        local success, errorMessage = pnetwork.removeGroup(groupName)
        if(success) then
            print("Successfully removed group")
        else
            print("Unable to remove group due to: " .. errorMessage)
        end
    end
    
    function pnetwork.ui.command.scan()
    
        print("scanning for peripherals on network")
        pnetwork.scanForNewPeripherals()
    
        print("found these peripherals:")
        --printTable(newPList)
        pnetwork.ui.printList(pnetwork.newPList)
    end
    
    
    function pnetwork.ui.command.assignNewPeripherals()
        --cycle through pnetwork.newPList, print contents, and assign to a group. Leave blank to skip
        for pName, pObject in pairs(pnetwork.newPList) do
            print(pName)
            print(textutils.serialize(pObject))
            pnetwork.ui.printPeripheral(pObject)
            print("which group should this be assigned to? (leave blank to skip")
            local groupName = read()
            if(groupName == "")
            then
                print("skipping")
            elseif(groupName == "q" or groupName == "quit")
            then
                print("quiting command, but you can still use the save command to save your progress")
                return
            else
                if(not pnetwork.config.groupList[groupName])
                then
                    print("No group with that name. Skipping peripheral")
                elseif(pnetwork.config.groupList[groupName]._members[pObject.name])
                then
                    print("already a peripheral in that group with that name")
                else
                    pnetwork.addNewPeripheralToGroup(pObject, pnetwork.config.groupList[groupName])
                    print("Added " .. pObject.name .. " to " .. groupName)
                end 
            end
            print("Next")
        end
    end
    
    function pnetwork.ui.command.removeFromGroup()
        print("Which group would you like to remove a peripheral from?")
        local groupName = read()
        if(groupName == "")then
            print("Not a valid input")
            return
        end
        if(not pnetwork.config.groupList[groupName])then
            print("group not found with a matching name")
            return
        end
    
        print("group found")
        pnetwork.ui.printList(pnetwork.config.groupList[groupName])
        print("Which peripheral would you like to remove. It will be added to the newPList")
        local pName = read()
        if(pName == "")then
            print("not a valid input")
            return
        end
    
        local success, errorMessage = pnetwork.removeFromGroup(pName, pnetwork.config.groupList[groupName])
        if(success) then
            print(pName .. " was removed from its group. It can be found in newPList until you scan")
        else
            print("Unable to remove from group due to: " .. errorMessage)
        end
    end
    
    function pnetwork.ui.command.printPeripheral()
        print("Which group does the peripheral belong to?")
        local groupName = read()
        if(groupName == "")then
            print("Not a valid input")
            return
        end
        local currentGroup = nil
        if(groupName == "newPList")
        then
            currentGroup = pnetwork.newPList
        elseif(pnetwork.config.groupList[groupName])
        then
            currentGroup = pnetwork.config.groupList[groupName]
        else
            print("group not found with a matching name")
            return
        end
    
        local memberNameListString = ""
        for name, pObject in pairs(currentGroup._members)
        do
            memberNameListString =memberNameListString .. ", " .. name
        end
        print(memberNameListString)
        print("Which peripheral would you like to print out?")
        local pName = read()
        if(pName == "")then
            print("not a valid input")
            return
        elseif(not currentGroup._members[pName])then
            print("peripheral not found with that name in that group")
            return
        end
        local pObject = currentGroup._members[pName]
        
        print("here is the config info:")
        print(textutils.serialize(pObject))
        print("press enter for current status")
        read()
        pnetwork.ui.printPeripheral(pObject)
    end
    
    function pnetwork.ui.command.printHelp()
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
        print(" - removeFromGroup  : peripheral is removed from it's current group and added to the newPList")
        print(" - printPeripheral  : print contents of a specific peripheral")
        print("")
    end
    
    local quit = false
    function pnetwork.ui.processCommand(command)
        local command = command and tonumber(command) or command --string or number
        local case = 
        {
            ["load"] = pnetwork.ui.command.load,
            ["save"] = pnetwork.ui.command.save,
            ["verify"] = pnetwork.ui.command.verify,
            ["help"] = pnetwork.ui.command.printHelp,
            ["h"] = pnetwork.ui.command.printHelp,
            ["quit"] = function () quit = true end,
            ["q"] = function () quit = true end,
    
            ["printGroups"] = function () pnetwork.ui.printList(pnetwork.config.groupList) end,
            ["createGroup"] = pnetwork.ui.command.createGroup,
            ["renameGroup"] = pnetwork.ui.command.renameGroup,
            ["removeGroup"] = pnetwork.ui.command.removeGroup,
    
            ["scan"] = pnetwork.ui.command.scan,
            ["printNew"] = function () pnetwork.ui.printList(pnetwork.newPList) end,
            ["printRegistered"] = function () pnetwork.ui.printList(pnetwork.pList) end,
            ["assignNew"] = pnetwork.ui.command.assignNewPeripherals,
            
            ["removeFromGroup"] = pnetwork.ui.command.removeFromGroup,
            ["printPeripheral"] = pnetwork.ui.command.printPeripheral,
    
            ["default"] = function () print("command not reconized") end,
        }
    
        if case[command] then
            case[command]()
        else
            case["default"]()
        end
    end
    
    function pnetwork.ui.launch(configFileName)
        local configFileName = configFileName or pnetwork.configFileName
        local resolvedFileName = shell.resolve(configFileName)
        pnetwork.configFileName = fs.getName(resolvedFileName)
        pnetwork.configDirectory = fs.getDir(resolvedFileName)
        expect(1, pnetwork.configFileName, "string")

        if(not fs.exists(pnetwork.getConfigFilePath())) then
            print("Unable to read config file. Would you like to create a new one at: " .. pnetwork.getConfigFilePath() .. " (y/n)?")
            local answer = read()
            if(answer == "y" or answer == "yes")then
                print("creating new config file")
                pnetwork.saveConfigFile()
            else
                print("Unable to start program without a config.")
                return
            end
        elseif(pnetwork.loadConfigFile(pnetwork.configFileName))
        then
            print("successfully loaded pnetwork.config file from: " .. pnetwork.getConfigFilePath())
        else
            error("Unable to read pnetwork.config file: " .. pnetwork.getConfigFilePath())
        end
        print("Press enter to continue")
        read()
    
        pnetwork.ui.command.printHelp()
        while quit == false do
            print("")
            print("Enter command: ")
            local command = read()
            pnetwork.ui.processCommand(command)
        end
    end
    
    
    return pnetwork

end

return pnetworkBuilder