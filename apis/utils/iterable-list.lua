local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local iListBuilder = {}

function iListBuilder.new(name)
    local list = {}
    list.name = name
    list.length = 0
    list.lastIndex = 0 -- when searching, this is the last value that was searched
    list.members = {}

    function list.add(obj)
        if(obj)
        then
            list.length = list.length + 1
            list.members[list.length] = obj
            list.lastIndex = list.length
        else
            error("cannot add nil to list", 2)
        end
    end

    function list.get(index)
        return list.members[index]
    end

    function list.nextIndex()
        if(list.length == 0)
        then
            list.lastIndex = 0
            return 0
        elseif(list.lastIndex == list.length)
        then
            list.lastIndex = 1
            return list.lastIndex
        else
            list.lastIndex = list.lastIndex + 1
            return list.lastIndex
        end
    end

    function list.print()
        print("name: " .. list.name)
        print("length: " .. list.length)
        print("lastIndex: " .. list.lastIndex)
    end

    return list
end
return iListBuilder