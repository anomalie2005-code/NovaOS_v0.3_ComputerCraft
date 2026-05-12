local MonitorData = {}

local function getUptime()
    local seconds = math.floor(os.clock())
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function getComputerName()
    local label = os.getComputerLabel()

    if label and label ~= "" then
        return label
    end

    return "computer-" .. tostring(os.getComputerID())
end

local function safeCount(value)
    if type(value) == "table" then
        return #value
    end

    return 0
end

function MonitorData.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getPeripherals()
        if self.ctx.services and self.ctx.services.peripherals then
            return self.ctx.services.peripherals:list()
        end

        local result = {}
        local names = peripheral.getNames()

        table.sort(names)

        for _, name in ipairs(names) do
            table.insert(result, {
                name = name,
                type = peripheral.getType(name) or "unknown",
                status = "online"
            })
        end

        return result
    end

    function self:getTasks()
        if self.ctx.services and self.ctx.services.tasks then
            return self.ctx.services.tasks:list()
        end

        return {}
    end

    function self:getRednetStatus()
        if self.ctx.services and self.ctx.services.rednet then
            return self.ctx.services.rednet:getStatus()
        end

        return {
            available = false,
            reason = "Rednet service is not loaded.",
            modems = {}
        }
    end

    function self:getSystemRows()
        local termW, termH = term.getSize()
        local peripherals = self:getPeripherals()
        local tasks = self:getTasks()

        return {
            { label = "OS", value = self.ctx.config.systemName .. " " .. self.ctx.config.version },
            { label = "Host", value = getComputerName() },
            { label = "ID", value = tostring(os.getComputerID()) },
            { label = "Shell", value = self.ctx.config.shellName },
            { label = "Theme", value = self.ctx.config.theme },
            { label = "Uptime", value = getUptime() },
            { label = "Terminal", value = tostring(termW) .. "x" .. tostring(termH) },
            { label = "Home", value = self.ctx.filesystem:display(self.ctx.config.homeDir) },
            { label = "Tasks", value = tostring(safeCount(tasks)) },
            { label = "Peripherals", value = tostring(safeCount(peripherals)) }
        }
    end

    function self:getRednetRows()
        local status = self:getRednetStatus()
        local rows = {}

        table.insert(rows, {
            label = "Available",
            value = tostring(status.available)
        })

        table.insert(rows, {
            label = "Status",
            value = status.reason or "unknown"
        })

        if status.modems and #status.modems > 0 then
            for _, modem in ipairs(status.modems) do
                table.insert(rows, {
                    label = modem.name,
                    value = modem.open and "open" or "closed"
                })
            end
        else
            table.insert(rows, {
                label = "Modems",
                value = "none"
            })
        end

        return rows
    end

    function self:collect()
        return {
            systemRows = self:getSystemRows(),
            peripherals = self:getPeripherals(),
            tasks = self:getTasks(),
            rednetRows = self:getRednetRows()
        }
    end

    return self
end

return MonitorData