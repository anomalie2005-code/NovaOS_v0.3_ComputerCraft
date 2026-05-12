local Class = require("sys.class")
local TerminalBuffer = require("sys.terminal_buffer")
local TerminalRenderer = require("sys.terminal_renderer")
local TerminalInput = require("sys.terminal_input")

local Terminal = Class.create()

local FULLSCREEN_COMMANDS = {
    open = true,
    edit = true
}

local DIRECT_COMMANDS = {
    reboot = true,
    restart = true,
    shutdown = true,
    poweroff = true,
    halt = true
}

local function getFirstWord(input)
    input = tostring(input or "")

    local word = string.match(input, "^(%S+)")

    return word or ""
end

function Terminal:init(ctx)
    self.ctx = ctx
    self.running = false

    self.buffer = TerminalBuffer.new({
        maxLines = 700
    })

    self.renderer = TerminalRenderer.new({
        ctx = ctx,
        buffer = self.buffer
    })

    self.input = TerminalInput.new({
        ctx = ctx,
        buffer = self.buffer,
        renderer = self.renderer
    })
end

function Terminal:getPrompt()
    local ctx = self.ctx

    local username = "user"
    local hostname = "nova"
    local path = "~"

    if ctx.config then
        username = ctx.config.username or username
        hostname = ctx.config.hostname or hostname
    end

    if ctx.filesystem and ctx.filesystem.display then
        path = ctx.filesystem:display()
    end

    return tostring(username) .. "@" .. tostring(hostname) .. " " .. tostring(path) .. " > "
end

function Terminal:addCommandLine(input)
    local width = term.getSize()
    self.buffer:addLine(self:getPrompt() .. tostring(input or ""), width)
end

function Terminal:addOutputLine(text)
    local width = term.getSize()
    self.buffer:addLine(text, width)
end

function Terminal:addError(message)
    self:addOutputLine("Error: " .. tostring(message))
end

function Terminal:runFullscreenCommand(input)
    local ctx = self.ctx

    self.renderer:restorePlainScreen()

    local ok, result, message = pcall(function()
        return ctx.registry:execute(ctx, input)
    end)

    term.setCursorBlink(false)

    if not ok then
        if ctx.logger then
            ctx.logger:error(result)
        end

        self:addError(result)
        return
    end

    if result == false then
        self:addOutputLine(message or "Command failed.")
        return
    end

    local commandName = getFirstWord(input)

    if FULLSCREEN_COMMANDS[commandName] then
        self:addOutputLine("[returned from " .. commandName .. "]")
    end
end

function Terminal:captureCommandOutput(callback)
    local oldPrint = _G.print
    local oldWrite = _G.write

    local pending = ""

    local function flush()
        if pending ~= "" then
            self:addOutputLine(pending)
            pending = ""
        end
    end

    _G.write = function(text)
        text = tostring(text or "")

        local startIndex = 1

        while true do
            local newlineIndex = string.find(text, "\n", startIndex, true)

            if not newlineIndex then
                pending = pending .. string.sub(text, startIndex)
                break
            end

            pending = pending .. string.sub(text, startIndex, newlineIndex - 1)
            flush()

            startIndex = newlineIndex + 1
        end
    end

    _G.print = function(...)
        local values = {}

        for index = 1, select("#", ...) do
            table.insert(values, tostring(select(index, ...)))
        end

        pending = pending .. table.concat(values, "\t")
        flush()
    end

    local ok, result, message = pcall(callback)

    flush()

    _G.print = oldPrint
    _G.write = oldWrite

    return ok, result, message
end

function Terminal:runCapturedCommand(input)
    local ctx = self.ctx

    local ok, result, message = self:captureCommandOutput(function()
        return ctx.registry:execute(ctx, input)
    end)

    if not ok then
        if ctx.logger then
            ctx.logger:error(result)
        end

        self:addError(result)
        return
    end

    if result == false then
        self:addOutputLine(message or "Command failed.")
    end
end

function Terminal:welcome()
    local ctx = self.ctx
    local width = term.getSize()

    self.buffer:clear()

    local showFetchOnBoot = true

    if ctx.config and ctx.config.showFetchOnBoot == false then
        showFetchOnBoot = false
    end

    if showFetchOnBoot then
        local ok = pcall(function()
            self:runCapturedCommand("fetch")
        end)

        if not ok then
            self.buffer:addLine(tostring(ctx.config.systemName or "NovaOS") .. " " .. tostring(ctx.config.version or ""), width)
        end
    else
        self.buffer:addLine(tostring(ctx.config.systemName or "NovaOS") .. " " .. tostring(ctx.config.version or ""), width)
    end

    self.buffer:addBlank(width)
    self.buffer:addLine("Type 'help' to see available commands.", width)
    self.buffer:addLine("Mouse wheel / PageUp / PageDown scrolls shell output.", width)
    self.buffer:addBlank(width)
end

function Terminal:execute(input)
    input = tostring(input or "")

    if input == "" then
        return
    end

    local commandName = getFirstWord(input)

    if commandName == "clear" or commandName == "cls" then
        self.buffer:clear()
        return
    end

    self:addCommandLine(input)

    if DIRECT_COMMANDS[commandName] or FULLSCREEN_COMMANDS[commandName] then
        self:runFullscreenCommand(input)
        return
    end

    self:runCapturedCommand(input)
end

function Terminal:run()
    local ctx = self.ctx

    self.running = true
    self:welcome()

    while self.running do
        local input = self.input:read(self:getPrompt())

        input = tostring(input or "")

        if input ~= "" then
            if ctx.history then
                ctx.history:add(input)
            end

            if ctx.logger then
                ctx.logger:info("Command: " .. input)
            end

            self:execute(input)
        end
    end
end

return Terminal