
settings.load()
local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")
local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local logBuilder = require(settings.get("require.api_path") .. "utils.log")

local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local FUEL_POINTS = {}
FUEL_POINTS["minecraft:lava_bucket"] = 100
FUEL_POINTS["minecraft:coal_block"] = 80
FUEL_POINTS["minecraft:dried_kelp_block"] = 20
FUEL_POINTS["minecraft:blaze_rod"] = 12
FUEL_POINTS["minecraft:coal"] = 8
FUEL_POINTS["minecraft:charcoal"] = 8
local function getFuelPoints(fuelName)
    local points = FUEL_POINTS[fuelName]
    if(points) then
        return points
    else
        return 0
    end
end
local function isFuelSlot(slotObj)
    return slotObj and FUEL_POINTS[slotObj.name] ~= nil
end

local SMOKER_ITEMS = {}
SMOKER_ITEMS["minecraft:porkchop"] =  true
SMOKER_ITEMS["minecraft:beef"] =  true
SMOKER_ITEMS["minecraft:chicken"] =  true
SMOKER_ITEMS["minecraft:cod"] =  true
SMOKER_ITEMS["minecraft:salmon"] =  true
SMOKER_ITEMS["minecraft:potato"] =  true
SMOKER_ITEMS["minecraft:mutton"] =  true
SMOKER_ITEMS["minecraft:rabbit"] =  true
SMOKER_ITEMS["minecraft:kelp"] =  true
local BLAST_ITEMS = {}
BLAST_ITEMS["minecraft:raw_copper"] =  true
BLAST_ITEMS["minecraft:raw_iron"] =  true
BLAST_ITEMS["minecraft:raw_gold"] =  true
BLAST_ITEMS["minecraft:nether_gold_ore"] =  true
BLAST_ITEMS["minecraft:ancient_debris"] =  true
BLAST_ITEMS["minecraft:copper_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_copper_ore"] =  true
BLAST_ITEMS["minecraft:diamond_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_diamond_ore"] =  true
BLAST_ITEMS["minecraft:gold_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_gold_ore"] =  true
BLAST_ITEMS["minecraft:iron_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_iron_ore"] =  true
BLAST_ITEMS["minecraft:lapis_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_lapis_ore"] =  true
BLAST_ITEMS["minecraft:redstone_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_redstone_ore"] =  true
BLAST_ITEMS["minecraft:coal_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_coal_ore"] =  true
BLAST_ITEMS["minecraft:emerald_ore"] =  true
BLAST_ITEMS["minecraft:deepslate_emerald_ore"] =  true
BLAST_ITEMS["minecraft:nether_quartz_ore"] =  true
BLAST_ITEMS["minecraft:iron_sword"] =  true
BLAST_ITEMS["minecraft:golden_sword"] =  true
BLAST_ITEMS["minecraft:iron_pickaxe"] =  true
BLAST_ITEMS["minecraft:golden_pickaxe"] =  true
BLAST_ITEMS["minecraft:iron_axe"] =  true
BLAST_ITEMS["minecraft:golden_axe"] =  true
BLAST_ITEMS["minecraft:iron_shovel"] =  true
BLAST_ITEMS["minecraft:golden_shovel"] =  true
BLAST_ITEMS["minecraft:iron_hoe"] =  true
BLAST_ITEMS["minecraft:golden_hoe"] =  true
BLAST_ITEMS["minecraft:iron_helmet"] =  true
BLAST_ITEMS["minecraft:chainmail_helmet"] =  true
BLAST_ITEMS["minecraft:golden_helmet"] =  true
BLAST_ITEMS["minecraft:iron_chestplate"] =  true
BLAST_ITEMS["minecraft:chainmail_chestplate"] =  true
BLAST_ITEMS["minecraft:golden_chestplate"] =  true
BLAST_ITEMS["minecraft:iron_pants"] =  true
BLAST_ITEMS["minecraft:chainmail_pants"] =  true
BLAST_ITEMS["minecraft:golden_pants"] =  true
BLAST_ITEMS["minecraft:iron_boots"] =  true
BLAST_ITEMS["minecraft:chainmail_boots"] =  true
BLAST_ITEMS["minecraft:golden_boots"] =  true
BLAST_ITEMS["minecraft:iron_horse_armor"] =  true
BLAST_ITEMS["minecraft:golden_horse_armor"] =  true
local FURNACE_ITEMS = {}
FURNACE_ITEMS["minecraft:sand"] =  true
FURNACE_ITEMS["minecraft:cobblestone"] =  true
FURNACE_ITEMS["minecraft:sandstone"] =  true
FURNACE_ITEMS["minecraft:red_sandstone"] =  true
FURNACE_ITEMS["minecraft:stone"] =  true
FURNACE_ITEMS["minecraft:quartz_block"] =  true
FURNACE_ITEMS["minecraft:clay_ball"] =  true
FURNACE_ITEMS["minecraft:netherrack"] =  true
FURNACE_ITEMS["minecraft:nether_bricks"] =  true
FURNACE_ITEMS["minecraft:basalt"] =  true
FURNACE_ITEMS["minecraft:clay"] =  true
FURNACE_ITEMS["minecraft:stone_bricks"] =  true
FURNACE_ITEMS["minecraft:polished_blackstone_bricks"] =  true
FURNACE_ITEMS["minecraft:cobbled_deepslate"] =  true
FURNACE_ITEMS["minecraft:deepslate_bricks"] =  true
FURNACE_ITEMS["minecraft:deepslate_tiles"] =  true
FURNACE_ITEMS["minecraft:white_terracotta"] =  true
FURNACE_ITEMS["minecraft:red_terracotta"] =  true
FURNACE_ITEMS["minecraft:lime_terracotta"] =  true
FURNACE_ITEMS["minecraft:pink_terracotta"] =  true
FURNACE_ITEMS["minecraft:gray_terracotta"] =  true
FURNACE_ITEMS["minecraft:cyan_terracotta"] =  true
FURNACE_ITEMS["minecraft:blue_terracotta"] =  true
FURNACE_ITEMS["minecraft:brown_terracotta"] =  true
FURNACE_ITEMS["minecraft:green_terracotta"] =  true
FURNACE_ITEMS["minecraft:black_terracotta"] =  true
FURNACE_ITEMS["minecraft:orange_terracotta"] =  true
FURNACE_ITEMS["minecraft:yellow_terracotta"] =  true
FURNACE_ITEMS["minecraft:purple_terracotta"] =  true
FURNACE_ITEMS["minecraft:magenta_terracotta"] =  true
FURNACE_ITEMS["minecraft:light_blue_terracotta"] =  true
FURNACE_ITEMS["minecraft:light_gray_terracotta"] =  true
FURNACE_ITEMS["minecraft:cactus"] =  true
FURNACE_ITEMS["minecraft:oak_log"] =  true
FURNACE_ITEMS["minecraft:birch_log"] =  true
FURNACE_ITEMS["minecraft:spruce_log"] =  true
FURNACE_ITEMS["minecraft:jungle_log"] =  true
FURNACE_ITEMS["minecraft:acacia_log"] =  true
FURNACE_ITEMS["minecraft:dark_oak_log"] =  true
FURNACE_ITEMS["minecraft:mangrove_log"] =  true
FURNACE_ITEMS["minecraft:crimson_stem"] =  true
FURNACE_ITEMS["minecraft:warped_stem"] =  true
FURNACE_ITEMS["minecraft:stripped_oak_log"] =  true
FURNACE_ITEMS["minecraft:stripped_birch_log"] =  true
FURNACE_ITEMS["minecraft:stripped_spruce_log"] =  true
FURNACE_ITEMS["minecraft:stripped_jungle_log"] =  true
FURNACE_ITEMS["minecraft:stripped_acacia_log"] =  true
FURNACE_ITEMS["minecraft:stripped_dark_oak_log"] =  true
FURNACE_ITEMS["minecraft:stripped_mangrove_log"] =  true
FURNACE_ITEMS["minecraft:stripped_crimson_stem"] =  true
FURNACE_ITEMS["minecraft:stripped_warped_stem"] =  true
FURNACE_ITEMS["minecraft:oak_wood"] =  true
FURNACE_ITEMS["minecraft:birch_wood"] =  true
FURNACE_ITEMS["minecraft:spruce_wood"] =  true
FURNACE_ITEMS["minecraft:jungle_wood"] =  true
FURNACE_ITEMS["minecraft:acacia_wood"] =  true
FURNACE_ITEMS["minecraft:dark_oak_wood"] =  true
FURNACE_ITEMS["minecraft:mangrove_wood"] =  true
FURNACE_ITEMS["minecraft:crimson_hyphae"] =  true
FURNACE_ITEMS["minecraft:warped_hyphae"] =  true
FURNACE_ITEMS["minecraft:stripped_oak_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_birch_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_spruce_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_jungle_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_acacia_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_dark_oak_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_mangrove_wood"] =  true
FURNACE_ITEMS["minecraft:stripped_crimson_hyphae"] =  true
FURNACE_ITEMS["minecraft:stripped_warped_hyphae"] =  true
FURNACE_ITEMS["minecraft:chorus_fruit"] =  true
FURNACE_ITEMS["minecraft:wet_sponge"] =  true
FURNACE_ITEMS["minecraft:sea_pickle"] =  true
local function isSmeltable(name)
    return SMOKER_ITEMS[name] or BLAST_ITEMS[name] or FURNACE_ITEMS[name]
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
local function isEmptySlot(slotObj)
    return slotObj == nil
