--just for building a tower straight up
local robox = require(settings.get("require.api_path") .. "turtle.robox")

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