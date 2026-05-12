local LogsView = {}

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

function LogsView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getLayout()
        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        local contentX = boxX + 2
        local contentY = boxY + 5
        local contentW = boxW - 4
        local contentH = boxH - 9

        if contentW < 10 then
            contentW = 10
        end

        if contentH < 3 then
            contentH = 3
        end

        return {
            width = width,
            height = height,

            boxX = boxX,
            boxY = boxY,
            boxW = boxW,
            boxH = boxH,

            contentX = contentX,
            contentY = contentY,
            contentW = contentW,
            contentH = contentH
        }
    end

    function self:getMaxScroll(lineCount, visibleRows)
        local maxScroll = lineCount - visibleRows + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        return maxScroll
    end

    function self:drawLine(layout, y, line)
        local theme = self.ctx.theme

        line = tostring(line or "")

        local timePart = string.match(line, "^(%[[^%]]+%])")
        local levelPart = string.match(line, "^%[[^%]]+%]%s+(%[[^%]]+%])")
        local messagePart = line

        if timePart and levelPart then
            messagePart = string.gsub(line, "^%[[^%]]+%]%s+%[[^%]]+%]%s*", "")
        end

        writeAt(
            layout.contentX,
            y,
            string.rep(" ", layout.contentW),
            theme.foreground,
            theme.background
        )

        if timePart and levelPart then
            local x = layout.contentX

            writeAt(x, y, cutText(timePart, layout.contentW), theme.muted, theme.background)
            x = x + #timePart + 1

            if x < layout.contentX + layout.contentW then
                local levelColor = theme.accent2

                if string.find(levelPart, "ERROR") then
                    levelColor = theme.error
                elseif string.find(levelPart, "WARN") then
                    levelColor = theme.warning
                elseif string.find(levelPart, "INFO") then
                    levelColor = theme.accent
                end

                writeAt(x, y, cutText(levelPart, layout.contentW - (x - layout.contentX)), levelColor, theme.background)
                x = x + #levelPart + 1
            end

            if x < layout.contentX + layout.contentW then
                writeAt(
                    x,
                    y,
                    cutText(messagePart, layout.contentW - (x - layout.contentX)),
                    theme.foreground,
                    theme.background
                )
            end
        else
            writeAt(
                layout.contentX,
                y,
                cutText(line, layout.contentW),
                theme.foreground,
                theme.background
            )
        end
    end

    function self:draw(lines, state, info)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        state = state or {}
        info = info or {}

        local layout = self:getLayout()

        local scroll = state.scroll or 1
        local maxScroll = self:getMaxScroll(#lines, layout.contentH)

        if scroll < 1 then
            scroll = 1
        end

        if scroll > maxScroll then
            scroll = maxScroll
        end

        ctx.screen:clear(theme.background, theme.text)

        Box.draw(ctx, layout.boxX, layout.boxY, layout.boxW, layout.boxH, "System Logs")

        Box.writeInside(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            2,
            "File: " .. tostring(info.displayPath or "/data/logs/system.log"),
            theme.accent2
        )

        Box.writeInside(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            3,
            "H: help   R: refresh   C: clear   Q: quit",
            theme.muted
        )

        Box.drawSeparator(ctx, layout.boxX, layout.boxY + 4, layout.boxW)

        for visibleIndex = 1, layout.contentH do
            local lineIndex = scroll + visibleIndex - 1
            local line = lines[lineIndex]
            local y = layout.contentY + visibleIndex - 1

            self:drawLine(layout, y, line or "")
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

        Box.footer(
            ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            layout.boxH,
            "H: help   R: refresh   Q: quit"
        )

        StatusBar.drawBottom(ctx, "NovaOS / Logs", tostring(#lines) .. " lines")

        return {
            scroll = scroll,
            maxScroll = maxScroll,
            visibleRows = layout.contentH,
            totalRows = #lines
        }
    end

    function self:confirmClear()
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 48)
        local boxH = 9
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, "Clear log")
        Box.writeInside(ctx, boxX, boxY, boxW, 2, "Clear system.log?", theme.warning)
        Box.writeInside(ctx, boxX, boxY, boxW, 4, "This cannot be undone.", theme.muted)
        Box.footer(ctx, boxX, boxY, boxW, boxH, "Y: clear   any other key/right click: cancel")

        local event, a = os.pullEvent()

        if event == "key" and a == keys.y then
            return true
        end

        return false
    end

    return self
end

return LogsView