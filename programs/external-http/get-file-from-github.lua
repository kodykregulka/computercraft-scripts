--get command line args
args = {...}
--for testing lets get turtle/dig-hole.lua
local sourceFilename = args[1] or "turtle/dig-hole.lua"
--this will extract the filename "dig-hole.lua"
local targetFilename = args[2] or sourceFilename:match( "([^/]+)$" )

--getting file from github
local link = "https://raw.githubusercontent.com/kodykregulka/computercraft-scripts/main/" .. sourceFilename

local request = http.get(link)
local targetFile = fs.open(targetFilename, "w")
--print(request.readAll())
targetFile.write(request.readAll())
targetFile.close()
-- => HTTP is working!
request.close()