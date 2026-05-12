local TasksView = {}

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

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

function TasksView.new(ctx)
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
        local listW = boxW - 4
        local listH = boxH - 10

        if listW < 20 then
            listW = 20
        end

        if listH < 3 then
            listH = 3
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
            listH = listH
        }
    end

    function self:getMaxScroll(totalRows, visibleRows)
        local maxScroll = totalRows - visibleRows + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        return maxScroll
    end

    function self:getColumnLayout(width)
        if width >= 58 then
            local idW = 5
            local nameW = math.floor(width * 0.34)
            local kindW = math.floor(width * 0.20)
            local statusW = math.floor(width * 0.20)
            local ageW = width - idW - nameW - kindW - statusW - 8

            if ageW < 5 then
                ageW = 5
            end

            return {
                id = idW,
                name = nameW,
                kind = kindW,
                status = statusW,
                age = ageW
            }
        end

        local idW = 4
        local nameW = math.floor(width * 0.42)
        local kindW = math.floor(width * 0.22)
        local statusW = width - idW - nameW - kindW - 6

        if statusW < 8 then
            statusW = 8
        end

        return {
            id = idW,
            name = nameW,
            kind = kindW,
            status = statusW,
            age = 0
        }
    end

    function self:drawHeader(layout)
        local theme = self.ctx.theme
        local columns = self:getColumnLayout(layout.listW)

        local x = layout.listX
        local y = layout.listY - 2

        writeAt(x, y, string.rep(" ", layout.listW), theme.muted, theme.background)

        writeAt(x, y, padRight("ID", columns.id), theme.accent2, theme.background)
        x = x + columns.id + 2

        writeAt(x, y, padRight("NAME", columns.name), theme.accent2, theme.background)
        x = x + columns.name + 2

        writeAt(x, y, padRight("KIND", columns.kind), theme.accent2, theme.background)
        x = x + columns.kind + 2

        writeAt(x, y, padRight("STATUS", columns.status), theme.accent2, theme.background)

        if columns.age > 0 then
            x = x + columns.status + 2
            writeAt(x, y, padRight("AGE", columns.age), theme.accent2, theme.background)
        end

        writeAt(layout.listX, layout.listY - 1, string.rep("-", layout.listW), theme.muted, theme.background)
    end

    function self:drawTaskRow(layout, rowY, task, selected)
        local theme = self.ctx.theme
        local columns = self:getColumnLayout(layout.listW)

        local fg = theme.foreground
        local bg = theme.background

        if selected then
            fg = colors.black
            bg = theme.accent
        end

        writeAt(layout.listX, rowY, string.rep(" ", layout.listW), fg, bg)

        local x = layout.listX

        writeAt(x, rowY, padRight(cutText(tostring(task.id or ""), columns.id), columns.id), fg, bg)
        x = x + columns.id + 2

        writeAt(x, rowY, padRight(cutText(task.name or "", columns.name), columns.name), fg, bg)
        x = x + columns.name + 2

        writeAt(x, rowY, padRight(cutText(task.kind or "", columns.kind), columns.kind), fg, bg)
        x = x + columns.kind + 2

        local statusColor = fg

        if not selected then
            if task.status == "running" then
                statusColor = theme.success
            elseif task.status == "error" or task.status == "crashed" then
                statusColor = theme.error
            elseif task.status == "created" then
                statusColor = theme.warning
            end
        end

        writeAt(x, rowY, padRight(cutText(task.status or "", columns.status), columns.status), statusColor, bg)

        if columns.age > 0 then
            x = x + columns.status + 2
            writeAt(x, rowY, padRight(cutText(task.age or "", columns.age), columns.age), fg, bg)
        end

        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
    end

    function self:drawDetails(layout, task)
        local theme = self.ctx.theme

        local y = layout.boxY + layout.boxH - 4
        local width = layout.boxW - 4
        local x = layout.boxX + 2

        writeAt(x, y, string.rep(" ", width), theme.foreground, theme.background)

        if not task then
            writeAt(x, y, "Selected: none", theme.muted, theme.background)
            return
        end

        local text =
            "Selected: #" ..
            tostring(task.id or "?") ..
            " " ..
            tostring(task.name or "unknown") ..
            " / " ..
            tostring(task.kind or "generic") ..
            " / " ..
            tostring(task.status or "unknown") ..
            " / age " ..
            tostring(task.age or "?")

        writeAt(x, y, cutText(text, width), theme.muted, theme.background)
    end

    function self:drawSummary(layout, info)
        local theme = self.ctx.theme

        local total = tostring(info.total or 0)
        local running = tostring((info.statusCounts and info.statusCounts.running) or 0)
        local created = tostring((info.statusCounts and info.statusCounts.created) or 0)

        local text = "Total: " .. total .. "   Running: " .. running .. "   Created: " .. created

        self.ctx.ui.Box.writeInside(
            self.ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            2,
            text,
            theme.accent2
        )

        self.ctx.ui.Box.writeInside(
            self.ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            3,
            "H: help   R: refresh   Q: quit",
            theme.muted
        )
    end

    function self:draw(tasks, state, info)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        state = state or {}
        info = info or {}

        local layout = self:getLayout()

        local selected = state.selected or 1
        local scroll = state.scroll or 1

        if #tasks <= 0 then
            selected = 1
            scroll = 1
        else
            selected = clamp(selected, 1, #tasks)
        end

        local maxScroll = self:getMaxScroll(#tasks, layout.listH)

        scroll = clamp(scroll, 1, maxScroll)

        if selected < scroll then
            scroll = selected
        end

        if selected > scroll + layout.listH - 1 then
            scroll = selected - layout.listH + 1
        end

        scroll = clamp(scroll, 1, maxScroll)

        ctx.screen:clear(theme.background, theme.text)

        Box.draw(ctx, layout.boxX, layout.boxY, layout.boxW, layout.boxH, "Tasks")
        self:drawSummary(layout, info)

        Box.drawSeparator(ctx, layout.boxX, layout.boxY + 4, layout.boxW)

        self:drawHeader(layout)

        if #tasks == 0 then
            writeAt(layout.listX, layout.listY, "(no tasks)", theme.muted, theme.background)
        else
            for visibleIndex = 1, layout.listH do
                local taskIndex = scroll + visibleIndex - 1
                local task = tasks[taskIndex]
                local rowY = layout.listY + visibleIndex - 1

                if task then
                    self:drawTaskRow(layout, rowY, task, taskIndex == selected)
                else
                    writeAt(layout.listX, rowY, string.rep(" ", layout.listW), theme.foreground, theme.background)
                end
            end
        end

        if maxScroll > 1 then
            local scrollText = tostring(scroll) .. "/" .. tostring(maxScroll)

            writeAt(
                layout.boxX + layout.boxW - #scrollText - 2,
                layout.boxY,
                scrollText,
                theme.warning,
                theme.background
            )
        end

        self:drawDetails(layout, tasks[selected])

        Box.footer(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            layout.boxH,
            "H: help   R: refresh   Q: quit"
        )

        StatusBar.drawBottom(ctx, "NovaOS / Tasks", tostring(#tasks) .. " tasks")

        layout.scroll = scroll
        layout.selected = selected
        layout.maxScroll = maxScroll

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
        local index = layout.scroll + row - 1

        if index < 1 or index > count then
            return nil
        end

        return index
    end

    return self
end

return TasksView