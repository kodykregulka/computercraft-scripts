local expect = require "cc.expect"
local expect, field, range = expect.expect, expect.field, expect.range

local pnetwork = require(settings.get("require.api_path") .. "peripheral.pnetwork")

local args = {...}
pnetwork.ui.launch(shell.resolve(args[1]))