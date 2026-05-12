local Class = require("sys.class")
local SystemInfo = require("sys.services.system_info")

local Prompt = Class.create()

function Prompt:init()
end

function Prompt:draw(ctx)
    local theme = ctx.theme
    local username = ctx.config.username
    local hostname = ctx.config.hostname or SystemInfo.getComputerLabel()
    local path = ctx.filesystem:display()

    term.setTextColor(theme.accent)
    write(username)

    term.setTextColor(theme.muted)
    write("@")

    term.setTextColor(theme.accent2)
    write(hostname)

    term.setTextColor(theme.muted)
    write(" ")

    term.setTextColor(theme.foreground)
    write(path)

    term.setTextColor(theme.muted)
    write("\n")

    term.setTextColor(theme.accent)
    write("> ")

    term.setTextColor(theme.text)
end

return Prompt