end
local function isSmeltableSlot(slotObj)
    if(slotObj ~= nil) then
        return slotObj.count > 0 and isSmeltable(slotObj.name)
    end
    return false
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
    local startPoint = chestList.lastIndex
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

if(not arg[1])then error("requires a directory path to a data folder") end
local dataDir = "/" .. shell.resolve(arg[1])
if(not fs.exists(dataDir))then error("requires a directory path to an existing data folder") end

--load data
local pnetworkFile = fs.open(dataDir .. "/pnetwork_config.json", "r")
local pnetworkConfig = textutils.unserialize(pnetworkFile.readAll())
local log = logBuilder.new(dataDir .. "/network-furnace-server.log", "", true, true)

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

--input chests
local inputChestList = listBuilder.new("input chests")
local i = 1
for _name, configChest in pairs(pnetworkConfig.groupList["input"].members) do
    if(configChest)
    then
        local tempWrap = peripheral.wrap(configChest.permName)
        inputChestList.add(
            chestBuilder.new(
                configChest.permName, 
                tempWrap, 
                tempWrap.size()
            )
        )
    end
end

--reserve chests (for reserving items that belong to multi-itemType jobs)
local reserveChestList = listBuilder.new("reserve chests")
for _name, configChest in pairs(pnetworkConfig.groupList["reserve"].members) do
    --reserveChestList[configChest.permName] = peripheral.wrap(configChest.permName)
    local tempWrap = peripheral.wrap(configChest.permName)
    reserveChestList.add(
        chestBuilder.new(
            configChest.permName, 
            tempWrap, 
            tempWrap.size()
        )
    )
