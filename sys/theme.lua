local Theme = {}

Theme.themes = {
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

function Theme.exists(name)
    return Theme.themes[name] ~= nil
end

function Theme.get(name)
    if Theme.themes[name] then
        return Theme.themes[name]
    end

    return Theme.themes.cyber
end

function Theme.list()
    local names = {}

    for name in pairs(Theme.themes) do
        table.insert(names, name)
    end

    table.sort(names)

    return names
end

return Theme
