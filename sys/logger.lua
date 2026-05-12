local Class = require("sys.class")

local Logger = Class.create()

function Logger:init(logFile)
    self.logFile = logFile or "data/logs/system.log"

    local logDir = fs.getDir(self.logFile)

    if logDir ~= "" and not fs.exists(logDir) then
        fs.makeDir(logDir)
    end
end

function Logger:getTime()
    local ok, formatted = pcall(function()
        return textutils.formatTime(os.time(), true)
    end)

    if ok then
        return formatted
    end

    return "00:00"
end

function Logger:write(level, message)
    local line = "[" .. self:getTime() .. "] [" .. level .. "] " .. tostring(message)

    local handle = fs.open(self.logFile, "a")

    if handle then
        handle.writeLine(line)
        handle.close()
    end
end

function Logger:info(message)
    self:write("INFO", message)
end

function Logger:warn(message)
    self:write("WARN", message)
end

function Logger:error(message)
    self:write("ERROR", message)
end

function Logger:readAll()
    if not fs.exists(self.logFile) then
        return ""
    end

    local handle = fs.open(self.logFile, "r")

    if not handle then
        return ""
    end

    local content = handle.readAll()
    handle.close()

    return content or ""
end

return Logger