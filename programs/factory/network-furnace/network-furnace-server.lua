
settings.load()
local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")
local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local logBuilder = require(settings.get("require.api_path") .. "utils.log")

local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local FUEL_POINTS = {}
--FUEL_POINTS["minecraft:lava_bucket"] = 100 --not supported yet
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
    local testSlot = sourceWrap.getItemDetail(sourceSlot)
    print(textutils.serialize(testSlot))
    local currentDesiredAmount = desiredAmount or sourceWrap.getItemDetail(sourceSlot).count
    repeat
        local transferedAmount = transferedAmount + chestList.get(chestIndex).pWrap.pullItems(sourceName, sourceSlot, currentDesiredAmount)
        if(transferedAmount >= currentDesiredAmount)then
            return true
        else
            currentDesiredAmount = currentDesiredAmount - transferedAmount
            chestIndex = chestList.nextIndex()
        end
    until (chestIndex == startPoint)
    return false
end

if(not arg[1])then error("requires a directory path to a data folder") end
local dataDir = "/" .. shell.resolve(arg[1])
if(not fs.exists(dataDir))then error("requires a directory path to an existing data folder") end

--load data
local pnetworkFile = fs.open(dataDir .. "/pnetwork_config.json", "r")
local pnetworkConfig = textutils.unserialize(pnetworkFile.readAll())
local log = logBuilder.new(dataDir .. "/network-furnace-server.log", "", true, true)

--input chests
local inputChestList = listBuilder.new()
local i = 1
for _name, configChest in pairs(pnetworkConfig.groupList["input"].members) do
    if(configChest)
    then
        local tempWrap = peripheral.wrap(configChest.permName)
        inputChestList.add({
            name = configChest.permName, 
            pWrap = tempWrap,
            length = tempWrap.size(),
            lastSlot = 0
        })
    end
end

--reserve chests (for reserving items that belong to multi-itemType jobs)
local reserveChestList = listBuilder.new()
for _name, configChest in pairs(pnetworkConfig.groupList["reserve"].members) do
    --reserveChestList[configChest.permName] = peripheral.wrap(configChest.permName)
    local tempWrap = peripheral.wrap(configChest.permName)
    reserveChestList.add({
        name = configChest.permName,
        pWrap = tempWrap,
        length = tempWrap.size(),
        lastSlot = 0
    })
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
local outputChestList = listBuilder.new()
for _name, configChest in pairs(pnetworkConfig.groupList["output"].members) do
    local tempWrap = peripheral.wrap(configChest.permName)
    outputChestList.add({
        name = configChest.permName,
        pWrap = tempWrap,
        length = tempWrap.size(),
        lastSlot = 0 --we dont need this for output chest since we are just dumping
    })
end
--dropIntoChestList(outputChestList, sourceName, sourceSlot, desiredAmount)

--fuel chests
local fuelChestList = listBuilder.new()
for _name, configChest in pairs(pnetworkConfig.groupList["fuel"].members) do
    --fuelChestList[configChest.permName] = peripheral.wrap(configChest.permName)
    local tempWrap = peripheral.wrap(configChest.permName)
    fuelChestList.add({
        name = configChest.permName,
        pWrap = tempWrap,
        length = tempWrap.size(),
        lastSlot = 0
    })
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

    function furnace.addFuel(chestIndex, slotIndex, itemCount)
        return furnace.pWrap.pullItems(fuelChestList.get(chestIndex).name, slotIndex, itemCount, 2)
    end

    function furnace.addInput(chestIndex, slotIndex, itemCount)
        return furnace.pWrap.pullItems(inputChestList.get(chestIndex).name, slotIndex, itemCount, 1)
    end

    function furnace.smeltItems(inputChestIndex, inputChestSlotIndex, inputCount, fuelChestIndex, fuelChestSlotIndex, fuelCount)
        local transferedFuel = furnace.addFuel(fuelChestIndex, fuelChestSlotIndex, fuelCount)
        if(transferedFuel ~= fuelCount)then
            --dump job and return fuel
            log.warning("unable to start job due to unaccounted for fuel")
            return -1
        end
        local transferedInput = furnace.addInput(inputChestIndex, inputChestSlotIndex, inputCount)
        if(transferedInput ~= inputCount)then
            --continue job, but log warning
            log.warning("job started without the expected amount of input", "furnace.smeltItems")
        end
        local timerID = os.startTimer(inputCount*10)
        return timerID
    end

    function furnace.removeOutput()
        return dropIntoChestList(outputChestList, config.permName, 3)
    end
    return furnace
end
for _name, configFurnace in pairs(pnetworkConfig.groupList["furnaces"].members) do
    avalibleFurnaceQueue.push(furnaceBuilder.new(configFurnace))
