
peripheral.find("modem", rednet.open)

local protocol = "myproto"
local hosts = {rednet.lookup(protocol)}
local hostnames = {}
for k, v in pairs(hosts) do
  rednet.send(v, {sType = "lookup", sProtocol = protocol}, "dns")
  local id, data
  repeat
        id, data = rednet.receive("dns")
  until id == v and type(data) == "table" and data.sType and data.sType == "lookup response"
  hostnames[k] = data.sHostname
  print(hostnames[k])
end