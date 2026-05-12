local PackageOperations = {}

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

local function writeFile(path, content)
    local parent = fs.getDir(path)

    if parent and parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end

    local handle = fs.open(path, "w")

    if not handle then
        return false, "Cannot write file: " .. path
    end

    handle.write(content)
    handle.close()

    return true
end

local function capitalize(value)
    value = tostring(value or "")

    if value == "" then
        return value
    end

    return string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
end

local function createManifestContent(package)
    local appId = package.folder or package.id or "unknown"
    local appName = package.name or capitalize(appId)

    return
        "return {\n" ..
        "    id = \"" .. appId .. "\",\n" ..
        "    name = \"" .. appName .. "\",\n" ..
        "    description = \"Repaired NovaOS application manifest\",\n" ..
        "    version = \"0.1.0\",\n" ..
        "    author = \"NovaOS\",\n" ..
        "    entry = \"main.lua\",\n" ..
        "    category = \"user\"\n" ..
        "}\n"
end

local function createMainContent(package)
    local appId = package.folder or package.id or "unknown"
    local appName = package.name or capitalize(appId)

    return
        "local App = {}\n\n" ..
        "App.name = \"" .. appName .. "\"\n" ..
        "App.description = \"Repaired NovaOS application entry\"\n\n" ..
        "function App.run(ctx, args)\n" ..
        "    ctx.screen:clear(ctx.theme.background, ctx.theme.text)\n\n" ..
        "    local width, height = term.getSize()\n" ..
        "    local boxW = width - 2\n" ..
        "    local boxH = height - 3\n\n" ..
        "    ctx.ui.Box.draw(ctx, 2, 2, boxW, boxH, \"" .. appName .. "\")\n" ..
        "    ctx.ui.Box.writeInside(ctx, 2, 2, boxW, 2, \"Application ID: " .. appId .. "\", ctx.theme.accent2)\n" ..
        "    ctx.ui.Box.writeInside(ctx, 2, 2, boxW, 4, \"This entry file was repaired by Package Manager.\", ctx.theme.warning)\n" ..
        "    ctx.ui.Box.writeInside(ctx, 2, 2, boxW, 6, \"Press any key or click to exit.\", ctx.theme.muted)\n" ..
        "    ctx.ui.StatusBar.drawBottom(ctx, \"NovaOS / " .. appName .. "\", \"repaired app\")\n\n" ..
        "    while true do\n" ..
        "        local event = os.pullEvent()\n\n" ..
        "        if event == \"key\" or event == \"mouse_click\" then\n" ..
        "            return true\n" ..
        "        end\n" ..
        "    end\n" ..
        "end\n\n" ..
        "return App\n"
end

function PackageOperations.new(ctx, dialogs)
    local self = {}

    self.ctx = ctx
    self.dialogs = dialogs

    function self:isProtectedPackage(package)
        if not package then
            return true
        end

        local protected = {
            packages = true,
            launcher = true,
            files = true,
            editor = true,
            settings = true,
            monitor = true,
            logs = true,
            tasks = true,
            network = true,
            about = true
        }

        return protected[package.id] == true or protected[package.folder] == true
    end

    function self:validate(package)
        if not package then
            return false, "No package selected."
        end

        if package.status == "ok" then
            return true, "Package is valid: " .. tostring(package.id)
        end

        local lines = {}

        table.insert(lines, "Package: " .. tostring(package.id))
        table.insert(lines, "Status: " .. tostring(package.status))

        if not package.manifestExists then
            table.insert(lines, "Missing manifest: " .. tostring(package.manifestPath))
        end

        if package.manifestError then
            table.insert(lines, "Manifest error: " .. tostring(package.manifestError))
        end

        if not package.entryExists then
            table.insert(lines, "Missing entry: " .. tostring(package.entryPath))
        end

        return false, table.concat(lines, " | ")
    end

    function self:backup(package)
        if not package then
            return false, "No package selected."
        end

        if not fs.exists(package.appDir) or not fs.isDir(package.appDir) then
            return false, "Package folder does not exist: " .. tostring(package.appDir)
        end

        local backupRoot = "data/backups/packages"

        if not fs.exists("data") then
            fs.makeDir("data")
        end

        if not fs.exists("data/backups") then
            fs.makeDir("data/backups")
        end

        if not fs.exists(backupRoot) then
            fs.makeDir(backupRoot)
        end

        local baseName = tostring(package.folder or package.id) .. "_backup"
        local target = fs.combine(backupRoot, baseName)

        local counter = 1

        while fs.exists(target) do
            target = fs.combine(backupRoot, baseName .. "_" .. tostring(counter))
            counter = counter + 1
        end

        local ok, err = pcall(function()
            copyRecursive(package.appDir, target)
        end)

        if not ok then
            return false, "Backup failed: " .. tostring(err)
        end

        if self.ctx.logger then
            self.ctx.logger:info("Package backup created: " .. tostring(package.id) .. " -> " .. target)
        end

        return true, "Backup created: /" .. target
    end

    function self:delete(package)
        if not package then
            return false, "No package selected."
        end

        if self:isProtectedPackage(package) then
            return false, "Protected system package. Delete blocked: " .. tostring(package.id)
        end

        if not fs.exists(package.appDir) then
            return false, "Package folder does not exist: " .. tostring(package.appDir)
        end

        local confirmed = self.dialogs:confirm(
            "Delete package",
            "Delete package " .. tostring(package.id) .. "?"
        )

        if not confirmed then
            return false, "Delete cancelled."
        end

        local backupOk, backupMessage = self:backup(package)

        if not backupOk then
            return false, "Delete cancelled because backup failed: " .. tostring(backupMessage)
        end

        local ok, err = pcall(function()
            fs.delete(package.appDir)
        end)

        if not ok then
            return false, "Delete failed: " .. tostring(err)
        end

        if self.ctx.logger then
            self.ctx.logger:info("Package deleted: " .. tostring(package.id))
        end

        return true, "Deleted package: " .. tostring(package.id) .. " | " .. backupMessage
    end

    function self:repair(package)
        if not package then
            return false, "No package selected."
        end

        if not fs.exists(package.appDir) or not fs.isDir(package.appDir) then
            return false, "Package folder does not exist: " .. tostring(package.appDir)
        end

        if package.status == "ok" then
            return true, "Package is already valid."
        end

        local repaired = {}

        if not package.manifestExists then
            local okManifest, errManifest = writeFile(package.manifestPath, createManifestContent(package))

            if not okManifest then
                return false, errManifest
            end

            table.insert(repaired, "manifest.lua")
        elseif package.manifestError then
            local repairedPath = fs.combine(package.appDir, "manifest_repaired.lua")

            local okRepairManifest, errRepairManifest = writeFile(repairedPath, createManifestContent(package))

            if not okRepairManifest then
                return false, errRepairManifest
            end

            table.insert(repaired, "manifest_repaired.lua")
        end

        if not package.entryExists then
            local entryPath = package.entryPath or fs.combine(package.appDir, "main.lua")

            local okEntry, errEntry = writeFile(entryPath, createMainContent(package))

            if not okEntry then
                return false, errEntry
            end

            table.insert(repaired, package.entry or "main.lua")
        end

        if #repaired == 0 then
            return false, "Nothing to repair."
        end

        if self.ctx.logger then
            self.ctx.logger:info("Package repaired: " .. tostring(package.id) .. " [" .. table.concat(repaired, ", ") .. "]")
        end

        return true, "Repaired: " .. table.concat(repaired, ", ")
    end

    return self
end

return PackageOperations