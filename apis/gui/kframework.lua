local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local arrayListBuilder = require(settings.get("require.api_path") .. "utils.array-list")

local kFramework = {}

kFramework.utils = {}
kFramework.utils.mouse_button = {}
kFramework.utils.mouse_button.left = 1
kFramework.utils.mouse_button.right = 2
kFramework.utils.mouse_button.middle = 3

local function _newKAtom(nMinX, nMinY, nMaxX, nMaxY)
    local kAtom = {}
    local _kAtom = {}

    
    _kAtom.window = {}
    _kAtom.window.tWindow = nil
    function kAtom.window.getTWindow() return _kAtom.tWindow end
    function kAtom.window.setTWindow(tWindow) _kAtom.tWindow=tWindow end

    --constraints
    kAtom.window = {}
    _kAtom.window = {}
    _kAtom.window.nMinX = nMinX or 1
    function kAtom.window.getNMinX() return _kAtom.window.nMinX end
    function kAtom.window.setNMinX(nMinX) _kAtom.window.nMinx= nMinX end
    _kAtom.window.nMinY = nMinY or 1
    function kAtom.window.getNMinY() return _kAtom.window.nMinY end
    function kAtom.window.setNMinY(nMinY) _kAtom.window.nMinY=nMinY end
    _kAtom.window.nMaxX = nMaxX or 162
    function kAtom.window.getNMaxX() return _kAtom.window.nMaxX end
    function kAtom.window.setNMaxX(nMaxX) _kAtom.window.nMaxX=nMaxX end
    _kAtom.window.nMaxY = nMaxY or 80
    function kAtom.window.getNMaxY() return _kAtom.window.nMaxY end
    function kAtom.window.setNMaxY(nMaxY) _kAtom.window.nMaxY=nMaxY end

    --flags
    --_kAtom.isClickThrough = true -- TODO?
    --_kAtom.needsRedrawn = true

    --events
    _kAtom.eventHandler = {}
    function kAtom.addEventHandler(sEvent, fHandler)
        _kAtom.eventHandler[sEvent] = fHandler
    end
    function kAtom.consumeEvent(sEvent, ...)
        _kAtom.eventHandler[sEvent](...)
    end

    function kAtom.draw(tWindow)
        _kAtom.tWindow = tWindow

    end

    return kAtom
end

local function newKNode(nMinX, nMinY, nMaxX, nMaxY)
    local kNode = {}
    local _kAtom = _newKAtom(nMinX, nMinY, nMaxX, nMaxY)
    kNode.constraints = _kAtom.window


end

local function newKFrame(parentKFrame, nMinX, nMinY, nMaxX, nMaxY)
    local kFrame = {}
    local _kFrame = {}
    local _kAtom = _newKAtom(nMinX, nMinY, nMaxX, nMaxY)

    kFrame.window = _kAtom.window


    function _kFrame.newChild(childKNode,nX,nY,nXLength, nYLength)
        local child = {}
        local _child = {}
        _child.kNode = childKNode
        local _tTempWindow = window.create() --need to give access to resize function to child and remove from childKNode tWindow

        
        _child.nX = nX
        function child.getNX() return _child.nX end
        _child.nY = nY
        function child.getNY() return _child.nY end
        _child.nXLength = nXLength
        function child.getNXLength() return _child.nXLength end
        _child.nYLength = nYLength
        function child.getNYLength() return _child.nYLength end
        function child.setDimensions(nX,nY,nXLength,nYLength)
            _child.nX = nX
            _child.nY = nY
            _child.nXLength = nXLength
            _child.nYLength = nYLength 
        end

        function child.resolveCoordinates(nXFromEvent,nYFromEvent,mouseFromEvent)
            return nXFromEvent-(_child.nX-1), nYFromEvent-(_child.nY-1), mouseFromEvent
        end



        return child
    end
end