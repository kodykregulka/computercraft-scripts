
local minecraftVersion = "1.19.2"
local inputFileName = "minecraft-raw-items-" .. minecraftVersion .. ".json"
local outputFilename = "minecraft-items.json"


local inputFile = fs.open(shell.resolve(inputFileName), "r")
local inputJson = textutils.unserializeJSON(inputFile.readAll())
inputFile.close()

local outputJson = {}
outputJson._minecraft_version = minecraftVersion

for index, itemObj in pairs(inputJson) do
    outputJson[itemObj.name] = itemObj
end

function 

local outputFile = fs.open(shell.resolve(outputFilename), "w")
outputFile.write(textutils.serialize(outputJson))
outputFile.close()