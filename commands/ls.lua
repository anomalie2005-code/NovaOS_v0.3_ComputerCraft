local LsCommand = {}

LsCommand.description = "List directory contents"
LsCommand.category = "files"
LsCommand.usage = "ls [directory]"
LsCommand.aliases = {
    "dir"
}
LsCommand.examples = {
    "ls",
    "ls apps",
    "ls \"my folder\""
}

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

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
end

local function formatSize(size)
    size = tonumber(size or 0) or 0

    if size < 1024 then
        return tostring(size) .. "B"
    end

    local kb = math.floor((size / 1024) * 10) / 10

    return tostring(kb) .. "KB"
end

function LsCommand.run(ctx, args)
    local theme = ctx.theme
    local target = args[2]
    local path = ctx.filesystem:resolve(target)

    if not fs.exists(path) then
        return false, "Path does not exist: " .. ctx.filesystem:display(path)
    end

    if not fs.isDir(path) then
        term.setTextColor(theme.foreground)
        print(ctx.filesystem:display(path))
        term.setTextColor(theme.text)
        return true
    end

    local items = fs.list(path)
    table.sort(items)

    term.setTextColor(theme.accent)
    print("Directory: " .. ctx.filesystem:display(path))
    term.setTextColor(theme.muted)
    print("------------------------------")

    if #items == 0 then
        term.setTextColor(theme.muted)
        print("(empty)")
        term.setTextColor(theme.text)
        return true
    end

    local width = term.getSize()
    local nameWidth = math.max(16, width - 20)

    for _, item in ipairs(items) do
        local fullPath = fs.combine(path, item)

        if fs.isDir(fullPath) then
            term.setTextColor(theme.accent2)
            write("[DIR]  ")
            term.setTextColor(theme.foreground)
            print(cutText(item .. "/", width - 8))
        else
            local size = formatSize(fs.getSize(fullPath))

            term.setTextColor(theme.muted)
            write("[FILE] ")
            term.setTextColor(theme.foreground)
            write(padRight(cutText(item, nameWidth), nameWidth))
            term.setTextColor(theme.muted)
            print(" " .. size)
        end
    end

    term.setTextColor(theme.text)

    return true
end

return LsCommand