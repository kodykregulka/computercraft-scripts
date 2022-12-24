local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local logBuilder = {}

function logBuilder.new(filename, appName, isPrint, isTime)
    local log = {}
    log._fileName = "/" .. shell.resolve(filename)
    log._file = fs.open(log._fileName, "a")

    local function writeStringWithDate(message, scope, lType)
        return os.date("%Y-%m-%d_%T [") .. (lType or "") .."]<" .. (appName or "") .. "." .. (scope or "") .. "> " .. message
    end
    local function writeStringWithoutDate(message, scope, lType)
        return "[" .. (lType or "") .."]<" .. (appName or "") .. "." .. (scope or "") .. "> " .. message
    end
    if(isTime)then
        log._writeString = writeStringWithDate
    else
        log._writeString = writeStringWithoutDate
    end

    local function writeWithPrint(message)
        print(message)
        log._file.write(message .. "\n")
    end
    local function writeWithoutPrint(message)
        log._file.write(message .. "\n")
    end
    if(isPrint)then
        log._write = writeWithPrint
    else
        log._write = writeWithoutPrint
    end

    function log.close()
        log._write(log._writeString("Closing log"))
        log._file.close()
    end
    function log.info(message, scope)
        log._write(log._writeString(message, scope, "INFO"))
    end
    function log.warning(message, scope)
        log._write(log._writeString(message, scope, "WARN"))
    end
    function log.error(message, scope, level)
        --this will crash program
        local message = log._writeString(message, scope, "ERROR")
        log._write(message)
        log.close() --since error() will end program
        error(message, level or 1)
    end

    return  log
end

return logBuilder