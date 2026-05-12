local LogsData = {}

local function splitLines(text)
    local lines = {}

    text = tostring(text or "")

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        table.insert(lines, line)
    end

    return lines
end

function LogsData.new(ctx)
    local self = {}

    self.ctx = ctx
    self.logPath = "data/logs/system.log"

    function self:exists()
        return fs.exists(self.logPath) and not fs.isDir(self.logPath)
    end

    function self:readRaw()
        if not self:exists() then
            return ""
        end

        local handle = fs.open(self.logPath, "r")

        if not handle then
            return ""
        end

        local content = handle.readAll() or ""

        handle.close()

        return content
    end

    function self:readLines()
        local content = self:readRaw()
        local lines = splitLines(content)

        if #lines == 0 then
            table.insert(lines, "(log is empty)")
        end

        return lines
    end

    function self:clear()
        local parent = fs.getDir(self.logPath)

        if parent and parent ~= "" and not fs.exists(parent) then
            fs.makeDir(parent)
        end

        local handle = fs.open(self.logPath, "w")

        if not handle then
            return false, "Cannot clear log file."
        end

        handle.write("")
        handle.close()

        return true, "Log cleared."
    end

    function self:getInfo()
        local size = 0

        if self:exists() then
            size = fs.getSize(self.logPath)
        end

        return {
            path = self.logPath,
            displayPath = "/" .. self.logPath,
            size = size,
            exists = self:exists()
        }
    end

    return self
end

return LogsData