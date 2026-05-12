local CatCommand = {}

CatCommand.description = "Print file content"
CatCommand.category = "files"
CatCommand.usage = "cat <file>"
CatCommand.examples = {
    "cat notes.txt",
    "cat \"my notes.txt\""
}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if maxLength <= 0 then
        return ""
    end

    if #text <= maxLength then
        return text
    end

    return string.sub(text, 1, maxLength)
end

function CatCommand.run(ctx, args)
    local filePath = args[2]

    if not filePath then
        return false, "Usage: cat <file>"
    end

    local resolved = ctx.filesystem:resolve(filePath)

    if not fs.exists(resolved) then
        return false, "File does not exist: " .. ctx.filesystem:display(resolved)
    end

    if fs.isDir(resolved) then
        return false, "Cannot cat directory: " .. ctx.filesystem:display(resolved)
    end

    local handle = fs.open(resolved, "r")

    if not handle then
        return false, "Cannot open file: " .. ctx.filesystem:display(resolved)
    end

    local content = handle.readAll() or ""
    handle.close()

    local width = term.getSize()

    term.setTextColor(ctx.theme.accent)
    print("File: " .. ctx.filesystem:display(resolved))
    term.setTextColor(ctx.theme.muted)
    print(string.rep("-", math.min(width, 32)))

    term.setTextColor(ctx.theme.foreground)

    if content == "" then
        term.setTextColor(ctx.theme.muted)
        print("(empty file)")
    else
        for line in string.gmatch(content .. "\n", "(.-)\n") do
            print(cutText(line, width))
        end
    end

    term.setTextColor(ctx.theme.text)

    return true
end

return CatCommand