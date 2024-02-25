local threadExecutorBuilder = require(settings.get("require.api_path") .. "thread.thread-executor")
local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")

local threadExecutor = threadExecutorBuilder.new("test")

local function b()
	--print when certain key events happen
	while true do
		local event, key, isHeld = os.pullEvent("key")
		print(keys.getName(key) .. (isHeld and " is held" or " was pressed"))
	end
end

local bqueue = queueBuilder.new()
local function a()
	--add and remove threads
	print("starting a")
	while true do
		local event, key, isHeld = os.pullEvent("key")
		local keyname = keys.getName(key)
		if keyname == "a" then
			local threadController = threadExecutor.add(b)
			print("adding " .. threadController.id)
			bqueue.push(threadController.id)
		elseif keyname == "d" then
			local id = bqueue.pop()
			print("removing " .. id)
			threadExecutor.kill(id)
		elseif keyname == "i" then
			for id, thread in pairs(threadExecutor.threadPool._members) do
				print(id .. " : " .. coroutine.status(thread.coroutine))
			end
		end
	end
end


local rootExecutor = threadExecutorBuilder.new("root")

rootExecutor.add(threadExecutor.start)
rootExecutor.add(function()
	while true do
		local event, key = os.pullEvent("key")
		local keyname = keys.getName(key)
		if keyname == "a" then
			threadExecutor.add(a)
			local threadController = threadExecutor.add(b)
			bqueue.push(threadController.id)
			print("starting main")
			return
		end
	end
end)

rootExecutor.start()
--end
threadExecutor.start()


threadExecutor.add(a)
local threadController = threadExecutor.add(b)
bqueue.push(threadController.id)
