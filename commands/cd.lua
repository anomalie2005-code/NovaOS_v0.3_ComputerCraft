local CdCommand = {}

CdCommand.description = "Change current directory"
CdCommand.category = "files"
CdCommand.usage = "cd <directory>"
CdCommand.examples = {
    "cd apps",
    "cd ..",
    "cd ~",
    "cd \"my folder\""
}

function CdCommand.run(ctx, args)
    local target = args[2] or "~"

    local ok, message = ctx.filesystem:changeDir(target)

    if not ok then
        return false, message
    end

    term.setTextColor(ctx.theme.muted)
    print("Directory: " .. ctx.filesystem:display())
    term.setTextColor(ctx.theme.text)

    return true
end

return CdCommand