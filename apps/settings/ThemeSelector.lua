local ThemeSelector = {}

ThemeSelector.themes = {
    cyber = {
        name = "cyber",
        background = colors.black,
        foreground = colors.lightGray,
        text = colors.white,
        muted = colors.gray,
        accent = colors.cyan,
        accent2 = colors.lime,
        warning = colors.orange,
        error = colors.red,
        success = colors.lime,
        panel = colors.gray,
        panelText = colors.white
    },

    amber = {
        name = "amber",
        background = colors.black,
        foreground = colors.orange,
        text = colors.yellow,
        muted = colors.brown,
        accent = colors.orange,
        accent2 = colors.yellow,
        warning = colors.yellow,
        error = colors.red,
        success = colors.lime,
        panel = colors.brown,
        panelText = colors.yellow
    },

    arch = {
        name = "arch",
        background = colors.black,
        foreground = colors.lightGray,
        text = colors.white,
        muted = colors.gray,
        accent = colors.cyan,
        accent2 = colors.blue,
        warning = colors.orange,
        error = colors.red,
        success = colors.lime,
        panel = colors.gray,
        panelText = colors.white
    }
}

ThemeSelector.order = {
    "cyber",
    "amber",
    "arch"
}

function ThemeSelector.exists(name)
    return ThemeSelector.themes[name] ~= nil
end

function ThemeSelector.get(name)
    if ThemeSelector.themes[name] then
        return ThemeSelector.themes[name]
    end

    return ThemeSelector.themes.cyber
end

function ThemeSelector.next(currentTheme)
    local index = 1

    for i, name in ipairs(ThemeSelector.order) do
        if name == currentTheme then
            index = i
            break
        end
    end

    index = index + 1

    if index > #ThemeSelector.order then
        index = 1
    end

    return ThemeSelector.order[index]
end

function ThemeSelector.list()
    local result = {}

    for _, name in ipairs(ThemeSelector.order) do
        table.insert(result, name)
    end

    return result
end

return ThemeSelector