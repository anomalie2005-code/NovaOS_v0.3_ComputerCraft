local SettingsView = {}

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

function SettingsView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:draw(items, selected, message)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local List = ctx.ui.List
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        Box.draw(ctx, boxX, boxY, boxW, boxH, "Settings")

        if message and message ~= "" then
            Box.writeInside(ctx, boxX, boxY, boxW, 2, message, theme.success)
        else
            Box.writeInside(ctx, boxX, boxY, boxW, 2, "Use arrows, Enter, mouse click, or wheel.", theme.muted)
        end

        Box.drawSeparator(ctx, boxX, boxY + 4, boxW)

        local listX = boxX + 2
        local listY = boxY + 5
        local listW = boxW - 4
        local listH = boxH - 10

        if listH < 1 then
            listH = 1
        end

        selected = List.clamp(selected, #items)

        local scroll = List.getScroll(selected, listH, #items)

        List.draw(ctx, {
            x = listX,
            y = listY,
            width = listW,
            height = listH,
            items = items,
            selected = selected,
            scroll = scroll,
            emptyText = "(no settings)"
        })

        local selectedItem = items[selected]

        if selectedItem and selectedItem.hint then
            Box.writeInside(ctx, boxX, boxY, boxW, boxH - 4, "Hint: " .. selectedItem.hint, theme.muted)
        end

        Box.footer(ctx, boxX, boxY, boxW, boxH, "Enter/click: edit/toggle   Wheel: move   Q/right click: quit")
        StatusBar.drawBottom(ctx, "NovaOS / Settings", "theme: " .. tostring(ctx.config.theme))

        return {
            listX = listX,
            listY = listY,
            listW = listW,
            listH = listH,
            scroll = scroll
        }
    end

    function self:promptText(title, currentValue)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box
        local input = tostring(currentValue or "")

        while true do
            ctx.screen:clear(theme.background, theme.text)

            local width, height = term.getSize()
            local boxW = math.min(width - 4, 52)
            local boxH = 11
            local boxX = math.floor((width - boxW) / 2) + 1
            local boxY = math.floor((height - boxH) / 2) + 1

            Box.draw(ctx, boxX, boxY, boxW, boxH, title)
            Box.writeInside(ctx, boxX, boxY, boxW, 2, "Current: " .. tostring(currentValue or ""), theme.foreground)
            Box.writeInside(ctx, boxX, boxY, boxW, 4, "New value:", theme.accent2)

            term.setCursorPos(boxX + 2, boxY + 6)
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)

            local fieldWidth = boxW - 4
            local visibleInput = cutText(input, fieldWidth - 2)

            term.write("> " .. padRight(visibleInput, fieldWidth - 2))

            Box.footer(ctx, boxX, boxY, boxW, boxH, "Enter: save   Empty Enter/Esc/right click: cancel")

            term.setCursorPos(boxX + 4 + #visibleInput, boxY + 6)
            term.setCursorBlink(true)

            local event, a = os.pullEvent()

            if event == "char" then
                input = input .. tostring(a)
            elseif event == "paste" then
                input = input .. tostring(a)
            elseif event == "key" then
                local key = a

                if key == keys.enter then
                    term.setCursorBlink(false)

                    if input == "" then
                        return currentValue
                    end

                    return input
                elseif key == keys.backspace then
                    input = string.sub(input, 1, #input - 1)
                elseif key == keys.escape or key == keys.f10 then
                    term.setCursorBlink(false)
                    return currentValue
                end
            elseif event == "mouse_click" then
                local button = a

                if button ~= 1 then
                    term.setCursorBlink(false)
                    return currentValue
                end
            end
        end
    end

    return self
end

return SettingsView