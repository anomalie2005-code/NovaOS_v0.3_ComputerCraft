local ReloadCommand = {}

ReloadCommand.description = "Reload NovaOS command registry"
ReloadCommand.category = "system"
ReloadCommand.usage = "reload"
ReloadCommand.examples = {
    "reload"
}

function ReloadCommand.run(ctx, args)
    local ok, err = pcall(function()
        ctx.registry:reload(ctx)
    end)

    if not ok then
        return false, "Reload failed: " .. tostring(err)
    end

    term.setTextColor(ctx.theme.success)
    print("Commands reloaded.")
    term.setTextColor(ctx.theme.text)

    if ctx.logger then
        ctx.logger:info("Commands reloaded")
    end

    return true
end

return ReloadCommand