local TouchCommand = {}

TouchCommand.description = "Create an empty file or update file timestamp"
TouchCommand.category = "files"
TouchCommand.usage = "touch <file>"
TouchCommand.examples = {
    "touch notes.txt",
    "touch \"my notes.txt\""
}

function TouchCommand.run(ctx, args)
    local filePath = args[2]

    if not filePath then
        return false, "Usage: touch <file>"
    end

    local resolved = ctx.filesystem:resolve(filePath)

    if fs.exists(resolved) and fs.isDir(resolved) then
        return false, "Cannot touch directory: " .. ctx.filesystem:display(resolved)
    end

    local parent = fs.getDir(resolved)

    if parent and parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end

    if not fs.exists(resolved) then
        local handle = fs.open(resolved, "w")

        if not handle then
            return false, "Cannot create file: " .. ctx.filesystem:display(resolved)
        end

        handle.write("")
        handle.close()

        term.setTextColor(ctx.theme.success)
        print("Created: " .. ctx.filesystem:display(resolved))
        term.setTextColor(ctx.theme.text)

        return true
    end

    local handle = fs.open(resolved, "a")

    if not handle then
        return false, "Cannot update file: " .. ctx.filesystem:display(resolved)
    end

    handle.close()

    term.setTextColor(ctx.theme.muted)
    print("Updated: " .. ctx.filesystem:display(resolved))
    term.setTextColor(ctx.theme.text)

    return true
end

return TouchCommand