local LogCommand = {}

LogCommand.description = "Show recent system log lines"
LogCommand.category = "system"
LogCommand.usage = "log [number]"
LogCommand.examples = {
    "log",
    "log 20",
    "open logs"
}

local function splitLines(text)
    local lines = {}

    text = tostring(text or "")

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        table.insert(lines, line)
    end

    return lines
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

function LogCommand.run(ctx, args)
    local theme = ctx.theme
    local limit = tonumber(args[2]) or 12

    if limit < 1 then
        limit = 1
    end

    local content = ""

    if ctx.logger and ctx.logger.readAll then
        content = ctx.logger:readAll()
    elseif fs.exists("data/logs/system.log") then
        local handle = fs.open("data/logs/system.log", "r")

        if handle then
            content = handle.readAll() or ""
            handle.close()
        end
    end

    local lines = splitLines(content)

    term.setTextColor(theme.accent)
    print("System log")
    term.setTextColor(theme.muted)
    print("----------")

    if #lines == 0 or content == "" then
        term.setTextColor(theme.muted)
        print("(log is empty)")
        term.setTextColor(theme.text)
        return true
    end

    local startIndex = #lines - limit + 1

    if startIndex < 1 then
        startIndex = 1
    end

    local width = term.getSize()

    term.setTextColor(theme.foreground)

    for index = startIndex, #lines do
        local line = lines[index] or ""

        if string.find(line, "%[ERROR%]") then
            term.setTextColor(theme.error)
        elseif string.find(line, "%[WARN%]") then
            term.setTextColor(theme.warning)
        elseif string.find(line, "%[INFO%]") then
            term.setTextColor(theme.accent)
        else
            term.setTextColor(theme.foreground)
        end

        print(cutText(line, width))
    end

    term.setTextColor(theme.muted)
    print()
    print("Use: log <number>")
    print("Better viewer: open logs")
    term.setTextColor(theme.text)

    return true
end

return LogCommand