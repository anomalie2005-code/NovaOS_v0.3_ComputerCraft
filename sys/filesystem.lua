local Class = require("sys.class")

local FileSystem = Class.create()

local rootFolders = {
    sys = true,
    commands = true,
    apps = true,
    data = true,
    home = true,
    lib = true,
    rom = true,
    disk = true
}

local rootFiles = {
    ["startup.lua"] = true
}

local function getFirstPathPart(path)
    path = tostring(path or "")

    local first = string.match(path, "^([^/]+)")

    return first or path
end

local function isRootStylePath(path)
    path = tostring(path or "")

    if path == "" then
        return false
    end

    local first = getFirstPathPart(path)

    if rootFolders[first] then
        return true
    end

    if rootFiles[first] then
        return true
    end

    return false
end

function FileSystem:init(homeDir)
    self.homeDir = homeDir or "home/user"
    self.currentDir = self.homeDir

    if not fs.exists(self.homeDir) then
        fs.makeDir(self.homeDir)
    end
end

function FileSystem:normalize(path)
    if not path or path == "" then
        return self.currentDir
    end

    path = tostring(path)

    if path == "/" then
        return ""
    end

    if string.sub(path, 1, 1) == "/" then
        path = string.sub(path, 2)
    end

    local parts = {}

    for part in string.gmatch(path, "[^/]+") do
        if part == ".." then
            table.remove(parts)
        elseif part ~= "." and part ~= "" then
            table.insert(parts, part)
        end
    end

    return table.concat(parts, "/")
end

function FileSystem:resolve(path)
    if not path or path == "" then
        return self.currentDir
    end

    path = tostring(path)

    if path == "~" then
        return self.homeDir
    end

    if string.sub(path, 1, 2) == "~/" then
        return self:normalize(self.homeDir .. "/" .. string.sub(path, 3))
    end

    if path == "/" then
        return ""
    end

    if string.sub(path, 1, 1) == "/" then
        return self:normalize(path)
    end

    if fs.exists(path) then
        return self:normalize(path)
    end

    if isRootStylePath(path) then
        return self:normalize(path)
    end

    return self:normalize(fs.combine(self.currentDir, path))
end

function FileSystem:display(path)
    local value = path or self.currentDir

    if value == "" then
        return "/"
    end

    if value == self.homeDir then
        return "~"
    end

    local prefix = self.homeDir .. "/"

    if string.sub(value, 1, #prefix) == prefix then
        return "~/" .. string.sub(value, #prefix + 1)
    end

    return "/" .. value
end

function FileSystem:changeDir(path)
    local resolved = self:resolve(path)

    if not fs.exists(resolved) then
        return false, "Directory does not exist: " .. self:display(resolved)
    end

    if not fs.isDir(resolved) then
        return false, "Not a directory: " .. self:display(resolved)
    end

    self.currentDir = resolved

    return true
end

function FileSystem:list(path)
    local resolved = self:resolve(path)

    if not fs.exists(resolved) then
        return nil, "Path does not exist: " .. self:display(resolved)
    end

    if not fs.isDir(resolved) then
        return nil, "Not a directory: " .. self:display(resolved)
    end

    local items = fs.list(resolved)
    table.sort(items)

    return items, resolved
end

function FileSystem:exists(path)
    return fs.exists(self:resolve(path))
end

function FileSystem:isDir(path)
    return fs.isDir(self:resolve(path))
end

function FileSystem:readFile(path)
    local resolved = self:resolve(path)

    if not fs.exists(resolved) then
        return nil, "File does not exist: " .. self:display(resolved)
    end

    if fs.isDir(resolved) then
        return nil, "Cannot read directory: " .. self:display(resolved)
    end

    local handle = fs.open(resolved, "r")

    if not handle then
        return nil, "Cannot open file: " .. self:display(resolved)
    end

    local content = handle.readAll()
    handle.close()

    return content or "", resolved
end

return FileSystem