local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range


local queueBuilder = {}


function queueBuilder.new()
    local queue = {}
    queue.data = {}
    queue.first = 0
    queue.last = -1
    
    function queue.push(value)
        queue.last = queue.last + 1
        queue.data[queue.last] = value
    end

    function queue.peek()
        return queue.data[queue.first]
    end
    function queue.pop()
        if(queue.first > queue.last) then
            return nil
        else
            local value = queue.data[queue.first]
            queue.data[queue.first] = nil
            queue.first = queue.first + 1
            return value
        end
    end

    function queue.size()
        return queue.last - queue.first + 1
    end

    function queue.print()
        if(queue.first > queue.last) then
            return
        end
        for i = queue.first, queue.last, 1 do
            print(textutils.serialize(queue.data[i]))
        end
    end

    return queue
end

return queueBuilder