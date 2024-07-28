local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local poolBuilder = require(settings.get("require.api_path") .. "utils.pool")
local queueBuilder = require(settings.get("require.api_path") .. "utils.queue")
local parallel = require(settings.get("require.api_path") .. "thread.parallel-timeout")


--will run multiple functions like parallel API
--however will allow functions to be added and removed from thread pool
--be careful with gui stuff

--public
--create(funct...) -> returns list of ThreadController
--shutdown --kills all threads and ends executor
--start() --starts up the thread executor and does not yield until shutdown, this is your root call
--add(funct...) --adds funct to thread pool, returns ThreadController obj that will return the results eventually and can be waited on
--kill(thread ID ?)
--getPool
--

local function newThreadController(threadExecutor, thread)
	local threadController = {}
	threadController.id = nil --will be given a value when added to the pool

	--no start command, it will already be started when entering the threadPool
	function threadController.getStatus() return coroutine.status(thread.coroutine) end

	threadController.getResults = function() return thread.results end

	--kill command will just issue the kill command to the executor it belongs to
	function threadController.kill()
		--make sure we dont have any hanging references so garbage collecter can take care of coroutine
		threadController.getStatus = function() return "killed" end
		threadController.getResults = function() return nil end
		threadExecutor.kill(threadController.id)
	end

	--wait will yield until the desired thread returns
	function threadController.wait() --todo timeout?
		while true do
			local event, id = os.pullEvent(config.END_EVENT)
			if id == threadController.id then
				return threadController.getResults()
			end
		end
	end

	return threadController
end

local threadExecutorBuilder = {}
function threadExecutorBuilder.new(new_config)
	--once thread executor is started it is not suggested to edit the config externally
	--id is for identiying this instance of the thread-executor
	local config              = {}
	config.id                 = new_config.id or math.random(1000)
	config.EVENT_TYPE         = new_config.EVENT_TYPE or ("thread-executor-" .. config.id)
	config.WAKEUP_EVENT       = new_config.WAKEUP_EVENT or (config.EVENT_TYPE .. "-start")
	config.END_EVENT          = new_config.END_EVENT or (config.EVENT_TYPE .. "-end")
	config.pullEventFunction  = new_config.WAKEUP_EVENT or os.pullEventRaw
	config.close_when_empty   = new_config.close_when_empty or true
	local threadExecutor      = {}
	--this reference will be removed after executor is started to prevent unwanted modification
	threadExecutor._config    = config
	local threadPool          = poolBuilder.new(1000);
	threadExecutor.threadPool = threadPool --todo temp dev
	local shutdown            = false
	local executor_status     = "NOT_STARTED"
	--local commandQueue = queueBuilder.new()

	function threadExecutor.getStatus()
		return executor_status
	end

	function threadExecutor.kill(id)
		--not an active kill, just removes it from the pool so it can never resume
		--garbage collector should take care of it
		threadPool.remove(id)
	end

	function threadExecutor.add(funct, ...)
		local thread = {} --todo has internal stuff
		local f = funct
		local args = { ... }
		if #args > 0 then
			f = function()
				return funct(table.unpack(args))
			end
		end
		thread.coroutine = coroutine.create(f)
		thread.results = nil                                           --will be given a value throughout the execution or just at end?
		local threadController = newThreadController(threadExecutor, thread) --todo what we share with others
		threadController.id = threadPool.add(thread)                   --this will launch the thread asap
		os.queueEvent(config.WAKEUP_EVENT)                             --wakeup the executor if sleeping
		return threadController
	end

	function threadExecutor.addAll(...)
		--assume it is a list of lists
		-- {{funct1, arg1, arg2}, {funct2, arg1, arg2}, {funct3}, ...}
		local functList = table.pack(...)
		for i = 1, functList.n, 1 do
			local fargs = functList[i]
			local fn = fargs[1]
			if type(fn) ~= "function" then
				error("bad argument #" .. i .. " (function expected, got " .. type(fn) .. ")", 2)
			end
			threadExecutor.add(table.unpack(fargs))
		end
	end

	--start
	--this will not yield until shutdown, this should be your root loop of your program
	function threadExecutor.start()
		--remove access to config to prevent modification after start
		threadExecutor.config = nil
		executor_status = "RUNNING"
		local eventData = { n = 0 }

		while true do
			--todo empty pool event listen
			if threadPool._size == 0 then
				--wait until we get a wakeup event since no threads to manage
				os.pullEvent(config.WAKEUP_EVENT) --probably need to pull raw, but do that later
			end

			--todo shutdown check
			if shutdown then
				--should we clear the whole coroutine pool?
				executor_status = "DEAD"
				return
			end

			for id, thread in pairs(threadPool._members) do
				local cr = thread.coroutine
				if thread.filter == nil or thread.filter == eventData[1] or eventData[1] == "terminate" then
					local ok, parm = coroutine.resume(cr, table.unpack(eventData, 1, eventData.n))
					if not ok then
						error(parm, 0)
					else
						thread.filter = parm
					end
					if coroutine.status(cr) == "dead" then
						threadPool.remove(id)
					end
				end
			end
			for id, thread in ipairs(threadPool._members) do
				if thread and coroutine.status(thread.coroutine) == "dead" then
					threadPool.remove(id)
				end
			end
			eventData = table.pack(config.pullEventRaw())
		end
	end

	--shutdown
	function threadExecutor.shutdown()
		executor_status = "SHUTTING_DOWN"
		shutdown = true
	end

	--getPool --will require us to map the threadPool to a threadControllerPool

	return threadExecutor
end

return threadExecutorBuilder
