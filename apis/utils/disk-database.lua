local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local hashMapBuilder = require(settings.get("require.api_path") .. "utils.hash-map")
local stackBuilder = require(settings.get("require.api_path") .. "utils.stack")
local listBuilder = require(settings.get("require.api_path") .. "utils.iterable-list")

local databaseBuilder = {}

databaseBuilder.configFileName = "database-config.json"

local function _createTable(database, tableName)
    local tableObj = {}
    table.name = tableName
    table.recordHashMap = hashMapBuilder.new()
    table.tableData = {}
    table.action = {}

    function tableObj.save()
        local file = fs.open(fs.combine(database.config.tableDirectory, tableName .. ".json"), "w")
        local tableToSave = {}
        tableToSave.name = tableObj.name
        tableToSave.tableData = tableObj.tableData
        tableToSave.recordHashMap = tableObj.recordHashMap.toJsonObj()
        local jsonString = textutils.serialize(tableToSave)
        file.write(jsonString)
        file.close()
    end

    database.tableHashMap.insert(tableName, tableObj)
    return tableObj
end

local function _newDatabase(dbDirectory, config)
    local database = {}
    database.config = config
    database.action = {}
    database.dbDirectory = dbDirectory
    database.tableHashMap = hashMapBuilder.new()
    
    function database.createTable(tableName)
        local newTable = _createTable(database, tableName)
        newTable.save()
        return newTable
    end

    function database.removeTable(tableName)
        local tableToRemove = database.tableHashMap.get(tableName)
        if(tableToRemove ~= nil) then
            fs.delete(fs.combine(database.config.tableDirectory, tableToRemove.name .. ".json"))
            database.tableHashMap.remove(tableName)
        end
    end

    function database.saveConfig()
        local configFileName = fs.combine(database.dbDirectory, databaseBuilder.configFileName)
        local configFile = fs.open(configFileName, "w")
        configFile.write(textutils.serialize(database.config))
        configFile.close()
    end

    return database
end

function databaseBuilder.new(dbDirectory, tableDirectory)
    fs.makeDir(dbDirectory)
    if(~fs.exists(dbDirectory))then
        error("unable to create a database at " .. dbDirectory, 2)
    end

    tableDirectory = tableDirectory or fs.combine(dbDirectory, "tables")
    fs.makeDir(tableDirectory)
    if(~fs.exists(tableDirectory))then
        error("unable to create a database at " .. tableDirectory, 2)
    end

    local configJson = {}
    configJson.tableDirectory = tableDirectory

    local configFileName = fs.combine(dbDirectory, databaseBuilder.configFileName)
    local configFile = fs.open(configFileName, "w")
    configFile.write(textutils.serialize(configJson))
    configFile.close()

    return _newDatabase(dbDirectory, configJson)
end

function databaseBuilder.load(dbDirectory)
    if(~fs.isDir(dbDirectory))then
        error("unable to find a database at " .. dbDirectory, 2)
    end

    local configFileName = fs.combine(dbDirectory, databaseBuilder.configFileName)
    local configFile = fs.open(configFileName, "r")
    local configJson = textutils.unserialize(configFile.readAll())
    configFile.close()

    if(~fs.isDir(configJson.tableDirectory)) then
        error("unable to read database tables")
    end

    local db = _newDatabase(dbDirectory, configJson)

    --populate db with data from file
    local tableFiles = fs.list(configJson.tableDirectory)
    for key, element_name in pairs(tableFiles)
    do
        local fileName = fs.combine(configJson.tableDirectory, element_name)
        local file = fs.open(fileName, "r")
        local tableJson = textutils.unserialize(file.readAll())
        if(~tableJson or ~tableJson.name or ~tableJson.tableData or ~tableJson.recordHashMap) then
            error("unable to read table " .. fileName)
        end

        local loadTable = _createTable(db,tableJson.name)
        loadTable.tableData = tableJson.tableData
        loadTable.recordHashMap = listBuilder.fromJsonObj(tableJson.recordHashMap)
    end

    return db
end

return databaseBuilder