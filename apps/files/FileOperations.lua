local FileOperations = {}

local function copyRecursive(source, target)
    if fs.isDir(source) then
        if not fs.exists(target) then
            fs.makeDir(target)
        end

        for _, item in ipairs(fs.list(source)) do
            copyRecursive(fs.combine(source, item), fs.combine(target, item))
        end

        return true
    end

    fs.copy(source, target)

    return true
end

local function isProtectedRoot(path)
    path = tostring(path or "")

    local protected = {
        sys = true,
        commands = true,
        apps = true,
        data = true,
        home = true,
        lib = true,
        ["startup.lua"] = true
    }

    return protected[path] == true
end

function FileOperations.new(ctx, dialogs)
    local self = {}

    self.ctx = ctx
    self.dialogs = dialogs

    function self:createFile(currentPath)
        local name = self.dialogs:askText(
            "New file",
            "File name:",
            "Example: notes.txt",
            ""
        )

        if not name then
            return false, "Creation cancelled."
        end

        local target = fs.combine(currentPath, name)

        if fs.exists(target) then
            return false, "Path already exists: " .. self.ctx.filesystem:display(target)
        end

        local handle = fs.open(target, "w")

        if not handle then
            return false, "Cannot create file: " .. self.ctx.filesystem:display(target)
        end

        handle.write("")
        handle.close()

        return true, "Created file: " .. self.ctx.filesystem:display(target)
    end

    function self:createDirectory(currentPath)
        local name = self.dialogs:askText(
            "New directory",
            "Directory name:",
            "Example: projects",
            ""
        )

        if not name then
            return false, "Creation cancelled."
        end

        local target = fs.combine(currentPath, name)

        if fs.exists(target) then
            return false, "Path already exists: " .. self.ctx.filesystem:display(target)
        end

        fs.makeDir(target)

        return true, "Created directory: " .. self.ctx.filesystem:display(target)
    end

    function self:rename(entry)
        if not entry then
            return false, "No item selected."
        end

        if entry.kind == "up" then
            return false, "Cannot rename parent entry."
        end

        local newName = self.dialogs:askText(
            "Rename",
            "New name:",
            "Current: " .. tostring(entry.name),
            entry.name
        )

        if not newName then
            return false, "Rename cancelled."
        end

        if newName == entry.name then
            return true, "Name unchanged."
        end

        local parent = fs.getDir(entry.path)
        local target = fs.combine(parent, newName)

        if fs.exists(target) then
            return false, "Target already exists: " .. self.ctx.filesystem:display(target)
        end

        local ok, err = pcall(function()
            fs.move(entry.path, target)
        end)

        if not ok then
            return false, "Rename failed: " .. tostring(err)
        end

        return true, "Renamed to: " .. self.ctx.filesystem:display(target)
    end

    function self:delete(entry)
        if not entry then
            return false, "No item selected."
        end

        if entry.kind == "up" then
            return false, "Cannot delete parent entry."
        end

        if isProtectedRoot(entry.path) then
            return false, "Protected path: " .. self.ctx.filesystem:display(entry.path)
        end

        local confirmed = self.dialogs:confirm(
            "Delete",
            "Delete " .. self.ctx.filesystem:display(entry.path) .. "?"
        )

        if not confirmed then
            return false, "Delete cancelled."
        end

        local ok, err = pcall(function()
            fs.delete(entry.path)
        end)

        if not ok then
            return false, "Delete failed: " .. tostring(err)
        end

        return true, "Deleted: " .. self.ctx.filesystem:display(entry.path)
    end

    function self:copy(entry, currentPath)
        if not entry then
            return false, "No item selected."
        end

        if entry.kind == "up" then
            return false, "Cannot copy parent entry."
        end

        local defaultTarget = fs.combine(currentPath, entry.name .. "_copy")

        local targetInput = self.dialogs:askPath(
            "Copy",
            "Copy to:",
            "Target path. Example: backup/" .. entry.name,
            self.ctx.filesystem:display(defaultTarget)
        )

        if not targetInput then
            return false, "Copy cancelled."
        end

        local target = self.ctx.filesystem:resolve(targetInput)

        if fs.exists(target) and fs.isDir(target) then
            target = fs.combine(target, fs.getName(entry.path))
        end

        if fs.exists(target) then
            return false, "Target already exists: " .. self.ctx.filesystem:display(target)
        end

        local parent = fs.getDir(target)

        if parent and parent ~= "" and not fs.exists(parent) then
            fs.makeDir(parent)
        end

        local ok, err = pcall(function()
            copyRecursive(entry.path, target)
        end)

        if not ok then
            return false, "Copy failed: " .. tostring(err)
        end

        return true, "Copied to: " .. self.ctx.filesystem:display(target)
    end

    function self:move(entry, currentPath)
        if not entry then
            return false, "No item selected."
        end

        if entry.kind == "up" then
            return false, "Cannot move parent entry."
        end

        if isProtectedRoot(entry.path) then
            return false, "Protected path: " .. self.ctx.filesystem:display(entry.path)
        end

        local targetInput = self.dialogs:askPath(
            "Move",
            "Move to:",
            "Target path. Example: projects/" .. entry.name,
            self.ctx.filesystem:display(entry.path)
        )

        if not targetInput then
            return false, "Move cancelled."
        end

        local target = self.ctx.filesystem:resolve(targetInput)

        if target == entry.path then
            return true, "Path unchanged."
        end

        if fs.exists(target) and fs.isDir(target) then
            target = fs.combine(target, fs.getName(entry.path))
        end

        if fs.exists(target) then
            return false, "Target already exists: " .. self.ctx.filesystem:display(target)
        end

        local parent = fs.getDir(target)

        if parent and parent ~= "" and not fs.exists(parent) then
            fs.makeDir(parent)
        end

        local ok, err = pcall(function()
            fs.move(entry.path, target)
        end)

        if not ok then
            return false, "Move failed: " .. tostring(err)
        end

        return true, "Moved to: " .. self.ctx.filesystem:display(target)
    end

    return self
end

return FileOperations