local AboutApp = {}

AboutApp.name = "About"
AboutApp.description = "Information about NovaOS"

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

local function draw(ctx)
    local Box = ctx.ui.Box
    local StatusBar = ctx.ui.StatusBar
    local theme = ctx.theme

    ctx.screen:clear(theme.background, theme.text)

    local width, height = term.getSize()
    local boxX = 2
    local boxY = 2
    local boxW = width - 2
    local boxH = height - 3

    Box.draw(ctx, boxX, boxY, boxW, boxH, "About NovaOS")

    Box.writeInside(ctx, boxX, boxY, boxW, 2, "NovaOS " .. ctx.config.version, theme.accent)
    Box.writeInside(ctx, boxX, boxY, boxW, 3, "Advanced terminal environment for ComputerCraft.", theme.foreground)

    Box.writeInside(ctx, boxX, boxY, boxW, 5, "System name: " .. ctx.config.systemName, theme.foreground)
    Box.writeInside(ctx, boxX, boxY, boxW, 6, "Shell:       " .. ctx.config.shellName, theme.foreground)
    Box.writeInside(ctx, boxX, boxY, boxW, 7, "Theme:       " .. ctx.config.theme, theme.foreground)
    Box.writeInside(ctx, boxX, boxY, boxW, 8, "User:        " .. ctx.config.username, theme.foreground)
    Box.writeInside(ctx, boxX, boxY, boxW, 9, "Host:        " .. getComputerName(), theme.foreground)
    Box.writeInside(ctx, boxX, boxY, boxW, 10, "Computer ID: " .. tostring(os.getComputerID()), theme.foreground)
    Box.writeInside(ctx, boxX, boxY, boxW, 11, "Uptime:      " .. getUptime(), theme.foreground)

    Box.writeInside(ctx, boxX, boxY, boxW, 13, "Interface style:", theme.accent2)
    Box.writeInside(ctx, boxX, boxY, boxW, 14, "Terminal-first, dark, minimal, Linux-inspired TUI.", theme.foreground)

    Box.footer(ctx, boxX, boxY, boxW, boxH, "Q / Backspace / Mouse click: return")
    StatusBar.drawBottom(ctx, "NovaOS / About", "click anywhere to close")
end

function AboutApp.run(ctx, args)
    draw(ctx)

    while true do
        local event, a = os.pullEvent()

        if event == "key" then
            if a == keys.q or a == keys.backspace or a == keys.enter or a == keys.escape then
                return true
            end
        elseif event == "mouse_click" then
            return true
        end
    end
end

return AboutApp