local TerminalRenderer = {}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if maxLength <= 0 then
        return ""
    end

    if #text <= maxLength then
        return text
    end

    return string.sub(text, 1, maxLength)
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

local function startsWith(text, prefix)
    text = tostring(text or "")
    prefix = tostring(prefix or "")

    return string.sub(text, 1, #prefix) == prefix
end

local function findPromptParts(line)
    line = tostring(line or "")

    local promptStart, promptEnd = string.find(line, " > ", 1, true)

    if not promptStart then
        return nil
    end

    return {
        prompt = string.sub(line, 1, promptEnd),
        command = string.sub(line, promptEnd + 1)
    }
end

local function isAsciiArtLine(line)
    line = tostring(line or "")

    if line == "" then
        return false
    end

    if string.find(line, "^[%s%/%\\_%-%+%|%.%:%;%=%*%#%(%)]*$") then
        return true
    end

    if string.find(line, "Nova") and (
        string.find(line, "/") or
        string.find(line, "\\") or
        string.find(line, "_") or
        string.find(line, "-")
    ) then
        return true
    end

    return false
end

local function isKeyValueLine(line)
    line = tostring(line or "")

    local key, value = string.match(line, "^%s*([%w%s_%-%.]+):%s*(.*)$")

    if key and value then
        return key, value
    end

    return nil
end

local function isHintLine(line)
    line = tostring(line or "")

    if startsWith(line, "Type ") then
        return true
    end

    if startsWith(line, "Mouse wheel") then
        return true
    end

    if startsWith(line, "Use:") then
        return true
    end

    if startsWith(line, "Example:") then
        return true
    end

    if startsWith(line, "Available") then
        return true
    end

    if startsWith(line, "Current") then
        return true
    end

    return false
end

function TerminalRenderer.new(options)
    options = options or {}

    local self = {}

    self.ctx = options.ctx
    self.buffer = options.buffer

    function self:getTheme()
        if self.ctx and self.ctx.theme then
            return self.ctx.theme
        end

        return {
            background = colors.black,
            text = colors.orange,
            foreground = colors.orange,
            muted = colors.brown,
            accent = colors.orange,
            accent2 = colors.yellow,
            warning = colors.yellow,
            error = colors.red,
            success = colors.lime,
            status = colors.brown
        }
    end

    function self:getPalette()
        local theme = self:getTheme()

        return {
            bg = theme.background or colors.black,
            text = theme.text or colors.orange,
            normal = theme.foreground or colors.orange,
            dim = theme.muted or colors.brown,
            title = theme.accent or colors.orange,
            key = theme.accent2 or colors.yellow,
            command = theme.warning or colors.yellow,
            error = theme.error or colors.red,
            success = theme.success or colors.lime,
            bar = theme.status or theme.muted or colors.brown
        }
    end

    function self:getLayout()
        local width, height = term.getSize()

        local headerY = 1
        local outputY = 2
        local inputSeparatorY = height - 1
        local inputY = height

        local outputH = height - 3

        if outputH < 1 then
            outputH = 1
        end

        local outputX = 2
        local outputW = width - 2

        if outputW < 10 then
            outputX = 1
            outputW = width
        end

        return {
            width = width,
            height = height,

            headerY = headerY,

            outputX = outputX,
            outputY = outputY,
            outputW = outputW,
            outputH = outputH,

            inputSeparatorY = inputSeparatorY,
            inputY = inputY
        }
    end

    function self:clearScreen()
        local palette = self:getPalette()

        term.setCursorBlink(false)
        term.setBackgroundColor(palette.bg)
        term.setTextColor(palette.text)
        term.clear()
        term.setCursorPos(1, 1)
    end

    function self:drawHeader(layout)
        local palette = self:getPalette()

        local systemName = "NovaOS"
        local version = "0.1.0"
        local shellName = "NovaShell"

        if self.ctx and self.ctx.config then
            systemName = self.ctx.config.systemName or systemName
            version = self.ctx.config.version or version
        end

        local left = " " .. systemName .. " " .. version .. " "
        local right = " " .. shellName .. " "

        term.setCursorPos(1, layout.headerY)
        term.setBackgroundColor(palette.bg)
        term.setTextColor(palette.bar)
        term.write(string.rep("-", layout.width))

        writeAt(2, layout.headerY, left, palette.title, palette.bg)

        local rightX = layout.width - #right

        if rightX > 2 then
            writeAt(rightX, layout.headerY, right, palette.key, palette.bg)
        end
    end

    function self:writeColoredSegments(x, y, maxWidth, segments)
        local palette = self:getPalette()
        local currentX = x
        local remaining = maxWidth

        for _, segment in ipairs(segments or {}) do
            if remaining <= 0 then
                break
            end

            local text = cutText(segment.text or "", remaining)

            if text ~= "" then
                writeAt(
                    currentX,
                    y,
                    text,
                    segment.color or palette.normal,
                    palette.bg
                )

                currentX = currentX + #text
                remaining = remaining - #text
            end
        end
    end

    function self:drawPromptOutputLine(layout, y, line)
        local palette = self:getPalette()
        local parts = findPromptParts(line)

        if not parts then
            writeAt(layout.outputX, y, cutText(line, layout.outputW), palette.normal, palette.bg)
            return
        end

        self:writeColoredSegments(layout.outputX, y, layout.outputW, {
            { text = parts.prompt, color = palette.key },
            { text = parts.command, color = palette.command }
        })
    end

    function self:drawKeyValueLine(layout, y, line)
        local palette = self:getPalette()
        local key, value = isKeyValueLine(line)

        if not key then
            return false
        end

        local indent = string.match(line, "^(%s*)") or ""

        self:writeColoredSegments(layout.outputX, y, layout.outputW, {
            { text = indent, color = palette.normal },
            { text = key .. ":", color = palette.key },
            { text = " " .. tostring(value or ""), color = palette.normal }
        })

        return true
    end

    function self:drawListLine(layout, y, line)
        local palette = self:getPalette()

        if string.find(line, "^%s*[%-%*]%s+") then
            local indent, marker, text = string.match(line, "^(%s*)([%-%*])%s+(.*)$")

            self:writeColoredSegments(layout.outputX, y, layout.outputW, {
                { text = indent or "", color = palette.dim },
                { text = marker or "-", color = palette.key },
                { text = " " .. tostring(text or ""), color = palette.normal }
            })

            return true
        end

        if string.find(line, "^%s*%[%S+%]") then
            local tag, rest = string.match(line, "^(%s*%[%S+%])%s*(.*)$")

            self:writeColoredSegments(layout.outputX, y, layout.outputW, {
                { text = tag or "", color = palette.key },
                { text = " " .. tostring(rest or ""), color = palette.normal }
            })

            return true
        end

        return false
    end

    function self:drawOutputLine(layout, y, line)
        local palette = self:getPalette()

        line = tostring(line or "")

        writeAt(
            layout.outputX,
            y,
            string.rep(" ", layout.outputW),
            palette.normal,
            palette.bg
        )

        if line == "" then
            return
        end

        if startsWith(line, "Error:") then
            writeAt(layout.outputX, y, cutText(line, layout.outputW), palette.error, palette.bg)
            return
        end

        if startsWith(line, "[returned from") then
            writeAt(layout.outputX, y, cutText(line, layout.outputW), palette.success, palette.bg)
            return
        end

        if findPromptParts(line) then
            self:drawPromptOutputLine(layout, y, line)
            return
        end

        if isAsciiArtLine(line) then
            writeAt(layout.outputX, y, cutText(line, layout.outputW), palette.title, palette.bg)
            return
        end

        if self:drawKeyValueLine(layout, y, line) then
            return
        end

        if self:drawListLine(layout, y, line) then
            return
        end

        if isHintLine(line) then
            writeAt(layout.outputX, y, cutText(line, layout.outputW), palette.dim, palette.bg)
            return
        end

        writeAt(layout.outputX, y, cutText(line, layout.outputW), palette.normal, palette.bg)
    end

    function self:drawOutput(layout)
        local palette = self:getPalette()
        local visibleLines = self.buffer:getVisibleLines(layout.outputH)

        for row = 1, layout.outputH do
            local y = layout.outputY + row - 1
            local line = visibleLines[row]

            self:drawOutputLine(layout, y, line or "")
        end

        if self.buffer.scrollOffset > 0 then
            local text = " scroll " .. tostring(self.buffer.scrollOffset) .. " "
            local x = layout.width - #text

            if x < 1 then
                x = 1
            end

            writeAt(x, layout.inputSeparatorY, text, palette.command, palette.bg)
        end
    end

    function self:drawInputSeparator(layout)
        local palette = self:getPalette()

        term.setCursorPos(1, layout.inputSeparatorY)
        term.setBackgroundColor(palette.bg)
        term.setTextColor(palette.bar)
        term.write(string.rep("-", layout.width))

        local hint = " PgUp/PgDn: scroll  Tab: complete "

        if #hint + 2 < layout.width then
            writeAt(layout.width - #hint, layout.inputSeparatorY, hint, palette.dim, palette.bg)
        end
    end

    function self:drawInput(layout, prompt, input, cursor)
        local palette = self:getPalette()

        prompt = tostring(prompt or "> ")
        input = tostring(input or "")
        cursor = tonumber(cursor or 1) or 1

        local inputX = #prompt + 1
        local inputWidth = layout.width - #prompt

        if inputWidth < 1 then
            inputWidth = 1
        end

        local inputScroll = 1

        if cursor > inputWidth then
            inputScroll = cursor - inputWidth + 1
        end

        local visibleInput = string.sub(input, inputScroll, inputScroll + inputWidth - 1)

        term.setCursorBlink(false)

        term.setCursorPos(1, layout.inputY)
        term.setBackgroundColor(palette.bg)
        term.setTextColor(palette.text)
        term.write(string.rep(" ", layout.width))

        term.setCursorPos(1, layout.inputY)
        term.setTextColor(palette.key)
        term.write(cutText(prompt, layout.width))

        term.setTextColor(palette.text)
        term.write(cutText(visibleInput, inputWidth))

        local cursorX = inputX + cursor - inputScroll

        if cursorX < inputX then
            cursorX = inputX
        end

        if cursorX > layout.width then
            cursorX = layout.width
        end

        term.setCursorPos(cursorX, layout.inputY)
        term.setCursorBlink(true)
    end

    function self:draw(prompt, input, cursor)
        local layout = self:getLayout()

        self:clearScreen()
        self:drawHeader(layout)
        self:drawOutput(layout)
        self:drawInputSeparator(layout)
        self:drawInput(layout, prompt, input, cursor)

        return layout
    end

    function self:restorePlainScreen()
        local palette = self:getPalette()

        term.setCursorBlink(false)
        term.setBackgroundColor(palette.bg)
        term.setTextColor(palette.text)
        term.clear()
        term.setCursorPos(1, 1)
    end

    return self
end

return TerminalRenderer