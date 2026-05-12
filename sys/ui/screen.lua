local Class = require("sys.class")

local Screen = Class.create()

function Screen:init(target)
    self.target = target or term.current()
end

function Screen:clear(background, foreground)
    self.target.setBackgroundColor(background or colors.black)
    self.target.setTextColor(foreground or colors.white)
    self.target.clear()
    self.target.setCursorPos(1, 1)
end

function Screen:size()
    return self.target.getSize()
end

function Screen:setColor(foreground, background)
    if background then
        self.target.setBackgroundColor(background)
    end

    if foreground then
        self.target.setTextColor(foreground)
    end
end

function Screen:write(text, foreground, background)
    self:setColor(foreground, background)
    self.target.write(tostring(text))
end

function Screen:writeLine(text, foreground, background)
    self:setColor(foreground, background)
    print(tostring(text or ""))
end

function Screen:writeAt(x, y, text, foreground, background)
    self:setColor(foreground, background)
    self.target.setCursorPos(x, y)
    self.target.write(tostring(text))
end

function Screen:centerText(y, text, foreground, background)
    local width = self.target.getSize()
    local value = tostring(text)
    local x = math.floor((width - #value) / 2) + 1

    if x < 1 then
        x = 1
    end

    self:writeAt(x, y, value, foreground, background)
end

function Screen:horizontalLine(y, char, foreground, background)
    local width = self.target.getSize()
    self:writeAt(1, y, string.rep(char or "-", width), foreground, background)
end

function Screen:pause(message)
    self:writeLine("")
    self:writeLine(message or "Press any key to continue...", colors.gray)
    os.pullEvent("key")
end

return Screen
