local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local arrayListBuilder = require(settings.get("require.api_path") .. "utils.array-list")

local kFramework = {}

kFramework.utils = {}
kFramework.utils.mouse_button = {}
kFramework.utils.mouse_button.left = 1
kFramework.utils.mouse_button.right = 2
kFramework.utils.mouse_button.middle = 3

local function _createKAtom(nMinX, nMinY, nMaxX, nMaxY)
    local _kAtom = {}
    _kAtom.tWindow = nil

    --constraints
    _kAtom.nMinX = nMinX or 1
    _kAtom.nMinY = nMinY or 1
    _kAtom.nMaxX = nMaxX or 162
    _kAtom.nMaxY = nMaxY or 80

    --flags
    _kAtom.isClickThrough = true -- TODO?
    _kAtom.needsRedrawn = true

    --events
    _kAtom.eventMatrix = {}
    _kAtom.eventHandler = {}
    function _kAtom.consumeEvent(event, ...)

    end

    function _kAtom.draw(tWindow)
        _kAtom.tWindow = tWindow

    end

    return _kAtom
end

--TODO rewrite node and frame to use a hidden _kAtom and only expose functions that manipulate it correctly

function kFramework.newKNode(nMinX, nMinY, nMaxX, nMaxY)
    --no children, but you can draw your contents freely
    local kNode = {}
    local _kNode = {}

    --visable so node can be drawn on (since it cannot contain children)
    --initally nil until added to a parent kFrame 
    _kNode.tWindow = nil 
    function kNode.getTWindow() return _kNode.tWindow end
    function kNode.setTWindow(tWindow) _kNode.tWindow = tWindow end --use with caution

    --constraints
    kNode.nMinX = nMinX or 1
    kNode.nMinY = nMinY or 1
    kNode.nMaxX = nMaxX or 162
    kNode.nMaxY = nMaxY or 80

    --flags
    _kNode.isClickThrough = true
    kNode.needsRedrawn = true

    --event handling and clickMatrix
    function kNode.isClickThrough()
        return _kNode.isClickThrough
    end
    function kNode.setClickThrough(isClickThrough)
        _kNode.isClickThrough = isClickThrough
        if isClickThrough then
            --generate click matrix
            
            kNode.generateClickMatrix()
        else
            _kNode.clickMatrix = nil
        end
    end
    
    _kNode.clickMatrix = {}
    function kNode.generateClickMatrix(nXLength, nYLength)
        --implemented by classes that extend like kFrame 
        --for this implementation it will remain blank
        --because nodes dont have children which means we cant have a dynamic clickMatrix
        --just applyClickHandler and clearClickHandler as needed, overwrite this function
        --if you want your node to change click behavior on redraw
    end
    function kNode.clearClickHandler(nXLength, nYLength)
        --this just creates a null framework
        for x = 1, nXLength, 1 do
            _kNode.clickMatrix[x] = {}
        end
    end
    function kNode.applyClickHandler(clickHandler, nX, nY, nXLength, nYLength)
        for x = nX, nXLength, 1 do
            for y = nY, nYLength, 1 do
                _kNode.clickMatrix[x][y] = clickHandler
            end
        end
    end
    --you can overwrite this function to create a single click handler for your entire node
    function kNode.click(nX, nY, button)
        if _kNode.isClickThrough and _kNode.clickMatrix 
        and _kNode.clickMatrix[nX] and _kNode.clickMatrix[nX][nY] then
            _kNode.clickMatrix[nX][nY](nX, nY, button)
        end
    end

    function kNode.draw(tWindow)
        if not tWindow and not kNode.getTWindow() then
            --cant draw
            return
        elseif not tWindow then
            --force redraw on the same window
            tWindow = kNode.getTWindow()
            kNode.needsRedrawn = true
        elseif not kNode.getTWindow() then
            --has not been drawn yet
            kNode.needsRedrawn = true
        end
        
        if kNode.needsRedrawn then
            kNode.setTWindow(tWindow)
            kNode._drawContents(tWindow)
            kNode.generateClickMatrix(tWindow.getSize())
            kNode.needsRedrawn = false
        end
    end

    function kNode._drawContents(tWindow)
        --implement drawing text and colors to window
        --this should be overwritten by classes that inherit 
    end

    return kNode
end

