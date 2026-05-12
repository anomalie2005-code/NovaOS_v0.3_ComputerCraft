local PackagesData = {}

local function safeDofile(path)
    local ok, result = pcall(dofile, path)

    if not ok then
        return nil, tostring(result)
    end

    if type(result) ~= "table" then
        return nil, "Manifest must return table."
    end

    return result, nil
end

local function getStatus(appDir, manifestPath, entryPath, manifestError)
    if not fs.exists(manifestPath) then
        return "missing_manifest"
    end

    if manifestError then
        return "broken_manifest"
    end

    if not entryPath or entryPath == "" or not fs.exists(entryPath) then
        return "missing_entry"
    end

    if fs.isDir(entryPath) then
        return "invalid_entry"
    end

    return "ok"
end

local function countFiles(path)
    if not fs.exists(path) or not fs.isDir(path) then
        return 0
    end

    local count = 0
    local items = fs.list(path)

    for _, _ in ipairs(items) do
        count = count + 1
    end

    return count
end

local function getSizeRecursive(path)
    if not fs.exists(path) then
        return 0
    end

    if not fs.isDir(path) then
        return fs.getSize(path)
    end

    local total = 0

    for _, item in ipairs(fs.list(path)) do
        total = total + getSizeRecursive(fs.combine(path, item))
    end

    return total
end

local function formatBytes(size)
    size = tonumber(size or 0) or 0

    if size < 1024 then
        return tostring(size) .. " B"
    end

    local kb = math.floor((size / 1024) * 10) / 10

    return tostring(kb) .. " KB"
end

function PackagesData.new(ctx)
    local self = {}

    self.ctx = ctx
    self.appsDir = "apps"

    function self:scanPackage(appId)
        local appDir = fs.combine(self.appsDir, appId)
        local manifestPath = fs.combine(appDir, "manifest.lua")

        local manifest = nil
        local manifestError = nil

        if fs.exists(manifestPath) and not fs.isDir(manifestPath) then
            manifest, manifestError = safeDofile(manifestPath)
        end

        manifest = manifest or {}

        local entry = manifest.entry or "main.lua"
        local entryPath = fs.combine(appDir, entry)

        local status = getStatus(appDir, manifestPath, entryPath, manifestError)

        local package = {
            id = manifest.id or appId,
            folder = appId,
            name = manifest.name or appId,
            description = manifest.description or "No description",
            version = manifest.version or "0.1.0",
            author = manifest.author or "NovaOS",
            category = manifest.category or "uncategorized",
            entry = entry,
            appDir = appDir,
            manifestPath = manifestPath,
            entryPath = entryPath,
            manifestExists = fs.exists(manifestPath),
            entryExists = fs.exists(entryPath),
            manifestError = manifestError,
            status = status,
            fileCount = countFiles(appDir),
            size = getSizeRecursive(appDir)
        }

        package.sizeText = formatBytes(package.size)

        return package
    end

    function self:listPackages()
        local result = {}

        if not fs.exists(self.appsDir) then
            fs.makeDir(self.appsDir)
        end

        local items = fs.list(self.appsDir)
        table.sort(items)

        for _, item in ipairs(items) do
            local appDir = fs.combine(self.appsDir, item)

            if fs.isDir(appDir) then
                table.insert(result, self:scanPackage(item))
            end
        end

        table.sort(result, function(a, b)
            if a.status == b.status then
                return tostring(a.name):lower() < tostring(b.name):lower()
            end

            if a.status == "ok" then
                return true
            end

            if b.status == "ok" then
                return false
            end

            return tostring(a.status) < tostring(b.status)
        end)

        return result
    end

    function self:getSummary(packages)
        local summary = {
            total = #packages,
            ok = 0,
            broken = 0,
            missingManifest = 0,
            missingEntry = 0
        }

        for _, package in ipairs(packages) do
            if package.status == "ok" then
                summary.ok = summary.ok + 1
            elseif package.status == "missing_manifest" then
                summary.missingManifest = summary.missingManifest + 1
                summary.broken = summary.broken + 1
            elseif package.status == "missing_entry" then
                summary.missingEntry = summary.missingEntry + 1
                summary.broken = summary.broken + 1
            else
                summary.broken = summary.broken + 1
            end
        end

        return summary
    end

    function self:canLaunch(package)
        return package and package.status == "ok"
    end

    return self
end

return PackagesData