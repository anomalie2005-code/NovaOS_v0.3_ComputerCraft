local ClearCommand = {}

ClearCommand.description = "Clear terminal screen"
ClearCommand.category = "system"
ClearCommand.usage = "clear"
ClearCommand.aliases = {
    "cls"
}
ClearCommand.examples = {
    "clear",
    "cls"
}

function ClearCommand.run(ctx, args)
    ctx.screen:clear(ctx.theme.background, ctx.theme.text)

    return true
end

return ClearCommand