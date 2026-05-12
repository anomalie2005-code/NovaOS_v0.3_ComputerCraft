local HelpCommand = {}

HelpCommand.description = "Show command help"
HelpCommand.category = "system"
HelpCommand.usage = "help [command]"
HelpCommand.examples = {
    "help",
    "help open",
    "help edit",
    "help rm"
}

local fallbackHelp = {
    apps = {
        category = "apps",
        usage = "apps",
        description = "List installed applications",
        examples = { "apps" }
    },

    cat = {
        category = "files",
        usage = "cat <file>",
        description = "Print file content",
        examples = { "cat notes.txt", "cat \"my notes.txt\"" }
    },

    cd = {
        category = "files",
        usage = "cd <directory>",
        description = "Change current directory",
        examples = { "cd projects", "cd ..", "cd ~" }
    },

    clear = {
        category = "system",
        usage = "clear",
        description = "Clear terminal screen",
        examples = { "clear" }
    },

    cp = {
        category = "files",
        usage = "cp <source> <target>",
        description = "Copy file or directory",
        examples = { "cp notes.txt backup.txt", "cp projects projects_backup" }
    },

    edit = {
        category = "apps",
        usage = "edit [file]",
        description = "Open NovaOS editor",
        examples = { "edit", "edit notes.txt", "edit \"my notes.txt\"" }
    },

    fetch = {
        category = "system",
        usage = "fetch",
        description = "Show NovaOS system information",
        examples = { "fetch" }
    },

    help = {
        category = "system",
        usage = "help [command]",
        description = "Show command list or detailed command help",
        examples = { "help", "help open", "help edit" }
    },

    log = {
        category = "system",
        usage = "log [number]",
        description = "Show recent system log lines",
        examples = { "log", "log 20" }
    },

    ls = {
        category = "files",
        usage = "ls [directory]",
        description = "List directory contents",
        examples = { "ls", "ls projects" }
    },

    mkdir = {
        category = "files",
        usage = "mkdir <directory>",
        description = "Create a directory",
        examples = { "mkdir projects", "mkdir \"new folder\"" }
    },

    mv = {
        category = "files",
        usage = "mv <source> <target>",
        description = "Move or rename file or directory",
        examples = { "mv old.txt new.txt", "mv notes.txt projects/notes.txt" }
    },

    open = {
        category = "apps",
        usage = "open <app>",
        description = "Open an installed application",
        examples = { "open launcher", "open files", "open settings", "open monitor" }
    },

    peripherals = {
        category = "system",
        usage = "peripherals",
        description = "List connected peripherals",
        examples = { "peripherals" }
    },

    pwd = {
        category = "files",
        usage = "pwd",
        description = "Print current directory",
        examples = { "pwd" }
    },

    reboot = {
        category = "power",
        usage = "reboot",
        description = "Reboot computer",
        examples = { "reboot" }
    },

    reload = {
        category = "system",
        usage = "reload",
        description = "Reload command registry",
        examples = { "reload" }
    },

    rm = {
        category = "files",
        usage = "rm <path> [-f|-r]",
        description = "Remove file or directory",
        examples = { "rm notes.txt", "rm -r projects", "rm -f missing.txt" }
    },

    run = {
        category = "system",
        usage = "run <file>",
        description = "Run a Lua program",
        examples = { "run test.lua", "run apps/demo/main.lua" }
    },

    shutdown = {
        category = "power",
        usage = "shutdown",
        description = "Shut down computer",
        examples = { "shutdown" }
    },

    theme = {
        category = "system",
        usage = "theme [name]",
        description = "Show or change current theme",
        examples = { "theme", "theme cyber", "theme amber", "theme arch" }
    },

    touch = {
        category = "files",
        usage = "touch <file>",
        description = "Create an empty file",
        examples = { "touch notes.txt", "touch \"my notes.txt\"" }
    }
}

local categoryOrder = {
    "apps",
    "files",
    "system",
    "power",
    "general"
}

local function writeColor(text, color)
    term.setTextColor(color)
    write(tostring(text or ""))
end

local function printColor(text, color)
    term.setTextColor(color)
    print(tostring(text or ""))
end

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
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

local function mergeCommandMetadata(commandName, command)
    local fallback = fallbackHelp[commandName] or {}

    return {
        id = commandName,
        name = command.name or commandName,
        description = command.description or fallback.description or "No description",
        category = command.category or fallback.category or "general",
        usage = command.usage or fallback.usage or commandName,
        examples = command.examples or fallback.examples or {},
        aliases = command.aliases or fallback.aliases or {}
    }