function kFramework.newKFrame(nMinX, nMinY, nMaxX, nMaxY)
    local kFrame = kFramework.newKNode(nMinX, nMinY, nMaxX, nMaxY)
    local _kFrame = {} --hidden

    --make tWindow not visable for this class, but maintain the ability for the underlying node to access it. 
    _kFrame.getTWindow = kFrame.getTWindow
    --kFrame.getTWindow = nil --hide visability TODO FIX
    _kFrame.setTWindow = kFrame.setTWindow --allows us to edit the underlying node window
    --kFrame.setTWindow = nil --hide since we wont want containers drawing, use a node for that

    _kFrame.applyClickHandler = kFrame.applyClickHandler
    kFrame.applyClickHandler = nil --hide visability to maintain data
    _kFrame.clearClickHandler = kFrame.clearClickHandler
    kFrame.clearClickHandler = nil
    function kFrame.generateClickMatrix(nXLength, nYLength)
        --do this once size is set
        _kFrame.clearClickHandler(nXLength, nYLength)
        for i = 1, kFrame.children.length, 1 do
            local child = kFrame.children.get(i)
            _kFrame.applyClickHandler(function (nx,ny,mouse) child.kNode.click(child.resolveCoordinates(nx,ny, mouse))  end, child.nX, child.nY, child.nXLength, child.nYLength)
        end
    end

    --children
    kFrame.children = arrayListBuilder.new()
    function _kFrame.newChild(childKNode,nX,nY,nXLength, nYLength)
        local child = {}
        child.kNode = childKNode
        child.nX = nX
        child.nY = nY
        child.nXLength = nXLength
        child.nYLength = nYLength
        function child.resolveCoordinates(nXFromEvent,nYFromEvent,mouseFromEvent)
            return nXFromEvent-(child.nX-1), nYFromEvent-(child.nY-1), mouseFromEvent
        end
        return child
    end
    function kFrame.add(childKNode, nX,nY,nXLength,nYLength)
        kFrame.children.append(_kFrame.newChild(childKNode, nX,nY,nXLength,nYLength))
    end

    function kFrame.insert(index,childKNode, nX,nY,nXLength,nYLength)
        kFrame.children.insert(index, _kFrame.newChild(childKNode, nX,nY,nXLength,nYLength))
    end

    --TODO remove child 

    function kFrame._drawContents(tWindow)
        --implement drawing text and colors to window
        --also implement creating a clickMatrix
        for i = 1, kFrame.children.length, 1 do
            local child = kFrame.children.get(i)
            --TODO determine if resize is needed
            child.kNode.draw(window.create(tWindow, child.nX, child.nY, child.nXLength, child.nYLength))
        end
    end

    function kFrame.resize(tWindow)
        local nXLength, nYLength = tWindow.getSize()
        _kFrame.tWindow = tWindow

    end

    return kFrame
end

function kFramework.newKApp(rootTerm, nMinX, nMinY, nMaxX,nMaxY)
    --extends KFrame
    --handles general event handling
    local kApp = kFramework.newKFrame(nMinX, nMinY, nMaxX,nMaxY)

    kApp.draw(rootTerm)

    kApp.eventHandler = {}

    function kApp.eventHandler.alarm(alarmID)
        --sub
    end
    function kApp.eventHandler.char(letter_string)
        --my_window.setCursorPos(1,1)
        --my_window.write(letter_string)
        --my_window.setCursorPos(1,1)
    end
    function kApp.eventHandler.computer_command(args)
        --sub
    end
    function kApp.eventHandler.disk(side_string)
        --sub
    end
    function kApp.eventHandler.disk_eject(side_string)
        --sub
    end
    function kApp.eventHandler.file_transfer(files)
        --sub
    end
    function kApp.eventHandler.http_check(url_string, success, error_string)
        --sub
    end
    function kApp.eventHandler.http_failure(url_string, error_string, response)
        --sub
    end
    function kApp.eventHandler.http_success(url_string, resonse)
        --sub
    end
    function kApp.eventHandler.key(keycode, isHeld)
        --pass through
        --my_window.return_desired_colors()
        --if isHeld then
        --    print(keys.getName(keycode) ..  "is held")
        --else
        --    print(keys.getName(keycode) .. "is clicked")
        --end
    end
    function kApp.eventHandler.key_up(keycode)
        --pass through
    end
    function kApp.eventHandler.modem_message(side_string, inChannel, replyChannel, message, distance)
        --sub
    end
    function kApp.eventHandler.monitor_resize(monitorID_string)
        --pass through?
    end
    function kApp.eventHandler.monitor_touch(monitorID_string, x_num, y_num)
        --pass through
    end
    function kApp.eventHandler.mouse_click(mouse_button_num, x_num, y_num)
        --pass through
        kApp.click(x_num, y_num, mouse_button_num)
    end
    function kApp.eventHandler.mouse_drag(mouse_button_num, x_num, y_num)
        --passthrough
    end
    function kApp.eventHandler.mouse_scroll(direction_num, x_num, y_num)
        --pass through
        --my_window.return_desired_colors()
        --my_window.scroll(direction_num)
    end
    function kApp.eventHandler.mouse_up(mouse_button_num, x_num, y_num)
        --pass through
    end
    function kApp.eventHandler.paste(clipboard_string)
        --pass through
    end
    function kApp.eventHandler.peripheral(side_string)
        --sub
    end
    function kApp.eventHandler.peripheral_detach(side_string)
        --sub
    end
    function kApp.eventHandler.rednet_message(senderID, message, protocol)
        --sub
    end
    function kApp.eventHandler.redstone()
        --sub
    end
    function kApp.eventHandler.speaker_audio_empty(speaker_name)
        --sub
    end
    function kApp.eventHandler.task_complete(taskID, success, error_string, task_table)
        --sub
    end
    function kApp.eventHandler.term_resize()
        --pass through?
    end
    function kApp.eventHandler.terminate()
        --sub
    end
    function kApp.eventHandler.timer(timerID)
        --sub
    end
    function kApp.eventHandler.turtle_inventory()
        --sub
    end
    function kApp.eventHandler.websocket_closed(url_string)
        --sub
    end
    function kApp.eventHandler.websocket_failure(url_string, error_string)
        --sub
    end
    function kApp.eventHandler.websocket_message(url_string, contents_string, isBinary)
        --sub
    end
    function kApp.eventHandler.websocket_success(url_string, handle)
        --sub
    end

    function kApp.run()
        kApp.draw()
        local exitProgram = false
        while not exitProgram do
            local event, param1, param2, param3, param4, param5 = os.pullEvent()
            
            local event_funct = kApp.eventHandler[event]
            if(event_funct) then
                event_funct(param1,param2,param3,param4,param5)
            else
                --report error?
            end
            
        end
    end


    return kApp
end

return kFramework