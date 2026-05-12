local LauncherView = {}

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

local function wrapText(text, width)
    text = tostring(text or "")

    local lines = {}
    local current = ""

    if width < 1 then
        return { "" }
    end

    for word in string.gmatch(text, "%S+") do
        if #word > width then
            if current ~= "" then
                table.insert(lines, current)
                current = ""
            end

            local index = 1

            while index <= #word do
                table.insert(lines, string.sub(word, index, index + width - 1))
                index = index + width
            end
        elseif current == "" then
            current = word
        elseif #current + 1 + #word <= width then
            current = current .. " " .. word
        else
            table.insert(lines, current)
            current = word
        end
    end

    if current ~= "" then
        table.insert(lines, current)
    end

    if #lines == 0 then
        table.insert(lines, "")
    end

    return lines
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

function LauncherView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getLayout()
        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        local listX = boxX + 2
        local listY = boxY + 5
        local listW = math.floor((boxW - 6) * 0.40)
        local listH = boxH - 9

        if listW < 18 then
            listW = 18
        end

        if listH < 3 then
            listH = 3
        end

        local detailsX = listX + listW + 3
        local detailsY = listY
        local detailsW = boxW - listW - 7
        local detailsH = listH

        if detailsW < 18 then
            detailsW = 18
        end

        return {
            boxX = boxX,
            boxY = boxY,
            boxW = boxW,
            boxH = boxH,

            listX = listX,
            listY = listY,
            listW = listW,
            listH = listH,

            detailsX = detailsX,
            detailsY = detailsY,
            detailsW = detailsW,
            detailsH = detailsH
        }
    end

    function self:getListScroll(selected, listScroll, visibleRows, count)
        if count <= 0 then
            return 1
        end

        if listScroll < 1 then
            listScroll = 1
        end

        local maxScroll = count - visibleRows + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        if selected < listScroll then
            listScroll = selected
        end

        if selected > listScroll + visibleRows - 1 then
            listScroll = selected - visibleRows + 1
        end

        if listScroll > maxScroll then
            listScroll = maxScroll
        end

        return listScroll
    end

    function self:buildDetailsRows(app, width)
        local rows = {}

        local function addBlank()
            table.insert(rows, {
                kind = "blank"
            })
        end

        local function addText(text)
            table.insert(rows, {
                kind = "text",
                text = text
            })
        end

        local function addField(label, value)
            label = tostring(label or "")
            value = tostring(value or "")

            local labelWidth = 10
            local valueWidth = width - labelWidth - 2

            if valueWidth < 8 then
                valueWidth = width
            end

            local wrapped = wrapText(value, valueWidth)

            for index, line in ipairs(wrapped) do
                if index == 1 then
                    table.insert(rows, {
                        kind = "field",
                        label = label,
                        value = line
                    })
                else
                    table.insert(rows, {
                        kind = "field",
                        label = "",
                        value = line
                    })
                end
            end
        end

        if not app then
            addText("(no app selected)")
            return rows
        end

        addField("Name", app.name or app.id or "unknown")
        addField("ID", app.id or "unknown")
        addField("Version", app.version or "unknown")
        addField("Category", app.category or "uncategorized")
        addField("Author", app.author or "NovaOS")
        addField("Entry", app.entry or "main.lua")

        addBlank()
        addText("About:")

        local descriptionLines = wrapText(app.description or "No description", width)

        for _, line in ipairs(descriptionLines) do
            addText(line)
        end

        return rows
    end

    function self:clearDetails(layout)
        local theme = self.ctx.theme

        for row = 0, layout.detailsH do
            writeAt(
                layout.detailsX,
                layout.detailsY + row,
                string.rep(" ", layout.detailsW),
                theme.foreground,
                theme.background
            )
        end
    end

    function self:drawDetailsRow(layout, y, row)
        local theme = self.ctx.theme

        writeAt(layout.detailsX, y, string.rep(" ", layout.detailsW), theme.foreground, theme.background)

        if not row then
            return
        end

        if row.kind == "blank" then
            return
        end

        if row.kind == "text" then
            writeAt(
                layout.detailsX,
                y,
                cutText(row.text or "", layout.detailsW),
                theme.foreground,
                theme.background
            )

            return
        end

        if row.kind == "field" then
            local labelWidth = 10
            local valueX = layout.detailsX + labelWidth + 2
            local valueW = layout.detailsW - labelWidth - 2

            if valueW < 1 then
                valueW = 1
            end

            if row.label and row.label ~= "" then
                writeAt(
                    layout.detailsX,
                    y,
                    padRight(tostring(row.label) .. ":", labelWidth),
                    theme.accent2,
                    theme.background
                )
            end

            writeAt(
                valueX,
                y,
                cutText(row.value or "", valueW),
                theme.foreground,
                theme.background
            )
        end
    end

    function self:drawDetails(layout, app, detailsScroll)
        local theme = self.ctx.theme

        self:clearDetails(layout)

        writeAt(layout.detailsX, layout.detailsY, padRight("Details", layout.detailsW), theme.accent, theme.background)
        writeAt(layout.detailsX, layout.detailsY + 1, string.rep("-", layout.detailsW), theme.muted, theme.background)

        local rows = self:buildDetailsRows(app, layout.detailsW)
        local contentY = layout.detailsY + 3
        local contentH = layout.detailsH - 3

        if contentH < 1 then
            contentH = 1
        end

        local maxScroll = #rows - contentH + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        detailsScroll = clamp(detailsScroll or 1, 1, maxScroll)

        for visibleIndex = 1, contentH do
            local rowIndex = detailsScroll + visibleIndex - 1
            local row = rows[rowIndex]
            local y = contentY + visibleIndex - 1

            self:drawDetailsRow(layout, y, row)
        end

        if maxScroll > 1 then
            local scrollText = tostring(detailsScroll) .. "/" .. tostring(maxScroll)

            writeAt(
                layout.detailsX + layout.detailsW - #scrollText,
                layout.detailsY,
                scrollText,
                theme.warning,
                theme.background
            )
        end

        return detailsScroll, maxScroll
    end

    function self:draw(apps, selected, state)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local List = ctx.ui.List
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        state = state or {}

        local message = state.message or ""
        local listScroll = state.listScroll or 1
        local detailsScroll = state.detailsScroll or 1

        ctx.screen:clear(theme.background, theme.text)

        local layout = self:getLayout()

        Box.draw(ctx, layout.boxX, layout.boxY, layout.boxW, layout.boxH, "NovaOS Launcher")

        if message ~= "" then
            Box.writeInside(ctx, layout.boxX, layout.boxY, layout.boxW, 2, message, theme.success)
        else
            Box.writeInside(ctx, layout.boxX, layout.boxY, layout.boxW, 2, "Enter: launch   H: help   Q: quit", theme.muted)
        end

        Box.drawSeparator(ctx, layout.boxX, layout.boxY + 4, layout.boxW)

        selected = List.clamp(selected, #apps)
        listScroll = self:getListScroll(selected, listScroll, layout.listH, #apps)

        List.draw(ctx, {
            x = layout.listX,
            y = layout.listY,
            width = layout.listW,
            height = layout.listH,
            items = apps,
            selected = selected,
            scroll = listScroll,
            emptyText = "(no applications)"
        })

        local normalizedDetailsScroll, maxDetailsScroll =
            self:drawDetails(layout, apps[selected], detailsScroll)

        Box.footer(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            layout.boxH,
            "Enter: launch   H: help   Q: quit"
        )

        StatusBar.drawBottom(ctx, "NovaOS / Launcher", tostring(#apps) .. " apps")

        layout.listScroll = listScroll
        layout.detailsScroll = normalizedDetailsScroll
        layout.maxDetailsScroll = maxDetailsScroll

        return layout
    end

    function self:hitTestList(layout, mouseX, mouseY, count)
        return self.ctx.ui.List.hitTest({
            x = layout.listX,
            y = layout.listY,
            width = layout.listW,
            height = layout.listH,
            scroll = layout.listScroll,
            count = count
        }, mouseX, mouseY)
    end

    function self:isInsideList(layout, mouseX, mouseY)
        return mouseX >= layout.listX
            and mouseX < layout.listX + layout.listW
            and mouseY >= layout.listY
            and mouseY < layout.listY + layout.listH
    end

    function self:isInsideDetails(layout, mouseX, mouseY)
        return mouseX >= layout.detailsX
            and mouseX < layout.detailsX + layout.detailsW
            and mouseY >= layout.detailsY
            and mouseY < layout.detailsY + layout.detailsH
    end

    return self
end

return LauncherView