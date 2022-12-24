print("setting up cc computer")

fs.makeDir("/apis")
fs.makeDir("/apis/turtle")
fs.makeDir("/programs")
fs.makeDir("/programs/turtle")

settings.load()
-- if you edit the above directory structure make sure you update this api_path 
-- look up how the require function works in lua, the .apis. means /apis/
shell.run("/startup.lua")