local PeripheralsCommand = {}

PeripheralsCommand.description = "List connected peripherals"
PeripheralsCommand.category = "system"
PeripheralsCommand.usage = "peripherals"
PeripheralsCommand.aliases = {
    "periph"
}
PeripheralsCommand.examples = {
    "peripherals",
    "periph"
}

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
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

local function getItems(ctx)
    if ctx.services and ctx.services.peripherals then
        return ctx.services.peripherals:list()
    end

    local items = {}
    local names = peripheral.getNames()

    table.sort(names)

    for _, name in ipairs(names) do
        table.insert(items, {
            name = name,
            type = peripheral.getType(name) or "unknown",
            status = "online"
        })
    end

    return items
end

function PeripheralsCommand.run(ctx, args)
    local theme = ctx.theme
    local items = getItems(ctx)

    term.setTextColor(theme.accent)
    print("Peripherals")
    term.setTextColor(theme.muted)
    print("-----------")

    if #items == 0 then
        term.setTextColor(theme.muted)
        print("(no peripherals connected)")
        term.setTextColor(theme.text)
        return true
    end

    local width = term.getSize()
    local nameWidth = math.max(12, math.floor(width * 0.35))
    local typeWidth = math.max(12, math.floor(width * 0.30))
    local statusWidth = width - nameWidth - typeWidth - 4

    if statusWidth < 8 then
        statusWidth = 8
    end

    term.setTextColor(theme.accent2)
    print(
        padRight("Name", nameWidth) ..
        "  " ..
        padRight("Type", typeWidth) ..
        "  " ..
        "Status"
    )

    term.setTextColor(theme.muted)
    print(string.rep("-", math.min(width, nameWidth + typeWidth + statusWidth + 4)))

    for _, item in ipairs(items) do
        term.setTextColor(theme.foreground)

        write(padRight(cutText(item.name, nameWidth), nameWidth))
        write("  ")
        write(padRight(cutText(item.type, typeWidth), typeWidth))
        write("  ")

        term.setTextColor(theme.success)
        print(cutText(item.status or "online", statusWidth))
    end

    term.setTextColor(theme.text)

    return true
end

return PeripheralsCommand