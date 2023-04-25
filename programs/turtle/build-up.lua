--just for building a tower straight up
local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()

for i = 1, 64, 1
do
    robox.up()
    robox.placeDown()
end

robox.select(2)
for i = 1, 64, 1
do
    robox.up()
    robox.placeDown()
end

robox.select(3)
for i = 1, 64, 1
do
    robox.up()
    robox.placeDown()
end

robox.select(4)
for i = 1, 64, 1
do
    robox.up()
    robox.placeDown()
end