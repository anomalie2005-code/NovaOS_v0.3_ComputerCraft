local AppsCommand = {}

AppsCommand.description = "List installed applications"
AppsCommand.category = "apps"
AppsCommand.usage = "apps"
AppsCommand.examples = {
    "apps",
    "open launcher",
    "open packages"
}

local function repeatText(text, count)
    if count <= 0 then
        return ""
    end

    return string.rep(text, count)
end

local function writeColor(text, color)
    term.setTextColor(color)
    write(tostring(text or ""))
end

local function printColor(text, color)
    term.setTextColor(color)
    print(tostring(text or ""))
end

local function wrapText(text, width)
    text = tostring(text or "")

    local lines = {}
    local current = ""

    if width < 1 then
        return { "" }
    end

    for word in string.gmatch(text, "%S+") do
        if #word > width then
            if current ~= "" then
                table.insert(lines, current)
                current = ""
            end

            local index = 1

            while index <= #word do
                table.insert(lines, string.sub(word, index, index + width - 1))
                index = index + width
            end
        elseif current == "" then
            current = word
        elseif #current + 1 + #word <= width then
            current = current .. " " .. word
        else
            table.insert(lines, current)
            current = word
        end
    end

    if current ~= "" then
        table.insert(lines, current)
    end

    if #lines == 0 then
        table.insert(lines, "")
    end

    return lines
end

local function getApps(ctx)
    if ctx.appManager and ctx.appManager.listMetadata then
        return ctx.appManager:listMetadata()
    end

    local result = {}

    for _, appName in ipairs(ctx.appManager:list()) do
        table.insert(result, {
            id = appName,
            name = appName,
            description = "No description",
            version = "0.1.0",
            category = "uncategorized",
            author = "NovaOS",
            entry = "main.lua"
        })
    end

    return result
end

local function printWrappedValue(theme, label, value, width)
    local labelText = "  " .. label .. ": "
    local valueWidth = width - #labelText

    if valueWidth < 12 then
        valueWidth = width - 4
        writeColor("  " .. label .. ":", theme.muted)
        print()
        labelText = "    "
    end

    local lines = wrapText(value, valueWidth)

    for index, line in ipairs(lines) do
        if index == 1 then
            writeColor(labelText, theme.muted)
            printColor(line, theme.foreground)
        else
            writeColor(string.rep(" ", #labelText), theme.muted)
            printColor(line, theme.foreground)
        end
    end
end

local function printAppCard(ctx, app, index, total)
    local theme = ctx.theme
    local width = term.getSize()

    local lineWidth = width

    if lineWidth > 56 then
        lineWidth = 56
    end

    if lineWidth < 28 then
        lineWidth = 28
    end

    printColor(repeatText("-", lineWidth), theme.muted)

    writeColor(tostring(index) .. "/" .. tostring(total) .. "  ", theme.muted)
    printColor(app.name or app.id or "unknown", theme.accent2)

    printWrappedValue(theme, "id", app.id or "unknown", lineWidth)
    printWrappedValue(theme, "version", app.version or "0.1.0", lineWidth)
    printWrappedValue(theme, "category", app.category or "uncategorized", lineWidth)
    printWrappedValue(theme, "author", app.author or "NovaOS", lineWidth)
    printWrappedValue(theme, "entry", app.entry or "main.lua", lineWidth)

    writeColor("  about:", theme.muted)
    print()

    local descriptionLines = wrapText(app.description or "No description", lineWidth - 4)

    for _, line in ipairs(descriptionLines) do
        printColor("    " .. line, theme.foreground)
    end

    print()
end

function AppsCommand.run(ctx, args)
    local theme = ctx.theme
    local apps = getApps(ctx)

    term.setTextColor(theme.accent)
    print("Installed applications")
    term.setTextColor(theme.muted)
    print("----------------------")
    print()

    if #apps == 0 then
        term.setTextColor(theme.muted)
        print("(no apps installed)")
        term.setTextColor(theme.text)
        return true
    end

    for index, app in ipairs(apps) do
        printAppCard(ctx, app, index, #apps)
    end

    term.setTextColor(theme.muted)
    print("Use: open <app>")
    print("Example: open launcher")
    print("Package manager: open packages")
    term.setTextColor(theme.text)

    return true
end

return AppsCommand