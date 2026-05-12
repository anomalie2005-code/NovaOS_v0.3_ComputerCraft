local List = {}

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

function List.move(selected, delta, count)
    if count <= 0 then
        return 1
    end

    selected = selected + delta

    if selected < 1 then
        selected = count
    elseif selected > count then
        selected = 1
    end

    return selected
end

function List.clamp(selected, count)
    if count <= 0 then
        return 1
    end

    if selected < 1 then
        return 1
    end

    if selected > count then
        return count
    end

    return selected
end

function List.getScroll(selected, visibleRows, count)
    if count <= visibleRows then
        return 1
    end

    local scroll = selected - visibleRows + 1

    if scroll < 1 then
        scroll = 1
    end

    if scroll > count - visibleRows + 1 then
        scroll = count - visibleRows + 1
    end

    return scroll
end

function List.hitTest(options, mouseX, mouseY)
    local x = options.x or 1
    local y = options.y or 1
    local width = options.width or 20
    local height = options.height or 10
    local scroll = options.scroll or 1
    local count = options.count or 0

    if mouseX < x or mouseX >= x + width then
        return nil
    end

    if mouseY < y or mouseY >= y + height then
        return nil
    end

    local row = mouseY - y + 1
    local index = scroll + row - 1

    if index < 1 or index > count then
        return nil
    end

    return index
end

function List.draw(ctx, options)
    local theme = ctx.theme

    local x = options.x or 1
    local y = options.y or 1
    local width = options.width or 20
    local height = options.height or 10
    local items = options.items or {}
    local selected = options.selected or 1
    local scroll = options.scroll or 1
    local emptyText = options.emptyText or "(empty)"

    local visibleRows = height

    for row = 1, visibleRows do
        local itemIndex = scroll + row - 1
        local item = items[itemIndex]
        local screenY = y + row - 1

        term.setCursorPos(x, screenY)

        if item then
            local text

            if type(item) == "table" then
                text = item.label or item.name or tostring(item.value or "")
            else
                text = tostring(item)
            end

            text = cutText(text, width - 2)

            if itemIndex == selected then
                term.setBackgroundColor(theme.accent)
                term.setTextColor(colors.black)
                term.write("> " .. text .. string.rep(" ", math.max(0, width - 2 - #text)))
                term.setBackgroundColor(theme.background)
                term.setTextColor(theme.text)
            else
                term.setBackgroundColor(theme.background)
                term.setTextColor(theme.foreground)
                term.write("  " .. text .. string.rep(" ", math.max(0, width - 2 - #text)))
            end
        else
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.muted)

            if #items == 0 and row == 1 then
                local text = cutText(emptyText, width)
                term.write(text .. string.rep(" ", math.max(0, width - #text)))
            else
                term.write(string.rep(" ", width))
            end
        end
    end

    term.setBackgroundColor(theme.background)
    term.setTextColor(theme.text)
end

return List