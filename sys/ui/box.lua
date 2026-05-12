local Box = {}

local asciiChars = {
    topLeft = "+",
    topRight = "+",
    bottomLeft = "+",
    bottomRight = "+",
    horizontal = "-",
    vertical = "|",
    leftJoin = "+",
    rightJoin = "+"
}

local unicodeChars = {
    topLeft = "┌",
    topRight = "┐",
    bottomLeft = "└",
    bottomRight = "┘",
    horizontal = "─",
    vertical = "│",
    leftJoin = "├",
    rightJoin = "┤"
}

local function getChars(ctx)
    if ctx and ctx.config and ctx.config.boxStyle == "unicode" then
        return unicodeChars
    end

    return asciiChars
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
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

function Box.writeAt(x, y, text, foreground, background)
    local width, height = term.getSize()

    if x < 1 or y < 1 or x > width or y > height then
        return
    end

    if background then
        term.setBackgroundColor(background)
    end

    if foreground then
        term.setTextColor(foreground)
    end

    term.setCursorPos(x, y)
    term.write(tostring(text or ""))
end

function Box.clearArea(ctx, x, y, width, height, background)
    local theme = ctx.theme
    local bg = background or theme.background

    for row = y, y + height - 1 do
        Box.writeAt(x, row, string.rep(" ", width), theme.text, bg)
    end
end

function Box.draw(ctx, x, y, width, height, title)
    local theme = ctx.theme
    local chars = getChars(ctx)

    width = math.max(width, 4)
    height = math.max(height, 3)

    local screenWidth, screenHeight = term.getSize()

    x = clamp(x, 1, screenWidth)
    y = clamp(y, 1, screenHeight)

    if x + width - 1 > screenWidth then
        width = screenWidth - x + 1
    end

    if y + height - 1 > screenHeight then
        height = screenHeight - y + 1
    end

    if width < 4 or height < 3 then
        return
    end

    local horizontal = string.rep(chars.horizontal, width - 2)

    Box.writeAt(x, y, chars.topLeft .. horizontal .. chars.topRight, theme.muted, theme.background)

    for row = y + 1, y + height - 2 do
        Box.writeAt(x, row, chars.vertical, theme.muted, theme.background)
        Box.writeAt(x + 1, row, string.rep(" ", width - 2), theme.text, theme.background)
        Box.writeAt(x + width - 1, row, chars.vertical, theme.muted, theme.background)
    end

    Box.writeAt(x, y + height - 1, chars.bottomLeft .. horizontal .. chars.bottomRight, theme.muted, theme.background)

    if title and title ~= "" then
        local safeTitle = " " .. cutText(title, width - 6) .. " "
        Box.writeAt(x + 2, y, safeTitle, theme.accent, theme.background)
    end
end

function Box.drawSeparator(ctx, x, y, width)
    local theme = ctx.theme
    local chars = getChars(ctx)

    width = math.max(width, 4)

    Box.writeAt(
        x,
        y,
        chars.leftJoin .. string.rep(chars.horizontal, width - 2) .. chars.rightJoin,
        theme.muted,
        theme.background
    )
end

function Box.writeInside(ctx, x, y, width, line, text, foreground, background)
    local theme = ctx.theme
    local value = cutText(text or "", width - 4)

    Box.writeAt(
        x + 2,
        y + line,
        value .. string.rep(" ", math.max(0, width - 4 - #value)),
        foreground or theme.foreground,
        background or theme.background
    )
end

function Box.footer(ctx, x, y, width, height, text)
    local theme = ctx.theme
    local footerY = y + height - 2
    local value = cutText(text or "", width - 4)

    Box.writeAt(
        x + 2,
        footerY,
        value .. string.rep(" ", math.max(0, width - 4 - #value)),
        theme.muted,
        theme.background
    )
end

function Box.message(ctx, title, message, color)
    local theme = ctx.theme
    local width, height = term.getSize()

    local boxWidth = math.min(width - 4, 42)
    local boxHeight = 7
    local x = math.floor((width - boxWidth) / 2) + 1
    local y = math.floor((height - boxHeight) / 2) + 1

    Box.draw(ctx, x, y, boxWidth, boxHeight, title)
    Box.writeInside(ctx, x, y, boxWidth, 2, message, color or theme.foreground)
    Box.footer(ctx, x, y, boxWidth, boxHeight, "Press any key...")

    os.pullEvent("key")
end

return Box