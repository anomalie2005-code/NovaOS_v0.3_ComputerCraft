local Class = require("sys.class")
local CommandParser = require("sys.command_parser")

local CommandRegistry = Class.create()

local function endsWith(text, suffix)
    text = tostring(text or "")
    suffix = tostring(suffix or "")

    return string.sub(text, -#suffix) == suffix
end

local function removeLuaExtension(fileName)
    return string.gsub(fileName, "%.lua$", "")
end

local function isCommandFile(path, fileName)
    if fs.isDir(path) then
        return false
    end

    return endsWith(fileName, ".lua")
end

function CommandRegistry:init(commandsDir)
    self.commandsDir = commandsDir or "commands"
    self.commands = {}
    self.aliases = {}
end

function CommandRegistry:clear()
    self.commands = {}
    self.aliases = {}
end

function CommandRegistry:load(ctx)
    self:clear()

    if not fs.exists(self.commandsDir) then
        fs.makeDir(self.commandsDir)
    end

    local files = fs.list(self.commandsDir)
    table.sort(files)

    for _, fileName in ipairs(files) do
        local path = fs.combine(self.commandsDir, fileName)

        if isCommandFile(path, fileName) then
            local commandName = removeLuaExtension(fileName)
            local ok, commandOrError = pcall(dofile, path)

            if ok and type(commandOrError) == "table" and type(commandOrError.run) == "function" then
                local command = commandOrError

                command.id = command.id or commandName
                command.name = command.name or commandName
                command.description = command.description or "No description"
                command.category = command.category or "general"
                command.usage = command.usage or commandName
                command.examples = command.examples or {}

                self.commands[commandName] = command

                if type(command.aliases) == "table" then
                    for _, alias in ipairs(command.aliases) do
                        self.aliases[alias] = commandName
                    end
                end

                if ctx and ctx.logger then
                    ctx.logger:info("Command loaded: " .. commandName)
                end
            else
                if ctx and ctx.logger then
                    ctx.logger:error("Failed to load command " .. commandName .. ": " .. tostring(commandOrError))
                end
            end
        end
    end
end

function CommandRegistry:reload(ctx)
    self:load(ctx)

    return true
end

function CommandRegistry:get(commandName)
    commandName = tostring(commandName or "")

    if self.commands[commandName] then
        return self.commands[commandName]
    end

    local originalName = self.aliases[commandName]

    if originalName and self.commands[originalName] then
        return self.commands[originalName]
    end

    return nil
end

function CommandRegistry:has(commandName)
    return self:get(commandName) ~= nil
end

function CommandRegistry:list()
    local result = {}

    for commandName, command in pairs(self.commands) do
        table.insert(result, {
            id = commandName,
            name = command.name or commandName,
            description = command.description or "No description",
            category = command.category or "general",
            usage = command.usage or commandName,
            examples = command.examples or {},
            aliases = command.aliases or {}
        })
    end

    table.sort(result, function(a, b)
        local categoryA = tostring(a.category or "general")
        local categoryB = tostring(b.category or "general")

        if categoryA == categoryB then
            return tostring(a.name):lower() < tostring(b.name):lower()
        end

        return categoryA < categoryB
    end)

    return result
end

function CommandRegistry:parse(input)
    return CommandParser.parse(input)
end

function CommandRegistry:execute(ctx, input)
    local args, parseError = self:parse(input)

    if not args then
        return false, parseError or "Failed to parse command."
    end

    if #args == 0 then
        return true
    end

    local commandName = args[1]
    local command = self:get(commandName)

    if not command then
        return false, "Unknown command: " .. tostring(commandName)
    end

    return command.run(ctx, args)
end

return CommandRegistry