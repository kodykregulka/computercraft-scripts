--term.setCursorBlink(false)
--term.clear()

--for i = 1, 10, 1 do
--    term.setCursorPos(1,i)
--    term.write("hello world")

--end

local buttonBuilder = {}
function buttonBuilder.create(parent, x,y,text,text_color,fill_color,pressed_text_color, pressed_fill_color)

    local button = {}
    button.parent=parent
    button.x=x
    button.y=y
    button.text=text
    button.text_color=text_color
    button.fill_color=fill_color
    button.pressed_text_color = pressed_text_color
    button.pressed_fill_color = pressed_fill_color
    button.isPressed = false
    button.isVisible = false
    
    function button.clicked()
        button.isPressed = true
        button.draw()
    end
    function button.released()
        button.isPressed = false
        button.draw()
    end
    function button.setVisible(isVisible)
        button.isVisible = isVisible
        button.draw()
    end

    function button.draw()
        if(not button.isVisible) then
            parent.return_desired_colors()
            parent.setCursorPos(button.x,button.y)
            parent.write(string.rep(" ", #button.text))
        elseif(button.isPressed) then
            parent.setBackgroundColor(button.pressed_fill_color)
            parent.setTextColor(button.pressed_text_color)
            parent.setCursorPos(button.x, button.y)
            parent.write(button.text)
        else
            parent.setBackgroundColor(button.fill_color)
            parent.setTextColor(button.text_color)
            parent.setCursorPos(button.x, button.y)
            parent.write(button.text)
        end
    end

    button.setVisible(true)
    return button
end

local background_color = colors.black
local text_color = colors.white

local nXWidth, nYHeight = term.current().getSize()

local root_window = window.create(term.current(), 1, 1, nXWidth, nYHeight)
term.redirect(root_window)
print("hey")
root_window.setCursorBlink(false)
root_window.setBackgroundColor(background_color)
root_window.setTextColor(text_color)
local my_window = window.create(root_window, 8, 1, nXWidth-8, nYHeight)
--print("Writing some long text which will wrap around and show the bounds of this window.")

--create button
my_window.desired_background_color = colors.gray
my_window.desired_text_color = text_color
function my_window.return_desired_colors()
    my_window.setBackgroundColor(my_window.desired_background_color)
    my_window.setTextColor(my_window.desired_text_color)
end
local myButton = buttonBuilder.create(my_window, 3,2,"Button", colors.white, colors.blue, colors.lightGray, colors.gray)




local kframe = {}

local event_handler = {}

function event_handler.alarm(alarmID)
    --sub
end
function event_handler.char(letter_string)
    --my_window.setCursorPos(1,1)
    --my_window.write(letter_string)
    --my_window.setCursorPos(1,1)
end
function event_handler.computer_command(args)
    --sub
end
function event_handler.disk(side_string)
    --sub
end
function event_handler.disk_eject(side_string)
    --sub
end
function event_handler.file_transfer(files)
    --sub
end
function event_handler.http_check(url_string, success, error_string)
    --sub
end
function event_handler.http_failure(url_string, error_string, response)
    --sub
end
function event_handler.http_success(url_string, resonse)
    --sub
end
function event_handler.key(keycode, isHeld)
    --pass through
    my_window.return_desired_colors()
    if isHeld then
        print(keys.getName(keycode) ..  "is held")
    else
        print(keys.getName(keycode) .. "is clicked")
    end
end
function event_handler.key_up(keycode)
    --pass through
end
function event_handler.modem_message(side_string, inChannel, replyChannel, message, distance)
    --sub
end
function event_handler.monitor_resize(monitorID_string)
    --pass through?
end
function event_handler.monitor_touch(monitorID_string, x_num, y_num)
    --pass through
end
function event_handler.mouse_click(mouse_button_num, x_num, y_num)
    --pass through
    if mouse_button_num == 1 then
        --left click
        print("x:" .. x_num .. " y:" .. y_num)
        if(x_num==3 and y_num==2) then
            myButton.clicked()
        end
    elseif mouse_button_num == 2 then
        --right click
        term.setCursorPos(1,1)
    else
        --middle click
    end
end
function event_handler.mouse_drag(mouse_button_num, x_num, y_num)
    --passthrough
end
function event_handler.mouse_scroll(direction_num, x_num, y_num)
    --pass through
    my_window.return_desired_colors()
    my_window.scroll(direction_num)
end
function event_handler.mouse_up(mouse_button_num, x_num, y_num)
    --pass through
    myButton.released()
end
function event_handler.paste(clipboard_string)
    --pass through
end
function event_handler.peripheral(side_string)
    --sub
end
function event_handler.peripheral_detach(side_string)
    --sub
end
function event_handler.rednet_message(senderID, message, protocol)
    --sub
end
function event_handler.redstone()
    --sub
end
function event_handler.speaker_audio_empty(speaker_name)
    --sub
end
function event_handler.task_complete(taskID, success, error_string, task_table)
    --sub
end
function event_handler.term_resize()
    --pass through?
end
function event_handler.terminate()
    --sub
end
function event_handler.timer(timerID)
    --sub
end
function event_handler.turtle_inventory()
    --sub
end
function event_handler.websocket_closed(url_string)
    --sub
end
function event_handler.websocket_failure(url_string, error_string)
    --sub
end
function event_handler.websocket_message(url_string, contents_string, isBinary)
    --sub
end
function event_handler.websocket_success(url_string, handle)
    --sub
end

local exitProgram = false
while not exitProgram do
    local event, param1, param2, param3, param4, param5 = os.pullEvent()
    
    local event_funct = event_handler[event]
    if(event_funct) then
        event_funct(param1,param2,param3,param4,param5)
    else
        --report error?
    end
    
end




