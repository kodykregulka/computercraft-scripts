

local kframework = require(settings.get("require.api_path") .. "gui.k-framework")

local kApp = kframework.newKApp(term.current())

local kFrame = kframework.newKFrame()

kApp.add(kFrame, 5, 5, 40, 10)

local kNode = kframework.newKNode()
function kNode._drawContents()
    local tWindow = kNode.getTWindow()
    tWindow.setBackgroundColor(colors.blue)
    tWindow.setTextColor(colors.white)
    tWindow.setCursorPos(1,1)
    tWindow.write("Button")
end
function kNode.click()
    local tWindow = kNode.getTWindow()
    tWindow.setBackgroundColor(colors.red)
    tWindow.setTextColor(colors.black)
    tWindow.setCursorPos(1,1)
    tWindow.write("pressed")
end
kFrame.add(kNode, 1,1,20,3)


kApp.run()