local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local intIncrementerBuilder = require(settings.get("require.api_path") .. "utils.int-incrementer")

--list of objects that have unique ids and can be infinatly* added to
-- and any object can be removed at any time via the function

local poolBuilder = {}
function poolBuilder.new(max)
	local pool = {}
	pool._members = {}
	pool._size = 0

	local memberMax = max or 1000
	local intIncrementer = intIncrementerBuilder.new(1, 1, memberMax)
	function pool.getMemberMax() return memberMax end

	function pool.setMemberMax(newmax)
		if pool._size > newmax then
			error("new max is lower than current member count", 2)
		end
		intIncrementer.setMax(newmax)
		memberMax = newmax
	end

	function pool.add(obj)
		if (pool._size >= memberMax) then
			error("pool is full", 2)
		end
		local index = intIncrementer.next()
		while pool._members[index] ~= nil do -- this should not race i the size is properly managed
			index = intIncrementer.next()
		end
		pool._members[index] = obj
		pool._size = pool._size + 1
		return index
	end

	function pool.remove(index)
		if pool._members[index] ~= nil then
			pool._members[index] = nil
			pool._size = pool._size - 1
		end
	end

	return pool
end

return poolBuilder
