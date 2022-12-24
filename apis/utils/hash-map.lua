local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local hashMapBuilder = {}

function hashMapBuilder.new()
    local hashMap = {}
    hashMap._data = {}
    hashMap._size = 0
    function hashMap.getSize()
        return hashMap._size
    end

    function hashMap.insert(key, value)
        if(key == nil or value == nil)then error("cannot insert nil into hashmap")end
        if(hashMap._data[key])then
            --overwrite
            hashMap._data[key] = value
        else
            --new entry
            hashMap._data[key] = value
            hashMap._size = hashMap._size + 1
        end
    end

    function hashMap.remove(key)
        if(key == nil)then error("key cannot be nil")end
        if(hashMap._data[key]) then
            hashMap._data[key] = nil
            hashMap._size = hashMap._size - 1
        else
            --nothing to remove
        end
    end

    function hashMap.get(key)
        return hashMap._data[key]
    end

    return hashMap
end

return hashMapBuilder