local Class = require("sys.class")

local Autocomplete = Class.create()

local function startsWith(text, prefix)
    text = tostring(text or "")
    prefix = tostring(prefix or "")

    return string.sub(text, 1, #prefix) == prefix
end

local function splitInput(input)
    local parts = {}

    for part in string.gmatch(input or "", "%S+") do
        table.insert(parts, part)
    end

    return parts
end

local function getLastToken(input)
    input = tostring(input or "")

    if input == "" then
        return ""
    end

    if string.sub(input, -1) == " " then
        return ""
    end

    local last = string.match(input, "(%S+)$")

    return last or ""
end

local function removeDuplicates(list)
    local seen = {}
    local result = {}

    for _, item in ipairs(list) do
        if not seen[item] then
            seen[item] = true
            table.insert(result, item)
        end
    end

    table.sort(result)

    return result
end

local function getDirectoryAndPrefix(ctx, token)
    token = tostring(token or "")

    local dirPart = ""
    local prefix = token
    local slashIndex = nil

    for i = #token, 1, -1 do
        if string.sub(token, i, i) == "/" then
            slashIndex = i
            break
        end
    end

    if slashIndex then
        dirPart = string.sub(token, 1, slashIndex)
        prefix = string.sub(token, slashIndex + 1)
    end

    local searchDir

    if dirPart == "" then
        searchDir = ctx.filesystem.currentDir
    else
        searchDir = ctx.filesystem:resolve(dirPart)
    end

    return searchDir, prefix
end

local function completeCommand(ctx, token)
    local result = {}
    local commands = ctx.registry:list()

    for _, command in ipairs(commands) do
        if startsWith(command.name, token) then
            table.insert(result, string.sub(command.name, #token + 1))
        end
    end

    return removeDuplicates(result)
end

local function completeApp(ctx, token)
    local result = {}
    local apps = ctx.appManager:list()

    for _, appName in ipairs(apps) do
        if startsWith(appName, token) then
            table.insert(result, string.sub(appName, #token + 1))
        end
    end

    return removeDuplicates(result)
end

local function completeTheme(token)
    local result = {}
    local themes = {
        "cyber",
        "amber",
        "arch"
    }

    for _, themeName in ipairs(themes) do
        if startsWith(themeName, token) then
            table.insert(result, string.sub(themeName, #token + 1))
        end
    end

    return removeDuplicates(result)
end

local function completePath(ctx, token)
    local result = {}

    local searchDir, prefix = getDirectoryAndPrefix(ctx, token)

    if not fs.exists(searchDir) or not fs.isDir(searchDir) then
        return result
    end

    local items = fs.list(searchDir)
    table.sort(items)

    for _, item in ipairs(items) do
        if startsWith(item, prefix) then
            local fullPath = fs.combine(searchDir, item)
            local suffix = string.sub(item, #prefix + 1)

            if fs.isDir(fullPath) then
                suffix = suffix .. "/"
            end

            table.insert(result, suffix)
        end
    end

    return removeDuplicates(result)
end

function Autocomplete:init()
end

function Autocomplete:complete(ctx, input)
    input = tostring(input or "")

    local parts = splitInput(input)
    local lastToken = getLastToken(input)
    local endsWithSpace = string.sub(input, -1) == " "

    if #parts == 0 then
        return completeCommand(ctx, "")
    end

    if #parts == 1 and not endsWithSpace then
        return completeCommand(ctx, lastToken)
    end

    local commandName = parts[1]

    if commandName == "open" then
        return completeApp(ctx, lastToken)
    end

    if commandName == "theme" then
        return completeTheme(lastToken)
    end

    return completePath(ctx, lastToken)
end

return Autocomplete