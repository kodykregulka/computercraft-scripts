local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()

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

local function place64(kelpSpot, fillSpot)
    for i = 1, 64, 1
    do
        robox.select(kelpSpot)
        placeKelp()
        robox.up() -- will fail when blocked
        robox.select(fillSpot)
        robox.placeDown()
    end
end

local kelpSpot = 1
local fillSpot = 5

for i = 1, 10, 1
do
    place64(kelpSpot, fillSpot)
    kelpSpot = kelpSpot + 1
    fillSpot = fillSpot + 1
end