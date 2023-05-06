local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local pnetworkBuilder = require(settings.get("require.api_path") .. "peripheral.pnetwork")

local pnetwork = pnetworkBuilder.new()
local args = {...}
pnetwork.ui.launch(args[1])