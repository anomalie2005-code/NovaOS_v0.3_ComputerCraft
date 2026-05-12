local TableView = {}

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

local function writeAt(x, y, text, foreground, background)
    if background then
        term.setBackgroundColor(background)
    end

    if foreground then
        term.setTextColor(foreground)
    end

    term.setCursorPos(x, y)
    term.write(tostring(text or ""))
end

function TableView.draw(ctx, options)
    options = options or {}

    local theme = ctx.theme

    local x = options.x or 1
    local y = options.y or 1
    local width = options.width or 40
    local height = options.height or 10
    local columns = options.columns or {}
    local rows = options.rows or {}
    local scroll = options.scroll or 1
    local selected = options.selected
    local showHeader = options.showHeader ~= false

    local availableRows = height

    if showHeader then
        availableRows = availableRows - 2
    end

    if availableRows < 1 then
        availableRows = 1
    end

    local totalFixed = 0
    local flexibleCount = 0

    for _, column in ipairs(columns) do
        if column.width then
            totalFixed = totalFixed + column.width
        else
            flexibleCount = flexibleCount + 1
        end
    end

    local separators = math.max(0, #columns - 1) * 2
    local remaining = width - totalFixed - separators

    if remaining < 1 then
        remaining = 1
    end

    local flexibleWidth = math.floor(remaining / math.max(1, flexibleCount))

    local columnWidths = {}

    for index, column in ipairs(columns) do
        columnWidths[index] = column.width or flexibleWidth
    end

    if showHeader then
        local currentX = x

        for index, column in ipairs(columns) do
            local columnWidth = columnWidths[index]
            local label = cutText(column.label or column.key or "", columnWidth)

            writeAt(currentX, y, padRight(label, columnWidth), theme.accent, theme.background)

            currentX = currentX + columnWidth

            if index < #columns then
                writeAt(currentX, y, "  ", theme.muted, theme.background)
                currentX = currentX + 2
            end
        end

        writeAt(x, y + 1, string.rep("-", width), theme.muted, theme.background)
        y = y + 2
    end

    for rowIndex = 1, availableRows do
        local dataIndex = scroll + rowIndex - 1
        local row = rows[dataIndex]
        local currentY = y + rowIndex - 1

        if row then
            local currentX = x
            local isSelected = selected == dataIndex

            for columnIndex, column in ipairs(columns) do
                local columnWidth = columnWidths[columnIndex]
                local key = column.key
                local value = row[key]

                if value == nil then
                    value = ""
                end

                local fg = theme.foreground
                local bg = theme.background

                if isSelected then
                    fg = colors.black
                    bg = theme.accent
                elseif column.color then
                    fg = column.color
                end

                local text = cutText(tostring(value), columnWidth)

                writeAt(currentX, currentY, padRight(text, columnWidth), fg, bg)

                currentX = currentX + columnWidth

                if columnIndex < #columns then
                    writeAt(currentX, currentY, "  ", theme.muted, theme.background)
                    currentX = currentX + 2
                end
            end
        else
            writeAt(x, currentY, string.rep(" ", width), theme.muted, theme.background)
        end
    end

    term.setBackgroundColor(theme.background)
    term.setTextColor(theme.text)
end

return TableView
