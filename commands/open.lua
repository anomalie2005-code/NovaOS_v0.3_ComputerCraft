local OpenCommand = {}

OpenCommand.description = "Open an installed application"
OpenCommand.category = "apps"
OpenCommand.usage = "open <app>"
OpenCommand.examples = {
    "open launcher",
    "open files",
    "open settings",
    "open monitor"
}

function OpenCommand.run(ctx, args)
    local appName = args[2]

    if not appName then
        return false, "Usage: open <app>"
    end

    local ok, result = ctx.appManager:launch(appName, args)

    if not ok then
        return false, result
    end

    return true
end

return OpenCommand