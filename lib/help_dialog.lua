local HelpDialog = {}

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

function HelpDialog.new(ctx, options)
    local self = {}

    self.ctx = ctx
    self.title = options.title or "Help"
    self.rows = options.rows or {}

    function self:draw(scroll)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()

        local boxW = math.min(width - 4, 68)
        local boxH = math.min(height - 4, 18)

        if boxW < 34 then
            boxW = width - 2
        end

        if boxH < 10 then
            boxH = height - 2
        end

        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, self.title)

        local contentX = boxX + 2
        local contentY = boxY + 2
        local contentW = boxW - 4
        local contentH = boxH - 5

        if contentH < 3 then
            contentH = 3
        end

        local keyW = math.floor(contentW * 0.40)
        local actionW = contentW - keyW - 2

        local rowsVisible = contentH - 2
        local maxScroll = #self.rows - rowsVisible + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        if scroll < 1 then
            scroll = 1
        end

        if scroll > maxScroll then
            scroll = maxScroll
        end

        writeAt(contentX, contentY, cutText("Key", keyW), theme.accent2, theme.background)
        writeAt(contentX + keyW + 2, contentY, "Action", theme.accent2, theme.background)
        writeAt(contentX, contentY + 1, string.rep("-", contentW), theme.muted, theme.background)

        for visibleIndex = 1, rowsVisible do
            local rowIndex = scroll + visibleIndex - 1
            local row = self.rows[rowIndex]
            local y = contentY + 1 + visibleIndex

            writeAt(contentX, y, string.rep(" ", contentW), theme.foreground, theme.background)

            if row then
                writeAt(contentX, y, cutText(row.key or "", keyW), theme.accent, theme.background)
                writeAt(contentX + keyW + 2, y, cutText(row.action or "", actionW), theme.foreground, theme.background)
            end
        end

        if maxScroll > 1 then
            local scrollText = tostring(scroll) .. "/" .. tostring(maxScroll)

            writeAt(
                boxX + boxW - #scrollText - 2,
                boxY,
                scrollText,
                theme.warning,
                theme.background
            )
        end

        Box.footer(ctx, boxX, boxY, boxW, boxH, "Wheel/Up/Down: scroll   Q/Esc/right click: return")

        return {
            scroll = scroll,
            maxScroll = maxScroll
        }
    end

    function self:run()
        local scroll = 1

        while true do
            local result = self:draw(scroll)

            scroll = result.scroll

            local event, a = os.pullEvent()

            if event == "key" then
                if a == keys.q or a == keys.escape or a == keys.backspace then
                    return true
                elseif a == keys.up then
                    scroll = math.max(1, scroll - 1)
                elseif a == keys.down then
                    scroll = math.min(result.maxScroll, scroll + 1)
                elseif a == keys.pageUp then
                    scroll = math.max(1, scroll - 5)
                elseif a == keys.pageDown then
                    scroll = math.min(result.maxScroll, scroll + 5)
                elseif a == keys.home then
                    scroll = 1
                elseif a == keys["end"] then
                    scroll = result.maxScroll
                end
            elseif event == "mouse_scroll" then
                if a > 0 then
                    scroll = math.min(result.maxScroll, scroll + 3)
                else
                    scroll = math.max(1, scroll - 3)
                end
            elseif event == "mouse_click" then
                if a ~= 1 then
                    return true
                end
            end
        end
    end

    return self
end

return HelpDialog
