local FilePreview = {}

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

local function splitLines(text)
    local lines = {}

    text = tostring(text or "")

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        table.insert(lines, line)
    end

    return lines
end

function FilePreview.new(ctx, actions)
    local self = {}

    self.ctx = ctx
    self.actions = actions

    function self:loadLines(filePath)
        local content = ""

        if fs.exists(filePath) and not fs.isDir(filePath) then
            local handle = fs.open(filePath, "r")

            if handle then
                content = handle.readAll() or ""
                handle.close()
            end
        end

        local lines = splitLines(content)

        if #lines == 0 then
            table.insert(lines, "(empty file)")
        end

        return lines
    end

    function self:drawHelp()
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 56)
        local boxH = math.min(height - 4, 13)
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, "Preview Help")

        local rows = {
            "Wheel / Up / Down   Scroll file",
            "PageUp / PageDown   Scroll faster",
            "Home / End          Start / end",
            "E / left click      Edit file",
            "Q / Esc / right     Return to Files"
        }

        for index, row in ipairs(rows) do
            Box.writeInside(ctx, boxX, boxY, boxW, index + 1, row, theme.foreground)
        end

        Box.footer(ctx, boxX, boxY, boxW, boxH, "Press any key or click to return")

        local event = os.pullEvent()

        while event ~= "key" and event ~= "mouse_click" do
            event = os.pullEvent()
        end
    end

    function self:draw(filePath, lines, scroll)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        Box.draw(ctx, boxX, boxY, boxW, boxH, "View: " .. fs.getName(filePath))
        Box.writeInside(ctx, boxX, boxY, boxW, 2, "File: " .. ctx.filesystem:display(filePath), theme.accent2)
        Box.writeInside(ctx, boxX, boxY, boxW, 3, "E: edit   H: help   Q: return", theme.muted)
        Box.drawSeparator(ctx, boxX, boxY + 4, boxW)

        local visibleRows = boxH - 8

        if visibleRows < 1 then
            visibleRows = 1
        end

        for row = 1, visibleRows do
            local lineIndex = scroll + row - 1
            local line = lines[lineIndex]

            if line then
                Box.writeInside(
                    ctx,
                    boxX,
                    boxY + 4,
                    boxW,
                    row,
                    cutText(line, boxW - 4),
                    theme.foreground
                )
            end
        end

        Box.footer(ctx, boxX, boxY, boxW, boxH, "E: edit   H: help   Q: return")
        StatusBar.drawBottom(ctx, "NovaOS / File Preview", fs.getName(filePath))
    end

    function self:run(filePath)
        local lines = self:loadLines(filePath)
        local scroll = 1

        while true do
            self:draw(filePath, lines, scroll)

            local event, a = os.pullEvent()

            if event == "key" then
                local key = a

                if key == keys.q or key == keys.backspace or key == keys.left or key == keys.escape then
                    return true
                elseif key == keys.h then
                    self:drawHelp()
                elseif key == keys.up then
                    scroll = math.max(1, scroll - 1)
                elseif key == keys.down then
                    scroll = math.min(math.max(1, #lines), scroll + 1)
                elseif key == keys.pageUp then
                    scroll = math.max(1, scroll - 8)
                elseif key == keys.pageDown then
                    scroll = math.min(math.max(1, #lines), scroll + 8)
                elseif key == keys.home then
                    scroll = 1
                elseif key == keys["end"] then
                    scroll = math.max(1, #lines)
                elseif key == keys.e then
                    self.actions:editFile(filePath)
                    lines = self:loadLines(filePath)
                    scroll = 1
                end
            elseif event == "mouse_scroll" then
                local direction = a

                if direction > 0 then
                    scroll = math.min(math.max(1, #lines), scroll + 3)
                else
                    scroll = math.max(1, scroll - 3)
                end
            elseif event == "mouse_click" then
                local button = a

                if button == 1 then
                    self.actions:editFile(filePath)
                    lines = self:loadLines(filePath)
                    scroll = 1
                else
                    return true
                end
            end
        end
    end

    return self
end

return FilePreview