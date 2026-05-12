local MvCommand = {}

MvCommand.description = "Move or rename file or directory"
MvCommand.category = "files"
MvCommand.usage = "mv <source> <target>"
MvCommand.aliases = {
    "move",
    "ren",
    "rename"
}
MvCommand.examples = {
    "mv old.txt new.txt",
    "mv notes.txt projects/notes.txt",
    "mv \"old name.txt\" \"new name.txt\""
}

function MvCommand.run(ctx, args)
    local sourceArg = args[2]
    local targetArg = args[3]

    if not sourceArg or not targetArg then
        return false, "Usage: mv <source> <target>"
    end

    local source = ctx.filesystem:resolve(sourceArg)
    local target = ctx.filesystem:resolve(targetArg)

    if not fs.exists(source) then
        return false, "Source does not exist: " .. ctx.filesystem:display(source)
    end

    if fs.exists(target) and fs.isDir(target) then
        target = fs.combine(target, fs.getName(source))
    end

    if fs.exists(target) then
        return false, "Target already exists: " .. ctx.filesystem:display(target)
    end

    local parent = fs.getDir(target)

    if parent and parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end

    local ok, err = pcall(function()
        fs.move(source, target)
    end)

    if not ok then
        return false, "Move failed: " .. tostring(err)
    end

    term.setTextColor(ctx.theme.success)
    print("Moved: " .. ctx.filesystem:display(source) .. " -> " .. ctx.filesystem:display(target))
    term.setTextColor(ctx.theme.text)

    return true
end

return MvCommand