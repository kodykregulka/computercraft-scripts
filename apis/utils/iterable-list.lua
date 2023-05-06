local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local iListBuilder = {}

function iListBuilder.new(name)
    local list = {}
    list.name = name
    list._max_length = 0
    list._size = 0
    list.currentIndex = 0 -- when searching, this is the last value that was searched
    list._members = {}

    function list.add(obj)
        if(obj)
        then
            list._size = list._size + 1
            list._max_length = list._max_length + 1
            list._members[list._max_length] = obj
            list.currentIndex = list._max_length
            return list.currentIndex
        else
            error("cannot add nil to list", 2)
        end
    end

    function list.update(index, updatedObj)
        if(index < 1 or index > list._max_length) then
            error("index below acceptable value", 2)
        elseif(list._members[index]) then
            --update this record
            list._members[index] = updatedObj
        else
            --filling in a hole, dont increase max length
            list._members[index] = updatedObj
            list._size = list._size + 1
        end
    end

    function list.remove(index)
        if(list._members[index]) then
            list._size = list._size - 1
            list._members[index] = nil
        end
    end

    function list.get(index)
        return list._members[index]
    end

    function list.nextIndex()
        if(list._max_length == 0 or list._size == 0)
        then
            list.currentIndex = 0
            return 0
        elseif(list.currentIndex == list._max_length)
        then
            list.currentIndex = 1
        else
            list.currentIndex = list.currentIndex + 1
        end
        if(list._members[list.currentIndex]) then
            return list.currentIndex
        else
            return list.nextIndex()
        end
    end

    function list.nextMember()
        local index = list.nextIndex()
        if(index == 0) then
            return nil
        else
            return list._members[index]
        end
    end

    function list.print()
        print("name: " .. list.name)
        print("length: " .. list._max_length)
        print("lastIndex: " .. list.currentIndex)
    end

    function list.toJsonObj()
        local jsonObj = {}
        jsonObj.name = list.name
        jsonObj._max_length = list._max_length
        jsonObj._size = list._size
        jsonObj.currentIndex = list.currentIndex
        jsonObj._members = list._members
        return jsonObj
    end

    return list
end

function iListBuilder.fromJsonObj(jsonObj)
    local list = iListBuilder.new(jsonObj.name)
    list.name = jsonObj.name
    list._max_length = jsonObj._max_length
    list._size = jsonObj._size
    list.currentIndex = jsonObj.currentIndex
    list._members = jsonObj._members
    return list
end

return iListBuilder