end
local function insertIntoReserveChests(sourceName, sourceSlot, desiredAmount)
    local chestIndex, slotIndex = findNextChestSlotWithCriteria(reserveChestList, isEmptySlot)
    local transferedAmount = reserveChestList.get(chestIndex).pWrap.pullItems(sourceName, sourceSlot, desiredAmount, slotIndex)
    if(desiredAmount == transferedAmount)
    then
        return chestIndex, slotIndex, transferedAmount
    elseif(transferedAmount > desiredAmount)
    then
        error("too many items sent to reserve chest") -- this shouldnt happen
    elseif(transferedAmount == 0)
    then
        return -1, -1, 0
    else
        --transfered some items, not all
        --still work as intended for input chest to reserve slot. 
        --TODO If this is used by other functions we may want different behavior
        return chestIndex, slotIndex, transferedAmount
    end
end

--output chests
local outputChestList = listBuilder.new("output chests")
for _name, configChest in pairs(pnetworkConfig.groupList["output"].members) do
    local tempWrap = peripheral.wrap(configChest.permName)
    outputChestList.add(
        chestBuilder.new(
            configChest.permName, 
            tempWrap, 
            tempWrap.size()
        )
    )
end
--dropIntoChestList(outputChestList, sourceName, sourceSlot, desiredAmount)

--fuel chests
local fuelChestList = listBuilder.new("fuel chests")
for _name, configChest in pairs(pnetworkConfig.groupList["fuel"].members) do
    --fuelChestList[configChest.permName] = peripheral.wrap(configChest.permName)
    local tempWrap = peripheral.wrap(configChest.permName)
    fuelChestList.add(
        chestBuilder.new(
            configChest.permName, 
            tempWrap, 
            tempWrap.size()
        )
    )
