local FileHelp = {}

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

function FileHelp.new(ctx)
    local self = {}

    self.ctx = ctx

    self.rows = {
        { key = "Enter / left click", action = "Open folder or preview file" },
        { key = "Wheel / Up / Down", action = "Move selection" },
        { key = "PageUp / PageDown", action = "Move faster" },
        { key = "Backspace / Left", action = "Go to parent directory" },
        { key = "Right click", action = "Go to parent directory" },
        { key = "N", action = "Create new file" },
        { key = "D", action = "Create new directory" },
        { key = "R", action = "Rename selected item" },
        { key = "X / Delete", action = "Delete selected item" },
        { key = "C", action = "Copy selected item" },
        { key = "M", action = "Move selected item" },
        { key = "E", action = "Edit selected file" },
        { key = "Q / Esc", action = "Quit Files" },
        { key = "H", action = "Show this help" }
    }

    function self:draw(scroll)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()

        local boxW = math.min(width - 4, 66)
        local boxH = math.min(height - 4, 18)

        if boxW < 34 then
            boxW = width - 2
        end

        if boxH < 10 then
            boxH = height - 2
        end

        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, "Files Help")

        local contentX = boxX + 2
        local contentY = boxY + 2
        local contentW = boxW - 4
        local contentH = boxH - 5

        if contentH < 1 then
            contentH = 1
        end

        local maxScroll = #self.rows - contentH + 1

        if maxScroll < 1 then
            maxScroll = 1
        end

        if scroll < 1 then
            scroll = 1
        end

        if scroll > maxScroll then
            scroll = maxScroll
        end

        writeAt(contentX, contentY, cutText("Key", math.floor(contentW * 0.42)), theme.accent2, theme.background)
        writeAt(contentX + math.floor(contentW * 0.42) + 2, contentY, "Action", theme.accent2, theme.background)
        writeAt(contentX, contentY + 1, string.rep("-", contentW), theme.muted, theme.background)

        local keyW = math.floor(contentW * 0.42)
        local actionW = contentW - keyW - 2

        for visibleIndex = 1, contentH - 2 do
            local rowIndex = scroll + visibleIndex - 1
            local row = self.rows[rowIndex]
            local y = contentY + 1 + visibleIndex

            writeAt(contentX, y, string.rep(" ", contentW), theme.foreground, theme.background)

            if row then
                writeAt(contentX, y, cutText(row.key, keyW), theme.accent, theme.background)
                writeAt(contentX + keyW + 2, y, cutText(row.action, actionW), theme.foreground, theme.background)
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

        Box.footer(ctx, boxX, boxY, boxW, boxH, "Wheel/Up/Down: scroll   Q/Esc/Right click: return")

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

return FileHelp