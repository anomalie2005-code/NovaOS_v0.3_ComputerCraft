local RmCommand = {}

RmCommand.description = "Remove file or directory"
RmCommand.category = "files"
RmCommand.usage = "rm [-r] [-f] <path>"
RmCommand.aliases = {
    "del"
}
RmCommand.examples = {
    "rm notes.txt",
    "rm -r projects",
    "rm -f missing.txt",
    "rm -r \"old folder\""
}

local function parseArgs(args)
    local options = {
        recursive = false,
        force = false,
        path = nil
    }

    for index = 2, #args do
        local arg = args[index]

        if arg == "-r" or arg == "--recursive" then
            options.recursive = true
        elseif arg == "-f" or arg == "--force" then
            options.force = true
        elseif arg == "-rf" or arg == "-fr" then
            options.recursive = true
            options.force = true
        else
            options.path = arg
        end
    end

    return options
end

local function isProtectedPath(path)
    path = tostring(path or "")

    if path == "" then
        return true
    end

    local protected = {
        "sys",
        "commands",
        "apps",
        "data",
        "home",
        "lib",
        "startup.lua"
    }

    for _, item in ipairs(protected) do
        if path == item then
            return true
        end
    end

    return false
end

function RmCommand.run(ctx, args)
    local options = parseArgs(args)

    if not options.path then
        return false, "Usage: rm [-r] [-f] <path>"
    end

    local resolved = ctx.filesystem:resolve(options.path)

    if isProtectedPath(resolved) and not options.force then
        return false, "Protected path. Use -f only if you really know what you are doing: " .. ctx.filesystem:display(resolved)
    end

    if not fs.exists(resolved) then
        if options.force then
            term.setTextColor(ctx.theme.muted)
            print("Skipped missing path: " .. ctx.filesystem:display(resolved))
            term.setTextColor(ctx.theme.text)
            return true
        end

        return false, "Path does not exist: " .. ctx.filesystem:display(resolved)
    end

    if fs.isDir(resolved) and not options.recursive then
        return false, "Cannot remove directory without -r: " .. ctx.filesystem:display(resolved)
    end

    fs.delete(resolved)

    term.setTextColor(ctx.theme.success)
    print("Removed: " .. ctx.filesystem:display(resolved))
    term.setTextColor(ctx.theme.text)

    return true
end

return RmCommand