end
-- find fuel : local chestIndex, slotIndex, itemCount, itemName = findNextChestSlotWithCriteria(fuelChestList, isFuelSlot)
-- drop into fuelChestList : dropIntoChestList(fuelChestList, sourceName, sourceSlot, desiredAmount)

--furnace
local avalibleFurnaceQueue = queueBuilder.new()
local furnaceBuilder = {}
function furnaceBuilder.new(config)
    local furnace = {}
    furnace.name = config.permName
    furnace.pWrap = peripheral.wrap(config.permName)

    function furnace.addFuel(chestObj, slotIndex, itemCount)
        return furnace.pWrap.pullItems(chestObj.name, slotIndex, itemCount, 2)
    end

    function furnace.addInput(chestObj, slotIndex, itemCount)
        return furnace.pWrap.pullItems(chestObj.name, slotIndex, itemCount, 1)
    end

    function furnace.removeOutput()
        --if(furnace.pWrap.getItemDetail(2) ~= nil)then
            --empty fuel, it may be a bucket
         --   dropIntoChestList(fuelChestList, furnace.name, 2)
        --end

        return dropIntoChestList(outputChestList, furnace.name, 3)
    end

    function furnace.reset()
        --push input back to input chests
        dropIntoChestList(inputChestList, furnace.name, 1)
        if(furnace.pWrap.getItemDetail(1) ~= nil) then log.error("unable to clear furnace input for furnace: " .. furnace.name) end
        --push fuel to fuel chests
        dropIntoChestList(fuelChestList, furnace.name, 2)
        if(furnace.pWrap.getItemDetail(2) ~= nil) then log.error("unable to clear furnace fuel for furnace: " .. furnace.name) end
        --push output to output chests
        dropIntoChestList(outputChestList, furnace.name, 3)
        if(furnace.pWrap.getItemDetail(3) ~= nil) then log.error("unable to clear furnace output for furnace: " .. furnace.name) end
    end
    return furnace
end
for _name, configFurnace in pairs(pnetworkConfig.groupList["furnaces"].members) do
    avalibleFurnaceQueue.push(furnaceBuilder.new(configFurnace))
end

