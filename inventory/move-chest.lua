--hello

local chest_source = peripheral.wrap("minecraft:chest_10")
local chest_target = peripheral.wrap("minecraft:chest_11")

for i = 1, chest_source.size(), 1
do
    chest_source.pushItems(peripheral.getName(chest_target), i)

end
