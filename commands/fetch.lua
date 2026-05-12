local FetchCommand = {}

FetchCommand.description = "Show NovaOS system information"
FetchCommand.category = "system"
FetchCommand.usage = "fetch"
FetchCommand.aliases = {
    "neofetch",
    "screenfetch"
}
FetchCommand.examples = {
    "fetch"
}

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
end

local function cutText(text, width)
    text = tostring(text or "")

    if width <= 0 then
        return ""
    end

    if #text <= width then
        return text
    end

    return string.sub(text, 1, width)
end

local function writeColor(text, color)
    if color then
        term.setTextColor(color)
    end

    write(tostring(text or ""))
end

local function printColor(text, color)
    if color then
        term.setTextColor(color)
    end

    print(tostring(text or ""))
end

local function getLogo()
    return {
        " _   _                 ___  ____  ",
        "| \\ | | _____   ____ _/ _ \\/ ___| ",
        "|  \\| |/ _ \\ \\ / / _` | | | \\___ \\",
        "| |\\  | (_) \\ V / (_| | |_| |___) |",
        "|_| \\_|\\___/ \\_/ \\__,_|\\___/|____/ "
    }
end

local function getCompactLogo()
    return {
        " _   _             ",
        "| \\ | | _____   __ ",
        "|  \\| |/ _ \\ \\ / / ",
        "| |\\  | (_) \\ V /  ",
        "|_| \\_|\\___/ \\_/   "
    }
end

local function countCommands(ctx)
    if not ctx or not ctx.registry then
        return 0
    end

    if ctx.registry.list then
        local ok, result = pcall(function()
            return ctx.registry:list()
        end)

        if ok and type(result) == "table" then
            return #result
        end
    end

    if ctx.registry.commands and type(ctx.registry.commands) == "table" then
        local count = 0

        for _, _ in pairs(ctx.registry.commands) do
            count = count + 1
        end

        return count
    end

    return 0
end

local function countApps()
    if not fs.exists("apps") or not fs.isDir("apps") then
        return 0
    end

    local count = 0

    for _, item in ipairs(fs.list("apps")) do
        local path = fs.combine("apps", item)

        if fs.isDir(path) then
            count = count + 1
        end
    end

    return count
end

local function getThemeName(ctx)
    if ctx and ctx.config and ctx.config.theme then
        return tostring(ctx.config.theme)
    end

    if ctx and ctx.theme and ctx.theme.name then
        return tostring(ctx.theme.name)
    end

    return "unknown"
end

local function getHostname(ctx)
    if ctx and ctx.config and ctx.config.hostname then
        return tostring(ctx.config.hostname)
    end

    local label = os.getComputerLabel()

    if label and label ~= "" then
        return label
    end

    return "computer-" .. tostring(os.getComputerID())
end

local function getUptime()
    local seconds = math.floor(os.clock())

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    local function two(value)
        if value < 10 then
            return "0" .. tostring(value)
        end

        return tostring(value)
    end

    return two(hours) .. ":" .. two(minutes) .. ":" .. two(secs)
end

local function getTerminalSize()
    local width, height = term.getSize()
    return tostring(width) .. "x" .. tostring(height)
end

local function getSystemName(ctx)
    if ctx and ctx.config and ctx.config.systemName then
        return tostring(ctx.config.systemName)
    end

    return "NovaOS"
end

local function getSystemVersion(ctx)
    if ctx and ctx.config and ctx.config.version then
        return tostring(ctx.config.version)
    end

    return "0.1.0"
end

local function getShellName(ctx)
    if ctx and ctx.config and ctx.config.shellName then
        return tostring(ctx.config.shellName)
    end

    return "NovaShell"
end

local function getKernelName(ctx)
    if ctx and ctx.config and ctx.config.kernelName then
        return tostring(ctx.config.kernelName)
    end

    return "CraftKernel 0.1"
end

local function buildInfo(ctx)
    return {
        { key = "OS", value = getSystemName(ctx) .. " " .. getSystemVersion(ctx) },
        { key = "Host", value = getHostname(ctx) },
        { key = "ID", value = tostring(os.getComputerID()) },
        { key = "Kernel", value = getKernelName(ctx) },
        { key = "Shell", value = getShellName(ctx) },
        { key = "Theme", value = getThemeName(ctx) },
        { key = "Uptime", value = getUptime() },
        { key = "Apps", value = tostring(countApps()) },
        { key = "Commands", value = tostring(countCommands(ctx)) },
        { key = "Terminal", value = getTerminalSize() }
    }
end

local function getThemeColors(ctx)
    local theme = ctx and ctx.theme or {}

    return {
        logo = theme.accent or colors.orange,
        key = theme.accent2 or colors.yellow,
        value = theme.foreground or colors.orange,
        muted = theme.muted or colors.gray,
        background = theme.background or colors.black
    }
end

local function getLogoWidth(logo)
    local width = 0

    for _, line in ipairs(logo) do
        if #line > width then
            width = #line
        end
    end

    return width
end

local function printInfoLine(key, value, colorset, infoWidth)
    local keyText = tostring(key or "") .. ": "
    local valueText = tostring(value or "")

    writeColor(keyText, colorset.key)
    printColor(cutText(valueText, infoWidth - #keyText), colorset.value)
end

local function printSideBySide(ctx)
    local screenWidth = term.getSize()
    local colorset = getThemeColors(ctx)

    local logo = getLogo()
    local info = buildInfo(ctx)

    local logoWidth = getLogoWidth(logo)
    local gap = 4
    local minInfoWidth = 22

    if screenWidth < logoWidth + gap + minInfoWidth then
        logo = getCompactLogo()
        logoWidth = getLogoWidth(logo)
        gap = 3
    end

    local infoWidth = screenWidth - logoWidth - gap

    if infoWidth < 14 then
        for _, row in ipairs(info) do
            printInfoLine(row.key, row.value, colorset, screenWidth)
        end

        print("")
        return
    end

    local totalRows = math.max(#logo, #info)

    for index = 1, totalRows do
        local logoLine = logo[index] or ""
        local row = info[index]

        writeColor(padRight(logoLine, logoWidth), colorset.logo)
        write(string.rep(" ", gap))

        if row then
            local keyText = tostring(row.key or "") .. ": "
            local valueText = tostring(row.value or "")

            writeColor(keyText, colorset.key)
            printColor(cutText(valueText, infoWidth - #keyText), colorset.value)
        else
            print("")
        end
    end

    print("")
end

local function printColorBar(ctx)
    local colorset = getThemeColors(ctx)

    if not term.isColor or not term.isColor() then
        printColor("Colors: color unavailable", colorset.muted)
        return
    end

    writeColor("Colors: ", colorset.muted)

    local palette = {
        colors.red,
        colors.orange,
        colors.yellow,
        colors.lime,
        colors.cyan,
        colors.blue,
        colors.purple,
        colors.magenta,
        colors.white
    }

    local oldBackground = colors.black
    local oldText = colors.white

    if ctx and ctx.theme then
        oldBackground = ctx.theme.background or oldBackground
        oldText = ctx.theme.text or oldText
    end

    for _, color in ipairs(palette) do
        term.setBackgroundColor(color)
        term.setTextColor(color)
        write("  ")
    end

    term.setBackgroundColor(oldBackground)
    term.setTextColor(oldText)
    print("")
end

function FetchCommand.run(ctx, args)
    printSideBySide(ctx)
    printColorBar(ctx)

    return true
end

return FetchCommand