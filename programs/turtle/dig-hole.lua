settings.load()
local excavate = require(settings.get("require.api_path") .. "turtle.excavate")

--TODO put arg verification and a help print
local GO_HOME = true
if(arg[4] == "false")then GO_HOME = false end
excavate.digRectPrism(tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]), GO_HOME)