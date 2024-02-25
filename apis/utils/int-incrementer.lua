local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range


local intIncrementerBuilder = {}
function intIncrementerBuilder.new(startingIndex, min, max)
	local intIncrementer = {}
	local nextIndex = startingIndex or 1
	local minIndex = min or 0
	local maxIndex = max or 2000000

	function intIncrementer.getMax() return maxIndex end

	function intIncrementer.getMin() return minIndex end

	function intIncrementer.setMax(newMax)
		if nextIndex > newMax then
			nextIndex = minIndex
		end
		maxIndex = newMax
	end

	function intIncrementer.setMin(newMin)
		if nextIndex < newMin then
			nextIndex = newMin
		end
		minIndex = newMin
	end

	function intIncrementer.next()
		local retval = nextIndex
		if nextIndex == maxIndex then
			nextIndex = minIndex
		else
			nextIndex = nextIndex + 1
		end
		return retval
	end

	return intIncrementer
end

return intIncrementerBuilder
