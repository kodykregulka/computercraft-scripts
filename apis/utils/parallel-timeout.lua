local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local function timeoutFunction(timeout)
    local timerID = os.startTimer(timeout.seconds)
    local event, id
    repeat
        event, id = os.pullEvent("timer")
    until id == timerID
    timeout.active = true
end

function parallel.waitForAllWithTimeout(seconds, ...)
    local timeout = {}
    timeout.seconds = seconds
    timeout.active = false
    local args = {...}
    parallel.waitForAny(function () timeoutFunction(timeout) end, function () parallel.waitForAll(table.unpack(args)) end)
    return timeout.active
end

function parallel.waitForAnyWithTimeout(seconds, ...)
    local timeout = {}
    timeout.seconds = seconds
    timeout.active = false
    parallel.waitForAny(function () timeoutFunction(timeout) end, ...)
    return timeout.active
end

return parallel