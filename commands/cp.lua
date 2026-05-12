local CpCommand = {}

CpCommand.description = "Copy file or directory"
CpCommand.category = "files"
CpCommand.usage = "cp <source> <target>"
CpCommand.aliases = {
    "copy"
}
CpCommand.examples = {
    "cp notes.txt backup.txt",
    "cp \"my notes.txt\" \"my backup.txt\"",
    "cp projects projects_backup"
}

local function copyRecursive(source, target)
    if fs.isDir(source) then
        if not fs.exists(target) then
            fs.makeDir(target)
        end

        for _, item in ipairs(fs.list(source)) do
            copyRecursive(fs.combine(source, item), fs.combine(target, item))
        end

        return true
    end

    fs.copy(source, target)

    return true
end

function CpCommand.run(ctx, args)
    local sourceArg = args[2]
    local targetArg = args[3]

    if not sourceArg or not targetArg then
        return false, "Usage: cp <source> <target>"
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
        copyRecursive(source, target)
    end)

    if not ok then
        return false, "Copy failed: " .. tostring(err)
    end

    term.setTextColor(ctx.theme.success)
    print("Copied: " .. ctx.filesystem:display(source) .. " -> " .. ctx.filesystem:display(target))
    term.setTextColor(ctx.theme.text)

    return true
end

return CpCommand