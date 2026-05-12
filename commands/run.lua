local RunCommand = {}

RunCommand.description = "Run a Lua program"
RunCommand.category = "system"
RunCommand.usage = "run <file>"
RunCommand.examples = {
    "run test.lua",
    "run apps/demo/main.lua",
    "run \"my script.lua\""
}

function RunCommand.run(ctx, args)
    local filePath = args[2]

    if not filePath then
        return false, "Usage: run <file>"
    end

    local resolved = ctx.filesystem:resolve(filePath)

    if not fs.exists(resolved) then
        return false, "File does not exist: " .. ctx.filesystem:display(resolved)
    end

    if fs.isDir(resolved) then
        return false, "Cannot run directory: " .. ctx.filesystem:display(resolved)
    end

    term.setTextColor(ctx.theme.muted)
    print("Running: " .. ctx.filesystem:display(resolved))
    term.setTextColor(ctx.theme.text)

    if ctx.logger then
        ctx.logger:info("Running file: " .. resolved)
    end

    local ok, result = pcall(dofile, resolved)

    if not ok then
        if ctx.logger then
            ctx.logger:error("Run failed " .. resolved .. ": " .. tostring(result))
        end

        return false, "Runtime error: " .. tostring(result)
    end

    return true
end

return RunCommand