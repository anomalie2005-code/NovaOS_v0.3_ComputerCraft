local TerminalBuffer = {}

local DEFAULT_MAX_LINES = 700

local function toString(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function splitLineToWidth(text, width)
    text = toString(text)

    local lines = {}

    if width < 1 then
        return { "" }
    end

    if text == "" then
        return { "" }
    end

    local index = 1

    while index <= #text do
        table.insert(lines, string.sub(text, index, index + width - 1))
        index = index + width
    end

    return lines
end

function TerminalBuffer.new(options)
    options = options or {}

    local self = {}

    self.lines = {}
    self.maxLines = options.maxLines or DEFAULT_MAX_LINES
    self.scrollOffset = 0

    function self:clear()
        self.lines = {}
        self.scrollOffset = 0
    end

    function self:getLineCount()
        return #self.lines
    end

    function self:addRawLine(text)
        table.insert(self.lines, toString(text))

        while #self.lines > self.maxLines do
            table.remove(self.lines, 1)
        end
    end

    function self:addLine(text, width)
        width = tonumber(width or 1) or 1

        local wrapped = splitLineToWidth(text, width)

        for _, line in ipairs(wrapped) do
            self:addRawLine(line)
        end

        self:scrollToBottom()
    end

    function self:addLines(lines, width)
        for _, line in ipairs(lines or {}) do
            self:addLine(line, width)
        end
    end

    function self:addBlank(width)
        self:addLine("", width or 1)
    end

    function self:getMaxScroll(visibleRows)
        visibleRows = tonumber(visibleRows or 1) or 1

        local maxScroll = #self.lines - visibleRows

        if maxScroll < 0 then
            maxScroll = 0
        end

        return maxScroll
    end

    function self:scrollBy(delta, visibleRows)
        delta = tonumber(delta or 0) or 0

        self.scrollOffset = self.scrollOffset + delta

        local maxScroll = self:getMaxScroll(visibleRows)

        if self.scrollOffset < 0 then
            self.scrollOffset = 0
        end

        if self.scrollOffset > maxScroll then
            self.scrollOffset = maxScroll
        end
    end

    function self:scrollToBottom()
        self.scrollOffset = 0
    end

    function self:scrollToTop(visibleRows)
        self.scrollOffset = self:getMaxScroll(visibleRows)
    end

    function self:getVisibleLines(visibleRows)
        visibleRows = tonumber(visibleRows or 1) or 1

        local result = {}
        local lineCount = #self.lines

        if lineCount == 0 then
            return result
        end

        local endIndex = lineCount - self.scrollOffset
        local startIndex = endIndex - visibleRows + 1

        if startIndex < 1 then
            startIndex = 1
        end

        for index = startIndex, endIndex do
            table.insert(result, self.lines[index] or "")
        end

        return result
    end

    return self
end

return TerminalBuffer