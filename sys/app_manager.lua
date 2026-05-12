local Class = require("sys.class")

local AppManager = Class.create()

local function copyTable(source)
    local result = {}

    for key, value in pairs(source or {}) do
        result[key] = value
    end

    return result
end

function AppManager:init(ctx, appsDir)
    self.ctx = ctx
    self.appsDir = appsDir or "apps"
end

function AppManager:getAppDir(appId)
    return fs.combine(self.appsDir, appId)
end

function AppManager:getManifestPath(appId)
    return fs.combine(self:getAppDir(appId), "manifest.lua")
end

function AppManager:getDefaultEntryPath(appId)
    return fs.combine(self:getAppDir(appId), "main.lua")
end

function AppManager:loadManifest(appId)
    local manifestPath = self:getManifestPath(appId)

    local fallback = {
        id = appId,
        name = appId,
        description = "No description",
        version = "0.1.0",
        author = "NovaOS",
        entry = "main.lua",
        category = "uncategorized"
    }

    if not fs.exists(manifestPath) then
        return fallback
    end

    local ok, data = pcall(dofile, manifestPath)

    if not ok or type(data) ~= "table" then
        return fallback
    end

    local manifest = copyTable(fallback)

    for key, value in pairs(data) do
        manifest[key] = value
    end

    manifest.id = manifest.id or appId
    manifest.name = manifest.name or appId
    manifest.description = manifest.description or "No description"
    manifest.version = manifest.version or "0.1.0"
    manifest.author = manifest.author or "NovaOS"
    manifest.entry = manifest.entry or "main.lua"
    manifest.category = manifest.category or "uncategorized"

    return manifest
end

function AppManager:getEntryPath(appId)
    local manifest = self:loadManifest(appId)

    return fs.combine(self:getAppDir(appId), manifest.entry or "main.lua")
end

function AppManager:exists(appId)
    if not appId or appId == "" then
        return false
    end

    local appDir = self:getAppDir(appId)

    if not fs.exists(appDir) or not fs.isDir(appDir) then
        return false
    end

    return fs.exists(self:getEntryPath(appId))
end

function AppManager:list()
    local result = {}

    if not fs.exists(self.appsDir) then
        return result
    end

    local items = fs.list(self.appsDir)
    table.sort(items)

    for _, item in ipairs(items) do
        local path = fs.combine(self.appsDir, item)

        if fs.isDir(path) and self:exists(item) then
            table.insert(result, item)
        end
    end

    return result
end

function AppManager:listMetadata()
    local result = {}
    local appIds = self:list()

    for _, appId in ipairs(appIds) do
        local manifest = self:loadManifest(appId)

        table.insert(result, {
            id = appId,
            name = manifest.name or appId,
            label = manifest.name or appId,
            description = manifest.description or "No description",
            version = manifest.version or "0.1.0",
            author = manifest.author or "NovaOS",
            entry = manifest.entry or "main.lua",
            category = manifest.category or "uncategorized"
        })
    end

    table.sort(result, function(a, b)
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)

    return result
end

function AppManager:restoreTerminal()
    term.setCursorBlink(false)

    if self.ctx and self.ctx.screen and self.ctx.theme then
        self.ctx.screen:clear(self.ctx.theme.background, self.ctx.theme.text)
    else
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
    end
end

function AppManager:launch(appId, args)
    if not appId or appId == "" then
        return false, "App name is required"
    end

    if not self:exists(appId) then
        return false, "App not found: " .. appId
    end

    local entryPath = self:getEntryPath(appId)
    local manifest = self:loadManifest(appId)

    local ok, appOrError = pcall(dofile, entryPath)

    if not ok then
        self:restoreTerminal()
        return false, "Failed to load app '" .. appId .. "': " .. tostring(appOrError)
    end

    if type(appOrError) ~= "table" or type(appOrError.run) ~= "function" then
        self:restoreTerminal()
        return false, "Invalid app format: " .. appId
    end

    self.ctx.logger:info("Launching app: " .. appId)

    local launchArgs = args or {}
    launchArgs.manifest = manifest

    local okRun, result = pcall(function()
        return appOrError.run(self.ctx, launchArgs)
    end)

    self:restoreTerminal()

    if not okRun then
        self.ctx.logger:error("App crashed '" .. appId .. "': " .. tostring(result))
        return false, "App crashed: " .. tostring(result)
    end

    return true, result
end

return AppManager