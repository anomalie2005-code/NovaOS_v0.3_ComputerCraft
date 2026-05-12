local FileDialogs = {}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if maxLength <= 0 then
        return ""
    end

    if #text <= maxLength then
        return text
    end

    if maxLength <= 3 then
        return string.sub(text, 1, maxLength)
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
end

function FileDialogs.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:message(title, message, color)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 54)
        local boxH = 9
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, title or "Message")
        Box.writeInside(ctx, boxX, boxY, boxW, 3, cutText(message or "", boxW - 4), color or theme.foreground)
        Box.footer(ctx, boxX, boxY, boxW, boxH, "Press any key or click to continue")

        local event = os.pullEvent()

        while event ~= "key" and event ~= "mouse_click" do
            event = os.pullEvent()
        end
    end

    function self:confirm(title, message)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 58)
        local boxH = 10
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, title or "Confirm")
        Box.writeInside(ctx, boxX, boxY, boxW, 2, cutText(message or "", boxW - 4), theme.warning)
        Box.writeInside(ctx, boxX, boxY, boxW, 4, "This action may be irreversible.", theme.muted)
        Box.footer(ctx, boxX, boxY, boxW, boxH, "Y: confirm   any other key/right click: cancel")

        local event, a = os.pullEvent()

        if event == "key" and a == keys.y then
            return true
        end

        return false
    end

    function self:askText(title, label, placeholder, currentValue)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        local input = tostring(currentValue or "")
        local cursor = #input + 1

        while true do
            ctx.screen:clear(theme.background, theme.text)

            local width, height = term.getSize()
            local boxW = math.min(width - 4, 58)
            local boxH = 12
            local boxX = math.floor((width - boxW) / 2) + 1
            local boxY = math.floor((height - boxH) / 2) + 1

            Box.draw(ctx, boxX, boxY, boxW, boxH, title or "Input")
            Box.writeInside(ctx, boxX, boxY, boxW, 2, label or "Value:", theme.foreground)

            if placeholder and placeholder ~= "" then
                Box.writeInside(ctx, boxX, boxY, boxW, 3, placeholder, theme.muted)
            end

            local fieldX = boxX + 2
            local fieldY = boxY + 6
            local fieldW = boxW - 4

            local visibleInput = cutText(input, fieldW - 2)

            term.setCursorPos(fieldX, fieldY)
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)
            term.write("> " .. padRight(visibleInput, fieldW - 2))

            Box.footer(ctx, boxX, boxY, boxW, boxH, "Enter: confirm   Esc/F10/right click: cancel")

            local cursorX = fieldX + 1 + cursor

            if cursorX > fieldX + fieldW - 1 then
                cursorX = fieldX + fieldW - 1
            end

            term.setCursorPos(cursorX, fieldY)
            term.setCursorBlink(true)

            local event, a = os.pullEvent()

            if event == "char" then
                input = string.sub(input, 1, cursor - 1) .. tostring(a) .. string.sub(input, cursor)
                cursor = cursor + #tostring(a)
            elseif event == "paste" then
                input = string.sub(input, 1, cursor - 1) .. tostring(a) .. string.sub(input, cursor)
                cursor = cursor + #tostring(a)
            elseif event == "key" then
                if a == keys.enter then
                    term.setCursorBlink(false)

                    if input == "" then
                        return nil
                    end

                    return input
                elseif a == keys.backspace then
                    if cursor > 1 then
                        input = string.sub(input, 1, cursor - 2) .. string.sub(input, cursor)
                        cursor = cursor - 1
                    end
                elseif a == keys.delete then
                    if cursor <= #input then
                        input = string.sub(input, 1, cursor - 1) .. string.sub(input, cursor + 1)
                    end
                elseif a == keys.left then
                    cursor = math.max(1, cursor - 1)
                elseif a == keys.right then
                    cursor = math.min(#input + 1, cursor + 1)
                elseif a == keys.home then
                    cursor = 1
                elseif a == keys["end"] then
                    cursor = #input + 1
                elseif a == keys.escape or a == keys.f10 then
                    term.setCursorBlink(false)
                    return nil
                end
            elseif event == "mouse_click" then
                local button = a

                if button ~= 1 then
                    term.setCursorBlink(false)
                    return nil
                end
            end
        end
    end

    function self:askPath(title, label, placeholder, currentValue)
        return self:askText(title, label, placeholder, currentValue)
    end

    return self
end

return FileDialogs