local ThemeCommand = {}

ThemeCommand.description = "Change or show NovaOS theme"
ThemeCommand.category = "system"
ThemeCommand.usage = "theme [name]"
ThemeCommand.aliases = {}
ThemeCommand.examples = {
    "theme",
    "theme amber",
    "theme cyber",
    "theme arch"
}

local function printColor(text, color)
    if color then
        term.setTextColor(color)
    end

    print(tostring(text or ""))
end

local function writeColor(text, color)
    if color then
        term.setTextColor(color)
    end

    write(tostring(text or ""))
end

local function safeLoadConfig()
    local path = "sys/config.lua"

    if fs.exists(path) and not fs.isDir(path) then
        local ok, result = pcall(dofile, path)

        if ok and type(result) == "table" then
            return result
        end
    end

    return {}
end

local function saveConfig(config)
    local path = "data/settings.lua"

    if not fs.exists("data") then
        fs.makeDir("data")
    end

    local handle = fs.open(path, "w")

    if not handle then
        return false, "Cannot open settings file for writing."
    end

    handle.write("return {\n")

    for key, value in pairs(config or {}) do
        if type(value) == "string" then
            handle.write("    " .. tostring(key) .. " = \"" .. tostring(value) .. "\",\n")
        elseif type(value) == "number" or type(value) == "boolean" then
            handle.write("    " .. tostring(key) .. " = " .. tostring(value) .. ",\n")
        end
    end

    handle.write("}\n")
    handle.close()

    return true
end

local function loadSavedSettings()
    local path = "data/settings.lua"

    if fs.exists(path) and not fs.isDir(path) then
        local ok, result = pcall(dofile, path)

        if ok and type(result) == "table" then
            return result
        end
    end

    return {}
end

local function getAvailableThemes()
    return {
        cyber = {
            name = "cyber",
            background = colors.black,
            text = colors.white,
            foreground = colors.white,
            muted = colors.gray,
            accent = colors.cyan,
            accent2 = colors.lime,
            warning = colors.yellow,
            error = colors.red,
            success = colors.lime,
            status = colors.gray
        },

        amber = {
            name = "amber",
            background = colors.black,
            text = colors.orange,
            foreground = colors.orange,
            muted = colors.brown,
            accent = colors.orange,
            accent2 = colors.yellow,
            warning = colors.yellow,
            error = colors.red,
            success = colors.lime,
            status = colors.brown
        },

        arch = {
            name = "arch",
            background = colors.black,
            text = colors.lightGray,
            foreground = colors.lightGray,
            muted = colors.gray,
            accent = colors.cyan,
            accent2 = colors.blue,
            warning = colors.orange,
            error = colors.red,
            success = colors.lime,
            status = colors.gray
        },

        nova = {
            name = "nova",
            background = colors.black,
            text = colors.white,
            foreground = colors.white,
            muted = colors.gray,
            accent = colors.lightBlue,
            accent2 = colors.lime,
            warning = colors.yellow,
            error = colors.red,
            success = colors.lime,
            status = colors.gray
        }
    }
end

local function applyThemeToContext(ctx, themeName)
    local themes = getAvailableThemes()
    local selected = themes[themeName]

    if not selected then
        return false, "Unknown theme: " .. tostring(themeName)
    end

    ctx.theme = selected

    if ctx.config then
        ctx.config.theme = themeName
    end

    term.setBackgroundColor(selected.background)
    term.setTextColor(selected.text)
    term.clear()
    term.setCursorPos(1, 1)

    return true
end

local function saveThemeName(ctx, themeName)
    local settings = loadSavedSettings()

    settings.theme = themeName

    if ctx.config then
        for key, value in pairs(ctx.config) do
            if settings[key] == nil then
                settings[key] = value
            end
        end

        settings.theme = themeName
    end

    return saveConfig(settings)
end

local function showThemeList(ctx)
    local theme = ctx.theme or {}
    local themes = getAvailableThemes()

    local current = "unknown"

    if ctx.config and ctx.config.theme then
        current = ctx.config.theme
    elseif theme.name then
        current = theme.name
    end

    printColor("Current theme: " .. tostring(current), theme.accent or colors.orange)
    printColor("Available themes:", theme.accent2 or colors.yellow)

    local names = {}

    for name, _ in pairs(themes) do
        table.insert(names, name)
    end

    table.sort(names)

    for _, name in ipairs(names) do
        if name == current then
            writeColor("  * ", theme.success or colors.lime)
        else
            writeColor("    ", theme.muted or colors.gray)
        end

        printColor(name, theme.foreground or colors.white)
    end

    print()
    printColor("Use: theme <name>", theme.muted or colors.gray)
    printColor("Example: theme amber", theme.muted or colors.gray)

    return true
end

function ThemeCommand.run(ctx, args)
    args = args or {}

    local themeName = args[2]

    if not themeName or themeName == "" then
        return showThemeList(ctx)
    end

    themeName = string.lower(tostring(themeName))

    local ok, message = applyThemeToContext(ctx, themeName)

    if not ok then
        return false, message
    end

    local savedOk, savedMessage = saveThemeName(ctx, themeName)

    if not savedOk then
        printColor("Theme changed to: " .. themeName, ctx.theme.success)
        return false, savedMessage
    end

    printColor("Theme changed to: " .. themeName, ctx.theme.success)
    printColor("Config saved.", ctx.theme.muted)

    if ctx.logger then
        ctx.logger:info("Theme changed to: " .. themeName)
    end

    return true
end

return ThemeCommand