end

local function getCommands(ctx)
    local result = {}
    local rawCommands = ctx.registry:list()

    for _, item in ipairs(rawCommands) do
        local command = ctx.registry:get(item.id or item.name)

        if command then
            table.insert(result, mergeCommandMetadata(item.id or item.name, command))
        else
            table.insert(result, item)
        end
    end

    table.sort(result, function(a, b)
        local categoryA = tostring(a.category or "general")
        local categoryB = tostring(b.category or "general")

        if categoryA == categoryB then
            return tostring(a.name):lower() < tostring(b.name):lower()
        end

        return categoryA < categoryB
    end)

    return result
end

local function hasCategory(commands, category)
    for _, command in ipairs(commands) do
        if command.category == category then
            return true
        end
    end

    return false
end

local function printCommandLine(ctx, command, nameWidth)
    local theme = ctx.theme
    local width = term.getSize()

    local prefix = "  " .. padRight(command.name or command.id, nameWidth)
    local descriptionWidth = width - #prefix - 2

    if descriptionWidth < 12 then
        descriptionWidth = 12
    end

    local lines = wrapText(command.description or "No description", descriptionWidth)

    writeColor(prefix, theme.accent2)
    printColor(lines[1], theme.foreground)

    for index = 2, #lines do
        writeColor(string.rep(" ", #prefix), theme.accent2)
        printColor(lines[index], theme.foreground)
    end
end

local function printGeneralHelp(ctx)
    local theme = ctx.theme
    local commands = getCommands(ctx)

    term.setTextColor(theme.accent)
    print("NovaOS help")
    term.setTextColor(theme.muted)
    print("-----------")
    print()

    printColor("Use: help <command>", theme.muted)
    printColor("Example: help open", theme.muted)
    print()

    local printed = {}

    for _, category in ipairs(categoryOrder) do
        if hasCategory(commands, category) then
            printed[category] = true

            printColor(category .. ":", theme.accent)

            for _, command in ipairs(commands) do
                if command.category == category then
                    printCommandLine(ctx, command, 13)
                end
            end

            print()
        end
    end

    for _, command in ipairs(commands) do
        local category = command.category or "general"

        if not printed[category] then
            printed[category] = true

            printColor(category .. ":", theme.accent)

            for _, item in ipairs(commands) do
                if item.category == category then
                    printCommandLine(ctx, item, 13)
                end
            end

            print()
        end
    end

    term.setTextColor(theme.text)
end

local function printDetailedHelp(ctx, commandName)
    local theme = ctx.theme
    local command = ctx.registry:get(commandName)

    if not command then
        printColor("Unknown command: " .. tostring(commandName), theme.error)
        printColor("Use: help", theme.muted)
        term.setTextColor(theme.text)
        return false
    end

    local metadata = mergeCommandMetadata(commandName, command)
    local width = term.getSize()
    local wrapWidth = width - 4

    if wrapWidth < 20 then
        wrapWidth = width
    end

    term.setTextColor(theme.accent)
    print(metadata.name)
    term.setTextColor(theme.muted)
    print(string.rep("-", math.min(width, #metadata.name + 8)))
    print()

    printColor("Description:", theme.accent2)

    for _, line in ipairs(wrapText(metadata.description, wrapWidth)) do
        printColor("  " .. line, theme.foreground)
    end

    print()

    writeColor("Usage: ", theme.accent2)
    printColor(metadata.usage, theme.foreground)

    writeColor("Category: ", theme.accent2)
    printColor(metadata.category or "general", theme.foreground)

    if metadata.aliases and #metadata.aliases > 0 then
        writeColor("Aliases: ", theme.accent2)
        printColor(table.concat(metadata.aliases, ", "), theme.foreground)
    end

    if metadata.examples and #metadata.examples > 0 then
        print()
        printColor("Examples:", theme.accent2)

        for _, example in ipairs(metadata.examples) do
            printColor("  " .. example, theme.foreground)
        end
    end

    term.setTextColor(theme.text)

    return true
end

function HelpCommand.run(ctx, args)
    local commandName = args[2]

    if commandName and commandName ~= "" then
        return printDetailedHelp(ctx, commandName)
    end

    printGeneralHelp(ctx)

    return true
end

return HelpCommand