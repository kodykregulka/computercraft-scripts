local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local arrayListBuilder = require(settings.get("require.api_path") .. "utils.array-list")

local kFramework = {}

kFramework.utils = {}
kFramework.utils.mouse_button = {}
kFramework.utils.mouse_button.left = 1
kFramework.utils.mouse_button.right = 2
kFramework.utils.mouse_button.middle = 3

--node
--is handed a window to draw within, must implement a draw method
--it can specifiy max and min draw space, but it may not get it
function kFramework.newKNode(data) --args?
    local kNode = {}
    local _kNode = {}

    if(type(data) == "string") then
        data = textutils.serializeJSON(data)
    end
    _kNode.data = data

    --implement functions
    function kNode.handleEvent(event)
        --implement
    end
    function kNode.redraw(parent, window)
        --implement
    end
    function kNode.draw()
        --implement
    end


    --fields
    _kNode.window = {}
    kNode.window = {}
    _kNode.window.nMinX = nMinX or 1
    function kAtom.window.getNMinX() return _kNode.window.nMinX end
    function kAtom.window.setNMinX(nMinX) _kNode.window.nMinx= nMinX end
    _kNode.window.nMinY = nMinY or 1
    function kAtom.window.getNMinY() return _kNode.window.nMinY end
    function kAtom.window.setNMinY(nMinY) _kNode.window.nMinY=nMinY end
    _kNode.window.nMaxX = nMaxX or 162
    function kAtom.window.getNMaxX() return _kNode.window.nMaxX end
    function kAtom.window.setNMaxX(nMaxX) _kNode.window.nMaxX=nMaxX end
    _kNode.window.nMaxY = nMaxY or 80
    function kAtom.window.getNMaxY() return _kNode.window.nMaxY end
    function kAtom.window.setNMaxY(nMaxY) _kNode.nMaxY=nMaxY end


    return kNode, data
end

function kFramework.newLabel(data)
    local label, data = kFramework.newKNode(data)

    


    return label
end








--frames contain nodes
--frames provide drawing space for the node's draw function
--will manage a pixelMatrix that is used for passing through events and redraws
--this base kFramework will just do whatever you tell it and overwrite previous children without question nor checking
function kFramework.newKFrame() --args?
    local kFrame = kFramework.newKNode()
    local _kFrame = {}

    _kFrame.window = {}
    _kFrame.window.pixelMatrix = {}


    function kFrame.addChild(child, nX, nY)
        
    end

    function kFrame.removeChild()

    end

    return kFrame
end

return kFramework