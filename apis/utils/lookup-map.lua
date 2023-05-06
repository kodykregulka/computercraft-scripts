local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local lookupMapBuilder = {}

function lookupMapBuilder.new()
    local lookupMap = {}
    lookupMap._keyTable = {}
    lookupMap._valTable = {}
    lookupMap._size = 0

    function lookupMap.size()
        return lookupMap._size
    end

    local function checkType(obj)
        if(obj == nil) then
            error("lookup obj cannot be null", 3)
        end
        local oType = type(obj)
        if( not (oType == "string" or oType == "number")) then
            error("lookup obj must be a string or number", 3)
        end
    end

    function lookupMap.insert(key, val)
        checkType(key)
        checkType(val)
        
        if(lookupMap._keyTable[key]) then
            lookupMap.removeByKey(key)
        end
        if(lookupMap._valTable[val]) then
            lookupMap.removeByVal(val)
        end

        lookupMap._keyTable[key] = val
        lookupMap._valTable[val] = key
        lookupMap._size = lookupMap._size + 1
    end

    function lookupMap.removeByKey(key)
        checkType(key)
        
        local val = lookupMap._keyTable[key]
        lookupMap._valTable[val] = nil
        lookupMap._keyTable[val] = nil
        lookupMap._size = lookupMap._size - 1
    end
    function lookupMap.removeByVal(val)
        checkType(val)

        local key = lookupMap._valTable[val]
        lookupMap._keyTable[key] = nil
        lookupMap._valTable[val] = nil
        lookupMap._size = lookupMap._size - 1
    end

    function lookupMap.getValByKey(key)
        return lookupMap._keyTable[key]
    end
    function lookupMap.getKeyByVal(val)
        return lookupMap._valTable[val]
    end

    return lookupMap
end

function lookupMapBuilder.newFromMap(inputMap)
    local lookupMap = lookupMapBuilder.new()
    for k,v in pairs(inputMap) do
        lookupMap.insert(k,v)
    end
    return lookupMap
end

return lookupMapBuilder