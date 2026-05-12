local EditCommand = {}

EditCommand.description = "Open NovaOS editor"
EditCommand.category = "apps"
EditCommand.usage = "edit [file]"
EditCommand.examples = {
    "edit",
    "edit notes.txt",
    "edit \"my notes.txt\""
}

function EditCommand.run(ctx, args)
    local filePath = args[2]
    local ok
    local result

    if not filePath then
        ok, result = ctx.appManager:launch("editor", { "open", "editor" })
    else
        ok, result = ctx.appManager:launch("editor", { "open", "editor", filePath })
    end

    if not ok then
        return false, result
    end

    return true
end

return EditCommand