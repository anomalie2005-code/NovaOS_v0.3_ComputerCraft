local ShutdownCommand = {}

ShutdownCommand.description = "Shut down this ComputerCraft computer"

ShutdownCommand.category = "power"

ShutdownCommand.usage = "shutdown"

ShutdownCommand.aliases = {

    "poweroff",

    "halt"

}

ShutdownCommand.examples = {

    "shutdown",

    "poweroff",

    "halt"

}

function ShutdownCommand.run(ctx, args)

    term.setTextColor(ctx.theme.warning)

    print("Shutting down NovaOS...")

    term.setTextColor(ctx.theme.text)

    if ctx.logger then

        ctx.logger:info("Shutdown requested")

    end

    sleep(0.4)

    os.shutdown()

    return true

end

return ShutdownCommand