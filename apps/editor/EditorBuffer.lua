local EditorBuffer = {}

local function splitLines(text)
    local lines = {}

    text = tostring(text or "")

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        table.insert(lines, line)
    end

    if #lines == 0 then
        table.insert(lines, "")
    end

    return lines
end

local function joinLines(lines)
    return table.concat(lines or { "" }, "\n")
end

function EditorBuffer.new(filePath)
    local self = {}

    self.filePath = filePath
    self.lines = { "" }
    self.modified = false

    function self:load()
        if not self.filePath or self.filePath == "" then
            self.lines = { "" }
            self.modified = false
            return true
        end

        if fs.exists(self.filePath) and fs.isDir(self.filePath) then
            return false, "Cannot edit directory."
        end

        if fs.exists(self.filePath) then
            local handle = fs.open(self.filePath, "r")

            if not handle then
                return false, "Cannot open file."
            end

            local content = handle.readAll() or ""
            handle.close()

            self.lines = splitLines(content)
        else
            self.lines = { "" }
        end

        self.modified = false

        return true
    end

    function self:save()
        if not self.filePath or self.filePath == "" then
            return false, "No file path."
        end

        local parent = fs.getDir(self.filePath)

        if parent and parent ~= "" and not fs.exists(parent) then
            fs.makeDir(parent)
        end

        local handle = fs.open(self.filePath, "w")

        if not handle then
            return false, "Cannot save file."
        end

        handle.write(joinLines(self.lines))
        handle.close()

        self.modified = false

        return true, "Saved."
    end

    function self:getLine(index)
        return self.lines[index] or ""
    end

    function self:setLine(index, value)
        self.lines[index] = tostring(value or "")
        self.modified = true
    end

    function self:lineCount()
        return #self.lines
    end

    function self:insertChar(line, col, ch)
        local current = self:getLine(line)
        local before = string.sub(current, 1, col - 1)
        local after = string.sub(current, col)

        self.lines[line] = before .. ch .. after
        self.modified = true

        return line, col + #ch
    end

    function self:newLine(line, col)
        local current = self:getLine(line)
        local before = string.sub(current, 1, col - 1)
        local after = string.sub(current, col)

        self.lines[line] = before
        table.insert(self.lines, line + 1, after)

        self.modified = true

        return line + 1, 1
    end

    function self:backspace(line, col)
        if line == 1 and col == 1 then
            return line, col
        end

        if col > 1 then
            local current = self:getLine(line)
            local before = string.sub(current, 1, col - 2)
            local after = string.sub(current, col)

            self.lines[line] = before .. after
            self.modified = true

            return line, col - 1
        end

        local previous = self:getLine(line - 1)
        local current = self:getLine(line)
        local newCol = #previous + 1

        self.lines[line - 1] = previous .. current
        table.remove(self.lines, line)

        self.modified = true

        return line - 1, newCol
    end

    function self:delete(line, col)
        local current = self:getLine(line)

        if col <= #current then
            local before = string.sub(current, 1, col - 1)
            local after = string.sub(current, col + 1)

            self.lines[line] = before .. after
            self.modified = true

            return line, col
        end

        if line < #self.lines then
            self.lines[line] = current .. self:getLine(line + 1)
            table.remove(self.lines, line + 1)
            self.modified = true
        end

        return line, col
    end

    function self:find(query, startLine, startCol)
        query = tostring(query or "")

        if query == "" then
            return nil
        end

        startLine = startLine or 1
        startCol = startCol or 1

        for lineIndex = startLine, #self.lines do
            local line = self:getLine(lineIndex)
            local fromCol = 1

            if lineIndex == startLine then
                fromCol = startCol
            end

            local foundStart, foundEnd = string.find(line, query, fromCol, true)

            if foundStart then
                return {
                    line = lineIndex,
                    col = foundStart,
                    finishCol = foundEnd
                }
            end
        end

        for lineIndex = 1, startLine - 1 do
            local line = self:getLine(lineIndex)
            local foundStart, foundEnd = string.find(line, query, 1, true)

            if foundStart then
                return {
                    line = lineIndex,
                    col = foundStart,
                    finishCol = foundEnd
                }
            end
        end

        return nil
    end

    return self
end

return EditorBuffer