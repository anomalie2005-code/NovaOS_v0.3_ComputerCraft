local MkdirCommand = {}

MkdirCommand.description = "Create a directory"
MkdirCommand.category = "files"
MkdirCommand.usage = "mkdir <directory>"
MkdirCommand.examples = {
    "mkdir projects",
    "mkdir \"new folder\"",
    "mkdir projects/demo"
}

function MkdirCommand.run(ctx, args)
    local dirPath = args[2]

    if not dirPath then
        return false, "Usage: mkdir <directory>"
    end

    local resolved = ctx.filesystem:resolve(dirPath)

    if fs.exists(resolved) then
        if fs.isDir(resolved) then
            return false, "Directory already exists: " .. ctx.filesystem:display(resolved)
        end

        return false, "File already exists: " .. ctx.filesystem:display(resolved)
    end

    fs.makeDir(resolved)

    term.setTextColor(ctx.theme.success)
    print("Created directory: " .. ctx.filesystem:display(resolved))
    term.setTextColor(ctx.theme.text)

    return true
end

return MkdirCommand