local inProgressJobList = hashMapBuilder.new()     -- timerID -> jobObject
local jobIsReadyForTransferQueue = queueBuilder.new()
local jobBuilder = {}
function jobBuilder.new(furnace, fuelChestObj, fuelChestSlotIndex, fuelCount, fuelPoints)
    local job = {}
    job.furnace = furnace
    job.fuel = {}
    job.fuel.chestObj = fuelChestObj
    job.fuel.slotIndex = fuelChestSlotIndex
    job.fuel.count = fuelCount
    job.fuel.points = fuelPoints

    job.itemsToSmelt = 0
    job.taskInProgress = nil
    job.tasks = queueBuilder.new()
    
    function job.addTask(chestObj, chestSlotIndex, itemCount, itemName)
        if(job.fuel.points < job.itemsToSmelt + itemCount) then
            itemCount = job.fuel.points - job.itemsToSmelt
        end
        job.itemsToSmelt = job.itemsToSmelt + itemCount
        
        job.tasks.push({
            chestObj = chestObj,
            chestSlotIndex = chestSlotIndex,
            itemCount = itemCount,
            itemName = itemName
        })
    end

    function job.addFirstTask(chestObj, chestSlotIndex, itemCount, itemName)
        if(job.fuel.points < job.itemsToSmelt + itemCount) then --item to smelt will be zero
            itemCount = job.fuel.points - job.itemsToSmelt
        end

        if(job.fuel.points == itemCount)
        then
            print("Queueing task " .. job.furnace.name .. " : " .. itemName .. " : " .. itemCount)
            job.addTask(chestObj, chestSlotIndex, itemCount, itemName)
        else
            --must add these to reserve chest to avoid finding it in another search
            local reserveChestIndex, reserveChestSlotIndex, reserveTransferedAmount = insertIntoReserveChests(chestObj.name, chestSlotIndex, itemCount)
            print("Queueing task into reserve " .. job.furnace.name .. " : " .. itemName .. " : " .. itemCount)
            job.addTask(reserveChestList.get(reserveChestIndex), reserveChestSlotIndex, reserveTransferedAmount, itemName)
        end
    end

    function job.addReserveTask(chestObj, chestSlotIndex, itemCount, itemName)
        if(job.fuel.points < job.itemsToSmelt + itemCount) then
            itemCount = job.fuel.points - job.itemsToSmelt
        end
        local reserveChestIndex, reserveChestSlotIndex, reserveTransferedAmount = insertIntoReserveChests(chestObj.name, chestSlotIndex, itemCount)
        print("Queueing reserve task " .. job.furnace.name .. " : " .. itemName .. " : " .. itemCount)
        job.addTask(reserveChestList.get(reserveChestIndex), reserveChestSlotIndex, reserveTransferedAmount, itemName)
    end

    function job.isEfficient()
        return job.fuel.points == job.itemsToSmelt
    end

    function job.start()
        if(job.tasks.size() < 1 or job.fuel.points < job.itemsToSmelt) then
            log.error("cannot start job with more items to smelt than it can process")
        end

        print("starting job " .. job.furnace.name)
        
        --move fuel
        local transferedFuel = job.furnace.addFuel(job.fuel.chestObj, job.fuel.slotIndex, job.fuel.count)
        if(transferedFuel ~= job.fuel.count)then
            --dump job and return fuel
            log.warning("unable to start job due to unaccounted for fuel")
            dropIntoChestList(fuelChestList, job.furnace.name, 2)
            if(job.furnace.pWrap.getItemDetail(2) ~= nil) then log.error("unable to clear furnace fuel for furnace: " .. job.furnace.name) end
            return false
        end

        job.startNextTask()
    end

    function job.hasNextTask()
        return job.tasks.peek() ~= nil
    end

    function job.startNextTask()
        --move inputs for task
        job.taskInProgress = job.tasks.pop()
        print("starting task " .. job.furnace.name .. " : " .. job.taskInProgress.itemName .. " : " .. job.taskInProgress.itemCount)
        
        local transferedInput = job.furnace.addInput(job.taskInProgress.chestObj, job.taskInProgress.chestSlotIndex, job.taskInProgress.itemCount)
        if(transferedInput == job.taskInProgress.itemCount) then
            --success
            local timerID = os.startTimer(job.taskInProgress.itemCount*10)
            if(furnace.pWrap.getItemDetail(2).name == "minecraft:bucket")then
                --remove empty bucket
                dropIntoChestList(fuelChestList, furnace.name, 2)
            end
            inProgressJobList.insert(timerID, job)
        elseif(transferedInput < job.taskInProgress.itemCount)then
            --continue job, but log warning
            log.warning("job started without the expected amount of input. " .. transferedInput .. " instead of " .. job.taskInProgress.itemCount, "job.startNextTask")

            local timerID = os.startTimer(job.taskInProgress.itemCount*10)
            inProgressJobList.insert(timerID, job)
        elseif(transferedInput > job.taskInProgress.itemCount) then
            log.error("too many items transfered for job at furnace: " .. job.furnace.name, "job.startNextTask")
        else
            log.error("unable to transfer input items to furnace: " .. job.furnace.name, "job.startNextTask")
        end
    end

    function job.clearTasks()
        --returns all reserved resources back to their original chests
        while job.tasks.hasNext() do
            local task = job.tasks.pop()
            dropIntoChestList(inputChestList, task.chestObj.name, task.chestSlotIndex)
            if(task.chestObj.pWrap.getItemDetail(task.chestSlotIndex) ~= nil) then
                log.error("unable to clear reserve chest: " .. task.chestObj.name)
            end
            job.tasks = queueBuilder.new()
        end
    end

    return job
end

local function handle_doneTimer()
    while true do
        local event, timerID = os.pullEvent("timer")
        local job = inProgressJobList.get(timerID)
        if(job) -- throw out all other timers
        then
            jobIsReadyForTransferQueue.push(job)
            inProgressJobList.remove(timerID)
        end
    end
end

local function handle_doneTransfer()
    while true do
        local job = jobIsReadyForTransferQueue.pop()
        if(not job)
        then
            --delay before checking again
            os.sleep(5)
        else
            --make sure task is done
            local smeltedItems = job.furnace.removeOutput()
            if(smeltedItems < job.taskInProgress.itemCount)
            then
                --try a few times to clear furnace
                for failCount = 1, 3, 1
                do
                    os.sleep(1)
                    smeltedItems = smeltedItems + job.furnace.removeOutput()
                    if(smeltedItems >= job.taskInProgress.itemCount)
                    then
                        break --good
                    end
                end
                --unable to clear furnace of task, clear furnace out and clear job and all of its reserves
                job.furnace.reset()
                job.clearTasks()
                avalibleFurnaceQueue.push(job.furnace)
            end

            print("completed task " .. job.furnace.name .. " : " .. job.taskInProgress.itemName .. " : " .. job.taskInProgress.itemCount)

            --see if job is done
            if(job.hasNextTask()) then
                job.startNextTask()
            else
                --job is done, release furnace
                print("completed job " .. job.furnace.name)
                avalibleFurnaceQueue.push(job.furnace)
            end
        end
    end
