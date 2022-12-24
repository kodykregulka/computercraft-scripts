local robox = require(settings.get("require.api_path") .. "turtle.robox")

local function placeKelp()
    for i = 1, 5, 1
    do
        os.sleep(1)
        if(robox.place())
        then
            return true
        end
    end
    error("didnt place kelp")
end

local kelpSpot = 1
local fillSpot = 5

for i = 1, 64, 1
do
    robox.select(kelpSpot)
    placeKelp()
    robox.up() -- will fail when blocked
    robox.select(fillSpot)
    robox.placeDown()
end
kelpSpot = 2
fillSpot = 6
robox.select(2)
for i = 1, 64, 1
do
    robox.select(kelpSpot)
    placeKelp()
    robox.up() -- will fail when blocked
    robox.select(fillSpot)
    robox.placeDown()
end