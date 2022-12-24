local modem = peripheral.wrap("back")
modem.open(os.getComputerID())
--peripheral.call("right", "open", os.getComputerID())

print("Waiting for events")
local count = 1
while true do
    local event = {os.pullEvent()}
    if event[1] == "char" and event[2] == "g" then
        print(gps.locate(5, true))
    end 
    print("------------")
    print("<" .. count .. ">")
    count = count + 1
    for i = 1, #event, 1 do
        if type(event[i]) == "table" then
            print(i .. " " .. textutils.serialise(event[i]))
        else
            print(i .. " " .. tostring(event[i]))
        end
    end
    print("------------")
end

modem.close(os.getComputerID())