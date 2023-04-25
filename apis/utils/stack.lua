local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range


local stackBuilder = {}


function stackBuilder.new()
    local stack = {}
    stack.data = {}
    stack.last = 0
    
    function stack.push(value)
        stack.last = stack.last + 1
        stack.data[stack.last] = value
    end

    function stack.hasNext()
        return stack.data[stack.last] ~= nil
    end
    function stack.peek()
        return stack.data[stack.last]
    end
    function stack.pop()
        if(stack.data[stack.last] ~= nil) then
            local value = stack.data[stack.last]
            stack.data[stack.last] = nil
            stack.last = stack.last - 1
            return value
        else
            return nil
        end
    end

    function stack.size()
        return stack.last
    end

    function stack.print()
        if(stack.last < 1) then
            return
        end
        for i = 1, stack.last, 1 do
            print(textutils.serialize(stack.data[i]))
        end
    end

    function stack.toJsonObj()
        local jsonObj = {}
        jsonObj.data = stack.data
        jsonObj.last = stack.last
        return jsonObj
    end

    return stack
end

return stackBuilder