end

local function delegateFurnaceJobs()
    --grab the fuel for this job, it will determine item count
    local fuelChestIndex, fuelChestSlotIndex, avalibleFuelCount, fuelName = findNextChestSlotWithCriteria(fuelChestList, isFuelSlot)
    if(fuelChestIndex == -1 or avalibleFuelCount == 0)
    then
        --no fuel avalible, throw out job
        log.warning("no fuel avalible", "handle_delegateFurnaceJobs")
        os.sleep(5) -- wait 10 seconds before trying again
        return
    end

    --we have fuel!
    local fuelCount = 1 --this will work for all current fuels and should speed up furnace jobs by spreading the work across all furnaces
    local fuelPoints = getFuelPoints(fuelName) * fuelCount --amount of items that we can smelt with this fuel

    --get input items
    local inputChestIndex, inputChestSlotIndex, avalibleInputCount, inputName = findNextChestSlotWithCriteria(inputChestList, isSmeltableSlot)
    if(inputChestIndex == -1 or avalibleInputCount == 0)
    then
        --nothing to smelt, throw out job
        os.sleep(5)
        return
    end

    print("found input " .. inputName .. " with " .. avalibleInputCount)

    --get an avalible furnace
    local furnace = avalibleFurnaceQueue.pop()
    if(furnace == nil)
    then
        --no furnace avalible, throw out job
        os.sleep(10)
        return
    end

    local job = jobBuilder.new(furnace, fuelChestList.get(fuelChestIndex), fuelChestSlotIndex, fuelCount, fuelPoints)
    job.addFirstTask(inputChestList.get(inputChestIndex), inputChestSlotIndex, avalibleInputCount, inputName)

    while job.isEfficient() == false do
        --not enough input items for fuel
        --lets try to find another input slot to create a reserve task to follow it
        --get input items
        local inputChestIndex, inputChestSlotIndex, avalibleInputCount, inputName = findNextChestSlotWithCriteria(inputChestList, isSmeltableSlot)
        if(inputChestIndex == -1 or avalibleInputCount == 0)
        then
            --nothing else to smelt, start job inefficently 
            break
        end

        print("found reserve input " .. inputName .. " with " .. avalibleInputCount)
        job.addReserveTask(inputChestList.get(inputChestIndex), inputChestSlotIndex, avalibleInputCount, inputName)
    end

    job.start()
end


local function handle_delegateFurnaceJobs()
    while true do
        delegateFurnaceJobs()
    end
end

local command = arg[2]
if(command == nil) then
    print("please enter a command after the data directory.")
    print("launch : will start the furnace main application for normal use")
    print("reset  : will clear all of the furnaces and reserve chests to return the furnace to a good state")
elseif(command == "launch")then
    print("Starting network-furnace-server")
    local functionNumber = parallel.waitForAny(handle_doneTimer, handle_doneTransfer, handle_delegateFurnaceJobs)
    local functionName = {[1] = "handle_doneTimer", [2] = "handle_doneTransfer", [3] = "handle_delegateFurnaceJobs"}
    print("network-furnace-server stopped due to " .. functionName[functionNumber])
elseif(command == "reset")then
    print("clearing reserve chests")
    for _index, chest in pairs(reserveChestList.members) do
        for slotIndex, slotObj in pairs(chest.pWrap.list())do
            dropIntoChestList(inputChestList, chest.name, slotIndex)
        end
    end

    print("clearing furnaces")
    for _index, furnace in pairs(avalibleFurnaceQueue.data) do
        if(furnace.pWrap.getItemDetail(1)) then
            dropIntoChestList(inputChestList, furnace.name, 1)
        end
        if(furnace.pWrap.getItemDetail(2)) then
            dropIntoChestList(fuelChestList, furnace.name, 2)
        end
        if(furnace.pWrap.getItemDetail(3)) then
            dropIntoChestList(outputChestList, furnace.name, 3)
        end
    end
else
    print("command not reconized")
end
