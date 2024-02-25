local parallel = require(settings.get("require.api_path") .. "thread.parallel-timeout")
local args = { ... }
local waitTime = tonumber(args[1])
local function dowait()
	os.sleep(waitTime)
end

print(parallel.waitForAllWithTimeout(5, dowait, dowait))
