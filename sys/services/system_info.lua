local SystemInfo = {}

local function countItems(path)
    if not fs.exists(path) or not fs.isDir(path) then
        return 0
    end

    local count = 0
    local items = fs.list(path)

    for _, _ in ipairs(items) do
        count = count + 1
    end

    return count
end

function SystemInfo.getComputerLabel()
    local label = os.getComputerLabel()

    if label and label ~= "" then
        return label
    end

    return "computer-" .. tostring(os.getComputerID())
end

function SystemInfo.getUptime()
    local seconds = math.floor(os.clock())

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function SystemInfo.collect(ctx)
    local width, height = term.getSize()

    return {
        { label = "OS", value = ctx.config.systemName .. " " .. ctx.config.version },
        { label = "Host", value = SystemInfo.getComputerLabel() },
        { label = "ID", value = tostring(os.getComputerID()) },
        { label = "Kernel", value = "CraftKernel 0.1" },
        { label = "Shell", value = ctx.config.shellName },
        { label = "Theme", value = ctx.config.theme },
        { label = "Uptime", value = SystemInfo.getUptime() },
        { label = "Apps", value = tostring(countItems("apps")) },
        { label = "Commands", value = tostring(countItems("commands")) },
        { label = "Terminal", value = tostring(width) .. "x" .. tostring(height) }
    }
end

return SystemInfo