end

local inProgressJobList = hashMapBuilder.new()     -- timerID -> jobObject
local jobIsReadyForTransferQueue = queueBuilder.new()
local jobBuilder = {}
function jobBuilder.new(furnace, fuelChestIndex, fuelChestSlotIndex, fuelCount, fuelPoints)
    local job = {}
    job.furnace = furnace
    job.fuel = {}
    job.fuel.chestIndex = fuelChestIndex
    job.fuel.chestSlotIndex = fuelChestSlotIndex
    job.fuel.count = fuelCount
    job.fuel.points = fuelPoints

    job.itemsToSmelt = 0
    job.taskInProgress = nil
    job.tasks = queueBuilder.new()
    
    function job.addTask(inputChestIndex, inputChestSlotIndex, inputCount)
        if(job.fuel.points < job.itemsToSmelt + inputCount) then
            inputCount = job.fuel.points - job.itemsToSmelt
        end
        job.itemsToSmelt = job.itemsToSmelt + inputCount
        
        job.tasks.push({
            inputChestIndex = inputChestIndex,
            inputChestSlotIndex = inputChestSlotIndex,
            inputCount = inputCount
        })
    end

    function job.addReserveTask(inputChestIndex, inputChestSlotIndex, inputCount)
        local reserveChestIndex, reserveChestSlotIndex, reserveTransferedAmount = insertIntoReserveChests(inputChestList.get(inputChestIndex).name, inputChestSlotIndex, inputCount)
        job.addTask(reserveChestIndex, reserveChestSlotIndex, reserveTransferedAmount)
    end

    function job.isEfficient()
        return job.fuel.points == job.itemsToSmelt
    end

    function job.start()
        if(job.tasks.size() < 1 or job.fuel.points < job.itemsToSmelt) then
            log.error("cannot start job with more items to smelt than it can process")
        end
        
        --move fuel
        local transferedFuel = job.furnace.addFuel(job.fuel.chestIndex, job.fuel.chestSlotIndex, job.fuel.count)
        if(transferedFuel ~= job.fuel.count)then
            --dump job and return fuel
            log.warning("unable to start job due to unaccounted for fuel")
            dropIntoChestList(fuelChestList, job.furnace.name, 2)
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
        
        local transferedInput = job.furnace.addInput(job.taskInProgress.inputChestIndex, job.taskInProgress.inputChestSlotIndex, job.taskInProgress.inputCount)
        if(transferedInput == job.taskInProgress.inputCount) then
            --success
            local timerID = os.startTimer(job.taskInProgress.inputCount*10)
            inProgressJobList.insert(timerID, job)
        elseif(transferedInput < job.taskInProgress.inputCount)then
            --continue job, but log warning
            log.warning("job started without the expected amount of input", "job.startNextTask")

            local timerID = os.startTimer(job.taskInProgress.inputCount*10)
            inProgressJobList.insert(timerID, job)
        elseif(transferedInput > job.taskInProgress.inputCount) then
            log.error("too many items transfered for job at furnace: " .. job.furnace.name, "job.startNextTask")
        else
            log.error("unable to transfer input items to furnace: " .. job.furnace.name, "job.startNextTask")
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
        if(job)
        then
            if(not job.furnace.removeOutput()) then
                log.error("unable to remove output from furnace: " .. doneFurnace.name, "handle_doneTransfer")
            end

            --see if job is done
            if(job.hasNextTask()) then
                job.startNextTask()
            else
                --job is done, release furnace
                avalibleFurnaceQueue.push(job.furnace)
            end
        else
            --delay before checking again
            os.sleep(5)
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
        os.sleep(10) -- wait 10 seconds before trying again
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
        os.sleep(10)
        return
    end

    --get an avalible furnace
    local furnace = avalibleFurnaceQueue.pop()
    if(furnace == nil)
    then
        --no furnace avalible, throw out job
        os.sleep(10)
        return
    end

    local job = jobBuilder.new(furnace, fuelChestIndex, fuelChestSlotIndex, fuelCount, fuelPoints)
    job.addTask(inputChestIndex, inputChestSlotIndex, avalibleInputCount)

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

        job.addReserveTask(inputChestIndex,inputChestSlotIndex, avalibleInputCount)
    end

    job.start()
end


local function handle_delegateFurnaceJobs()
    while true do
        delegateFurnaceJobs()
    end
end

print("Starting network-furnace-server")
local functionNumber = parallel.waitForAny(handle_doneTimer, handle_doneTransfer, handle_delegateFurnaceJobs)
local functionName = {[1] = "handle_doneTimer", [2] = "handle_doneTransfer", [3] = "handle_delegateFurnaceJobs"}
print("network-furnace-server stopped due to " .. functionName[functionNumber])