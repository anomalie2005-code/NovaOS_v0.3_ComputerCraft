local RebootCommand = {}

RebootCommand.description = "Reboot this ComputerCraft computer"
RebootCommand.category = "power"
RebootCommand.usage = "reboot"
RebootCommand.aliases = {
    "restart"
}
RebootCommand.examples = {
    "reboot",
    "restart"
}

function RebootCommand.run(ctx, args)
    term.setTextColor(ctx.theme.warning)
    print("Rebooting NovaOS...")
    term.setTextColor(ctx.theme.text)

    if ctx.logger then
        ctx.logger:info("Reboot requested")
    end

    sleep(0.4)
    os.reboot()

    return true
end

return RebootCommand