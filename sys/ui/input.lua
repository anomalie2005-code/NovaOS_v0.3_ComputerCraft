local Input = {}

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

    return string.sub(text, #text - maxLength + 4)
end

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
end

local function insertAt(text, position, value)
    text = tostring(text or "")
    value = tostring(value or "")

    return string.sub(text, 1, position - 1) .. value .. string.sub(text, position)
end

local function removeBefore(text, position)
    text = tostring(text or "")

    if position <= 1 then
        return text, position
    end

    local result = string.sub(text, 1, position - 2) .. string.sub(text, position)

    return result, position - 1
end

local function removeAt(text, position)
    text = tostring(text or "")

    if position > #text then
        return text
    end

    return string.sub(text, 1, position - 1) .. string.sub(text, position + 1)
end

function Input.prompt(ctx, options)
    options = options or {}

    local title = options.title or "Input"
    local label = options.label or "Value:"
    local placeholder = options.placeholder or ""
    local value = tostring(options.value or "")
    local allowEmpty = options.allowEmpty == true

    local cursor = #value + 1

    while true do
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, options.width or 58)
        local boxH = options.height or 12
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, title)
        Box.writeInside(ctx, boxX, boxY, boxW, 2, label, theme.foreground)

        if placeholder ~= "" then
            Box.writeInside(ctx, boxX, boxY, boxW, 3, placeholder, theme.muted)
        end

        local fieldX = boxX + 2
        local fieldY = boxY + 6
        local fieldW = boxW - 4

        local visibleValue = cutText(value, fieldW - 2)

        term.setCursorPos(fieldX, fieldY)
        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
        term.write("> " .. padRight(visibleValue, fieldW - 2))

        Box.footer(ctx, boxX, boxY, boxW, boxH, "Enter: confirm   Esc/F10/right click: cancel")

        local visibleCursor = cursor

        if visibleCursor > fieldW - 1 then
            visibleCursor = fieldW - 1
        end

        term.setCursorPos(fieldX + 1 + visibleCursor, fieldY)
        term.setCursorBlink(true)

        local event, a, b, c = os.pullEvent()

        if event == "char" then
            value = insertAt(value, cursor, a)
            cursor = cursor + #a
        elseif event == "paste" then
            value = insertAt(value, cursor, a)
            cursor = cursor + #a
        elseif event == "key" then
            local key = a

            if key == keys.enter then
                term.setCursorBlink(false)

                if value == "" and not allowEmpty then
                    return nil
                end

                return value
            elseif key == keys.backspace then
                value, cursor = removeBefore(value, cursor)
            elseif key == keys.delete then
                value = removeAt(value, cursor)
            elseif key == keys.left then
                cursor = math.max(1, cursor - 1)
            elseif key == keys.right then
                cursor = math.min(#value + 1, cursor + 1)
            elseif key == keys.home then
                cursor = 1
            elseif key == keys["end"] then
                cursor = #value + 1
            elseif key == keys.escape or key == keys.f10 then
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

return Input
