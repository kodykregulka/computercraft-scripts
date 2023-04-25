local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local arrayListBuilder = {}

function arrayListBuilder.new()
    local list = {}
    list.length = 0
    list.members = {}

    function list.append(obj)
        if(not obj) then error("expected nonnull object", 2) end
        list.length = list.length + 1
        list.members[list.length] = obj
    end
    function list.appendAll(...)
        for i =1, #args, 1 do
            list.append(args[i])
        end
    end

    function list.get(index)
        return list.members[index]
    end

    function list.write(index, obj)
        expect(1, index, "number")
        if(not obj) then error("expected nonnull object", 2) end
        if(index > 0 or index <= list.length) then
            list.members[index] = obj
        else
            error("index out of bounds", 2)
        end
    end

    function list.insert(index, obj)
        expect(1, index, "number")
        expect(2, obj, "any")
        if(index > 0 or index <= list.length+1) then
            local target = list.members[index]
            list.members[index] = obj
            if(target) then
                list.insert(index+1, target)
            else
                list.length = list.length + 1
            end
        else
            error("index out of bounds", 2)
        end
    end

    function list.insertAll(index, ...)
        expect(1, index, "number")
        expect(2, args, "table")
        if(index > 0 or index <= list.length+1) then
            --get tail list
            local tailList
            if(index < list.length+1) then
                tailList = {table.unpack(list.members, index)}
            end
            --append new list
            for i = 1, #args, 1 do
                list.members[index + i -1] = args[i]
            end

            --append tail list
            for i = 1, #tailList, 1 do
                list.members[index+#args+i-1] = tailList[i]
            end

            list.length = list.length + #args
        else
            error("index out of bounds", 2)
        end
    end

    function list.remove(index)
        expect(1, index, "number")
        if(index > 0 or index <= list.length) then
            list.members[index] = nil
            if(index < list.length) then
                for i = index, list.length-1, 1 do
                    list.members[index] = list.members[index+1]
                end
            end
            list.members[list.length] = nil
            list.length = list.length - 1
        else
            error("index out of bounds", 2)
        end
    end

    return list
end
return arrayListBuilder