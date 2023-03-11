local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local kframeBuilder = {}

function kframeBuilder.newRoot()


end

function kframeBuilder.new(parentKFrame, nX, nY, nWidth, nHeight, isVisible)
    --parent contols movement and resizing of children
    --create a clickMatrix that keeps track of which window owns each pixel
    --might want to stick most of this in a hiden object and only give access through functions
    local kframe = {}
    kframe.parent = parentKFrame
    kframe.window = window.create(parentKFrame.window,nX, nY, nWidth, nHeight, isVisible)
    kframe.nX = nX
    kframe.nY = nY
    kframe.nWidth = nWidth
    kframe.nHeight = nHeight

    kframe.clickMap = {}
    function kframe.clearClickMap()
        kframe.clickMap = {}
        for col = 1, nWidth, 1 do
            kframe.clickMap[col] = {}
            for row = 1, nHeight, 1 do
                kframe.clickMap[col][row] = nil
            end
        end
    end
    kframe.clearClickMap()
    function kframe.addToClickMap(k_element, nX, nY, nWidth, nHeight)
        for col = 1, nWidth, 1 do
            if(col >= nX and col <= (nX+nWidth)) then
                for row = 1, nHeight, 1 do
                    if(row >= nY and row <= (nY+nHeight)) then
                        kframe.clickMap[col][row] = k_element
                    end
                end
            end
        end
    end

    kframe.children = {}


    function kframe.addChildren(...)
        for i,v in ipairs(arg) do
            --kframe.children
            --kframe.children
            --need a draw order like a stack, then we can generate the click map
            kframe.addToClickMap(v,) -- more
        end
    end


    return kframe
end