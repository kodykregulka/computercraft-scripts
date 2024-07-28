local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range
local parallel = require(settings.get("require.api_path") .. "thread.parallel-timeout")

--implements a pull event function with a timeout

--local os = require(settings.get("require.api_path") .. "thread.pull-event-timeout").add_to_os(os)

local os_extender = {}

function os_extender.add_to_os(given_os)
	local function _pullEvent(pullFunct, eventName, eventFilterFunct)
		while true do
			local eventData = table.pack(pullFunct(eventName))
			if eventFilterFunct(eventData) then
				return eventData
			end
		end
	end

	function given_os.pullEventRawTimeout(timeout, eventName, eventFilterFunct)
		return
	end

	function given_os.pullEventTimeout(timeout, eventName, eventFilterFunct)

	end

	return given_os
end

return os_extender
