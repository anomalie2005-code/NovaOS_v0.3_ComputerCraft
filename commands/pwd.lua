local PwdCommand = {}

PwdCommand.description = "Print current directory"
PwdCommand.category = "files"
PwdCommand.usage = "pwd"
PwdCommand.examples = {
    "pwd"
}

function PwdCommand.run(ctx, args)
    term.setTextColor(ctx.theme.foreground)
    print(ctx.filesystem:display())
    term.setTextColor(ctx.theme.text)

    return true
end

return PwdCommand