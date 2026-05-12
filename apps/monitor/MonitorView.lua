local MonitorView = {}

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

function MonitorView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getLayout()
        local width, height = term.getSize()

        local mainX = 2
        local mainY = 2
        local mainW = width - 2
        local mainH = height - 3

        local contentX = mainX + 2
        local contentY = mainY + 5
        local contentW = mainW - 4
        local contentH = mainH - 9

        if contentW < 10 then
            contentW = 10
        end

        if contentH < 3 then
            contentH = 3
        end

        return {
            width = width,
            height = height,

            mainX = mainX,
            mainY = mainY,
            mainW = mainW,
            mainH = mainH,

            contentX = contentX,
            contentY = contentY,
            contentW = contentW,
            contentH = contentH
        }
    end

    function self:addBlank(rows)
        table.insert(rows, {
            kind = "blank",
            text = ""
        })
    end

    function self:addSection(rows, title)
        table.insert(rows, {
            kind = "section",
            text = title
        })
    end

    function self:addText(rows, text)
        table.insert(rows, {
            kind = "text",
            text = text
        })
    end

    function self:addKeyValue(rows, label, value)
        table.insert(rows, {
            kind = "kv",
            label = label,
            value = value
        })
    end

    function self:buildRows(data)
        local rows = {}

        self:addSection(rows, "Runtime")

        for _, item in ipairs(data.systemRows or {}) do
            self:addKeyValue(rows, item.label, item.value)
        end

        self:addBlank(rows)
        self:addSection(rows, "Tasks")

        local tasks = data.tasks or {}

        if #tasks == 0 then
            self:addText(rows, "(no tasks)")
        else
            for _, task in ipairs(tasks) do
                local text =
                    "#" ..
                    tostring(task.id) ..
                    "  " ..
                    tostring(task.name) ..
                    "  [" ..
                    tostring(task.kind or "task") ..
                    "]  " ..
                    tostring(task.status or "unknown")

                self:addText(rows, text)
            end
        end

        self:addBlank(rows)
        self:addSection(rows, "Peripherals")

        local peripherals = data.peripherals or {}

        if #peripherals == 0 then
            self:addText(rows, "(none)")
        else
            for _, item in ipairs(peripherals) do
                local text =
                    tostring(item.name) ..
                    "  [" ..
                    tostring(item.type) ..
                    "]  " ..
                    tostring(item.status or "online")

                self:addText(rows, text)
            end
        end

        self:addBlank(rows)
        self:addSection(rows, "Rednet")

        for _, item in ipairs(data.rednetRows or {}) do
            self:addKeyValue(rows, item.label, item.value)
        end

        return rows
    end

    function self:getMaxScroll(totalRows, visibleRows)
        local maxScroll = totalRows - visibleRows + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        return maxScroll
    end

    function self:drawSection(layout, y, row)
        local theme = self.ctx.theme
        local title = " " .. tostring(row.text or "") .. " "
        local lineWidth = layout.contentW - #title

        if lineWidth < 0 then
            lineWidth = 0
        end

        writeAt(
            layout.contentX,
            y,
            cutText(title .. string.rep("-", lineWidth), layout.contentW),
            theme.accent,
            theme.background
        )
    end

    function self:drawKeyValue(layout, y, row)
        local theme = self.ctx.theme

        local labelWidth = math.min(14, math.floor(layout.contentW * 0.35))
        local valueWidth = layout.contentW - labelWidth - 2

        local label = cutText(tostring(row.label or "") .. ":", labelWidth)
        local value = cutText(tostring(row.value or ""), valueWidth)

        writeAt(
            layout.contentX,
            y,
            padRight(label, labelWidth),
            theme.accent2,
            theme.background
        )

        writeAt(
            layout.contentX + labelWidth + 2,
            y,
            value,
            theme.foreground,
            theme.background
        )
    end

    function self:drawText(layout, y, row)
        local theme = self.ctx.theme

        writeAt(
            layout.contentX,
            y,
            cutText(tostring(row.text or ""), layout.contentW),
            theme.foreground,
            theme.background
        )
    end

    function self:drawBlank(layout, y)
        writeAt(
            layout.contentX,
            y,
            string.rep(" ", layout.contentW),
            self.ctx.theme.foreground,
            self.ctx.theme.background
        )
    end

    function self:drawRow(layout, y, row)
        self:drawBlank(layout, y)

        if not row then
            return
        end

        if row.kind == "section" then
            self:drawSection(layout, y, row)
        elseif row.kind == "kv" then
            self:drawKeyValue(layout, y, row)
        elseif row.kind == "text" then
            self:drawText(layout, y, row)
        elseif row.kind == "blank" then
            self:drawBlank(layout, y)
        end
    end

    function self:drawScrollInfo(layout, scroll, maxScroll, totalRows)
        local theme = self.ctx.theme

        if maxScroll <= 1 then
            return
        end

        local text = " " .. tostring(scroll) .. "/" .. tostring(maxScroll) .. " "

        writeAt(
            layout.mainX + layout.mainW - #text - 2,
            layout.mainY,
            text,
            theme.warning,
            theme.background
        )

        local totalText = " rows: " .. tostring(totalRows) .. " "

        writeAt(
            layout.mainX + 2,
            layout.mainY + layout.mainH - 2,
            cutText(totalText, layout.mainW - 4),
            theme.muted,
            theme.background
        )
    end

    function self:draw(data, state)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        state = state or {}

        local rows = self:buildRows(data or {})
        local layout = self:getLayout()

        local scroll = state.scroll or 1
        local maxScroll = self:getMaxScroll(#rows, layout.contentH)

        if scroll < 1 then
            scroll = 1
        end

        if scroll > maxScroll then
            scroll = maxScroll
        end

        ctx.screen:clear(theme.background, theme.text)

        Box.draw(ctx, layout.mainX, layout.mainY, layout.mainW, layout.mainH, "System Monitor")

        Box.writeInside(
            ctx,
            layout.mainX,
            layout.mainY,
            layout.mainW,
            2,
            "NovaOS runtime, tasks, peripherals and rednet status",
            theme.accent2
        )

        Box.writeInside(
            ctx,
            layout.mainX,
            layout.mainY,
            layout.mainW,
            3,
            "H: help   R: refresh   Q: quit",
            theme.muted
        )

        Box.drawSeparator(ctx, layout.mainX, layout.mainY + 4, layout.mainW)

        for visibleIndex = 1, layout.contentH do
            local rowIndex = scroll + visibleIndex - 1
            local row = rows[rowIndex]
            local y = layout.contentY + visibleIndex - 1

            self:drawRow(layout, y, row)
        end

        self:drawScrollInfo(layout, scroll, maxScroll, #rows)

        Box.footer(
            ctx,
            layout.mainX,
            layout.mainY,
            layout.mainW,
            layout.mainH,
            "H: help   R: refresh   Q: quit"
        )

        StatusBar.drawBottom(
            ctx,
            "NovaOS / Monitor",
            tostring(#rows) .. " rows"
        )

        return {
            scroll = scroll,
            maxScroll = maxScroll,
            totalRows = #rows,
            visibleRows = layout.contentH
        }
    end

    return self
end

return MonitorView