local StatusBar = {}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if #text <= maxLength then
        return text
    end

    if maxLength <= 3 then
        return string.sub(text, 1, maxLength)
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

function StatusBar.drawTop(ctx, leftText, rightText)
    local theme = ctx.theme
    local width = term.getSize()

    leftText = tostring(leftText or "")
    rightText = tostring(rightText or "")

    local space = width - #leftText - #rightText

    if space < 1 then
        leftText = cutText(leftText, width - #rightText - 1)
        space = width - #leftText - #rightText
    end

    if space < 1 then
        rightText = ""
        space = width - #leftText
    end

    term.setCursorPos(1, 1)
    term.setBackgroundColor(theme.panel or colors.gray)
    term.setTextColor(theme.panelText or colors.white)
    term.write(leftText .. string.rep(" ", space) .. rightText)
    term.setBackgroundColor(theme.background)
    term.setTextColor(theme.text)
end

function StatusBar.drawBottom(ctx, leftText, rightText)
    local theme = ctx.theme
    local width, height = term.getSize()

    leftText = tostring(leftText or "")
    rightText = tostring(rightText or "")

    local space = width - #leftText - #rightText

    if space < 1 then
        leftText = cutText(leftText, width - #rightText - 1)
        space = width - #leftText - #rightText
    end

    if space < 1 then
        rightText = ""
        space = width - #leftText
    end

    term.setCursorPos(1, height)
    term.setBackgroundColor(theme.panel or colors.gray)
    term.setTextColor(theme.panelText or colors.white)
    term.write(leftText .. string.rep(" ", space) .. rightText)
    term.setBackgroundColor(theme.background)
    term.setTextColor(theme.text)
end

return StatusBar
