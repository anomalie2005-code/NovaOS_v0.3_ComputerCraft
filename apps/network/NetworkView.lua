local NetworkView = {}

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

function NetworkView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getLayout()
        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        local leftX = boxX + 2
        local leftY = boxY + 6
        local leftW = math.floor((boxW - 6) * 0.45)
        local leftH = boxH - 10

        if leftW < 20 then
            leftW = 20
        end

        if leftH < 3 then
            leftH = 3
        end

        local rightX = leftX + leftW + 3
        local rightY = leftY
        local rightW = boxW - leftW - 7
        local rightH = leftH

        if rightW < 20 then
            rightW = 20
        end

        return {
            boxX = boxX,
            boxY = boxY,
            boxW = boxW,
            boxH = boxH,

            leftX = leftX,
            leftY = leftY,
            leftW = leftW,
            leftH = leftH,

            rightX = rightX,
            rightY = rightY,
            rightW = rightW,
            rightH = rightH
        }
    end

    function self:drawKeyValueRows(x, y, width, height, rows)
        local theme = self.ctx.theme
        local labelW = math.min(14, math.floor(width * 0.42))
        local valueW = width - labelW - 2

        writeAt(x, y - 2, padRight("System", width), theme.accent, theme.background)
        writeAt(x, y - 1, string.rep("-", width), theme.muted, theme.background)

        for index = 1, height do
            local row = rows[index]
            local rowY = y + index - 1

            writeAt(x, rowY, string.rep(" ", width), theme.foreground, theme.background)

            if row then
                writeAt(x, rowY, padRight(cutText(row.label .. ":", labelW), labelW), theme.accent2, theme.background)
                writeAt(x + labelW + 2, rowY, cutText(row.value, valueW), theme.foreground, theme.background)
            end
        end
    end

    function self:drawModems(x, y, width, height, modems)
        local theme = self.ctx.theme

        writeAt(x, y - 2, padRight("Modems", width), theme.accent, theme.background)
        writeAt(x, y - 1, string.rep("-", width), theme.muted, theme.background)

        if #modems == 0 then
            writeAt(x, y, "(no modems found)", theme.muted, theme.background)

            for row = 2, height do
                writeAt(x, y + row - 1, string.rep(" ", width), theme.foreground, theme.background)
            end

            return
        end

        for row = 1, height do
            local modem = modems[row]
            local rowY = y + row - 1

            writeAt(x, rowY, string.rep(" ", width), theme.foreground, theme.background)

            if modem then
                local status = modem.open and "open" or "closed"
                local statusColor = modem.open and theme.success or theme.warning
                local text = tostring(modem.name) .. "  [" .. status .. "]"

                writeAt(x, rowY, cutText(text, width), statusColor, theme.background)
            end
        end
    end

    function self:draw(data, message)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        local layout = self:getLayout()

        ctx.screen:clear(theme.background, theme.text)

        Box.draw(ctx, layout.boxX, layout.boxY, layout.boxW, layout.boxH, "Network")

        if message and message ~= "" then
            Box.writeInside(ctx, layout.boxX, layout.boxY, layout.boxW, 2, message, theme.warning)
        else
            Box.writeInside(ctx, layout.boxX, layout.boxY, layout.boxW, 2, "Rednet and modem network manager", theme.accent2)
        end

        Box.writeInside(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            3,
            "O: open   C: close   S: send   B: broadcast   L: listen   H: help   Q: quit",
            theme.muted
        )

        Box.drawSeparator(ctx, layout.boxX, layout.boxY + 4, layout.boxW)

        self:drawKeyValueRows(layout.leftX, layout.leftY, layout.leftW, layout.leftH, data.rows or {})
        self:drawModems(layout.rightX, layout.rightY, layout.rightW, layout.rightH, data.modems or {})

        Box.footer(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            layout.boxH,
            "O: open   S: send   H: help   Q: quit"
        )

        StatusBar.drawBottom(ctx, "NovaOS / Network", tostring(#(data.modems or {})) .. " modems")

        return layout
    end

    return self
end

return NetworkView