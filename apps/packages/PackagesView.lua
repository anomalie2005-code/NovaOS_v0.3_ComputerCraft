local PackagesView = {}

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

function PackagesView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getLayout()
        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        local listX = boxX + 2
        local listY = boxY + 6
        local listW = math.floor((boxW - 6) * 0.42)
        local listH = boxH - 10

        if listW < 20 then
            listW = 20
        end

        if listH < 3 then
            listH = 3
        end

        local detailsX = listX + listW + 3
        local detailsY = listY
        local detailsW = boxW - listW - 7
        local detailsH = listH

        if detailsW < 20 then
            detailsW = 20
        end

        return {
            width = width,
            height = height,

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

    function self:getStatusColor(status, selected)
        local theme = self.ctx.theme

        if selected then
            return colors.black
        end

        if status == "ok" then
            return theme.success
        end

        if status == "missing_manifest" or status == "missing_entry" or status == "broken_manifest" then
            return theme.error
        end

        return theme.warning
    end

    function self:getListScroll(selected, listScroll, visibleRows, count)
        if count <= 0 then
            return 1
        end

        local maxScroll = count - visibleRows + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        if listScroll < 1 then
            listScroll = 1
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

    function self:drawSummary(layout, summary)
        local theme = self.ctx.theme

        local text =
            "Total: " ..
            tostring(summary.total or 0) ..
            "   OK: " ..
            tostring(summary.ok or 0) ..
            "   Broken: " ..
            tostring(summary.broken or 0)

        self.ctx.ui.Box.writeInside(
            self.ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            2,
            text,
            theme.accent2
        )
    end

    function self:drawMessage(layout, message)
        if not message or message == "" then
            self.ctx.ui.Box.writeInside(
                self.ctx,
                layout.boxX,
                layout.boxY,
                layout.boxW,
                3,
                "Enter: launch   H: help   Q: quit",
                self.ctx.theme.muted
            )

            return
        end

        self.ctx.ui.Box.writeInside(
            self.ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            3,
            message,
            self.ctx.theme.warning
        )
    end

    function self:drawList(layout, packages, selected, listScroll)
        local theme = self.ctx.theme

        writeAt(layout.listX, layout.listY - 2, padRight("Packages", layout.listW), theme.accent, theme.background)
        writeAt(layout.listX, layout.listY - 1, string.rep("-", layout.listW), theme.muted, theme.background)

        for visibleIndex = 1, layout.listH do
            local packageIndex = listScroll + visibleIndex - 1
            local package = packages[packageIndex]
            local y = layout.listY + visibleIndex - 1

            local fg = theme.foreground
            local bg = theme.background

            if packageIndex == selected then
                fg = colors.black
                bg = theme.accent
            end

            writeAt(layout.listX, y, string.rep(" ", layout.listW), fg, bg)

            if package then
                local statusIcon = "?"

                if package.status == "ok" then
                    statusIcon = "+"
                elseif package.status == "missing_manifest" then
                    statusIcon = "M"
                elseif package.status == "missing_entry" then
                    statusIcon = "E"
                elseif package.status == "broken_manifest" then
                    statusIcon = "B"
                end

                local nameWidth = layout.listW - 5

                writeAt(layout.listX, y, "[" .. statusIcon .. "]", self:getStatusColor(package.status, packageIndex == selected), bg)
                writeAt(layout.listX + 4, y, cutText(package.name or package.id, nameWidth), fg, bg)
            end
        end

        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
    end

    function self:buildDetailsRows(package, width)
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
            local labelWidth = 12
            local valueWidth = width - labelWidth - 2

            if valueWidth < 8 then
                valueWidth = width
            end

            local wrapped = wrapText(tostring(value or ""), valueWidth)

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

        if not package then
            addText("(no package selected)")
            return rows
        end

        addField("Name", package.name)
        addField("ID", package.id)
        addField("Folder", package.folder)
        addField("Version", package.version)
        addField("Category", package.category)
        addField("Author", package.author)
        addField("Status", package.status)
        addField("Entry", package.entry)
        addField("Size", package.sizeText)
        addField("Files", tostring(package.fileCount))
        addField("Manifest", package.manifestExists and "yes" or "no")
        addField("Entry file", package.entryExists and "yes" or "no")

        if package.manifestError then
            addBlank()
            addText("Manifest error:")

            for _, line in ipairs(wrapText(package.manifestError, width)) do
                addText(line)
            end
        end

        addBlank()
        addText("Actions:")
        addText("V validate  B backup")
        addText("D delete    R repair")
        addText("F open folder  N new")

        addBlank()
        addText("Description:")

        for _, line in ipairs(wrapText(package.description or "No description", width)) do
            addText(line)
        end

        return rows
    end

    function self:drawDetailsRow(layout, y, row)
        local theme = self.ctx.theme

        writeAt(layout.detailsX, y, string.rep(" ", layout.detailsW), theme.foreground, theme.background)

        if not row or row.kind == "blank" then
            return
        end

        if row.kind == "text" then
            writeAt(layout.detailsX, y, cutText(row.text or "", layout.detailsW), theme.foreground, theme.background)
            return
        end

        if row.kind == "field" then
            local labelWidth = 12
            local valueX = layout.detailsX + labelWidth + 2
            local valueW = layout.detailsW - labelWidth - 2

            if row.label and row.label ~= "" then
                writeAt(layout.detailsX, y, padRight(row.label .. ":", labelWidth), theme.accent2, theme.background)
            end

            writeAt(valueX, y, cutText(row.value or "", valueW), theme.foreground, theme.background)
        end
    end

    function self:drawDetails(layout, package, detailsScroll)
        local theme = self.ctx.theme

        writeAt(layout.detailsX, layout.detailsY - 2, padRight("Details", layout.detailsW), theme.accent, theme.background)
        writeAt(layout.detailsX, layout.detailsY - 1, string.rep("-", layout.detailsW), theme.muted, theme.background)

        local rows = self:buildDetailsRows(package, layout.detailsW)

        local maxScroll = #rows - layout.detailsH + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        detailsScroll = clamp(detailsScroll or 1, 1, maxScroll)

        for visibleIndex = 1, layout.detailsH do
            local rowIndex = detailsScroll + visibleIndex - 1
            local y = layout.detailsY + visibleIndex - 1

            self:drawDetailsRow(layout, y, rows[rowIndex])
        end

        if maxScroll > 1 then
            local scrollText = tostring(detailsScroll) .. "/" .. tostring(maxScroll)

            writeAt(
                layout.detailsX + layout.detailsW - #scrollText,
                layout.detailsY - 2,
                scrollText,
                theme.warning,
                theme.background
            )
        end

        return detailsScroll, maxScroll
    end

    function self:draw(packages, selected, state, summary)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        state = state or {}
        summary = summary or {}

        local listScroll = state.listScroll or 1
        local detailsScroll = state.detailsScroll or 1
        local message = state.message or ""

        local layout = self:getLayout()

        if #packages <= 0 then
            selected = 1
            listScroll = 1
        else
            selected = clamp(selected, 1, #packages)
            listScroll = self:getListScroll(selected, listScroll, layout.listH, #packages)
        end

        ctx.screen:clear(theme.background, theme.text)

        Box.draw(ctx, layout.boxX, layout.boxY, layout.boxW, layout.boxH, "Package Manager")
        self:drawSummary(layout, summary)
        self:drawMessage(layout, message)
        Box.drawSeparator(ctx, layout.boxX, layout.boxY + 4, layout.boxW)

        self:drawList(layout, packages, selected, listScroll)

        local normalizedDetailsScroll, maxDetailsScroll =
            self:drawDetails(layout, packages[selected], detailsScroll)

        Box.footer(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            layout.boxH,
            "Enter: launch   H: help   Q: quit"
        )

        StatusBar.drawBottom(ctx, "NovaOS / Packages", tostring(#packages) .. " packages")

        layout.selected = selected
        layout.listScroll = listScroll
        layout.detailsScroll = normalizedDetailsScroll
        layout.maxDetailsScroll = maxDetailsScroll

        return layout
    end

    function self:hitTestList(layout, mouseX, mouseY, count)
        if mouseX < layout.listX or mouseX >= layout.listX + layout.listW then
            return nil
        end

        if mouseY < layout.listY or mouseY >= layout.listY + layout.listH then
            return nil
        end

        local row = mouseY - layout.listY + 1
        local index = layout.listScroll + row - 1

        if index < 1 or index > count then
            return nil
        end

        return index
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

return PackagesView