local PkgCommand = {}

PkgCommand.description = "Manage local NovaOS packages"
PkgCommand.category = "apps"
PkgCommand.usage = "pkg <list|info|validate|open|new> [package]"
PkgCommand.aliases = {
    "package"
}
PkgCommand.examples = {
    "pkg list",
    "pkg info editor",
    "pkg validate",
    "pkg validate logs",
    "pkg open packages",
    "pkg new clock"
}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if maxLength <= 0 then
        return ""
    end

    if #text <= maxLength then
        return text
    end

    if maxLength <= 3 then
        return string.sub(text, 1, maxLength)
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
end

local function writeColor(text, color)
    term.setTextColor(color)
    write(tostring(text or ""))
end

local function printColor(text, color)
    term.setTextColor(color)
    print(tostring(text or ""))
end

local function sanitizeId(value)
    value = tostring(value or "")
    value = string.lower(value)
    value = string.gsub(value, "%s+", "-")
    value = string.gsub(value, "[^a-z0-9%-_]", "")

    return value
end

local function capitalize(value)
    value = tostring(value or "")

    if value == "" then
        return value
    end

    return string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
end

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

local function countFiles(path)
    if not fs.exists(path) or not fs.isDir(path) then
        return 0
    end

    local count = 0

    for _, _ in ipairs(fs.list(path)) do
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

local function getStatus(manifestPath, entryPath, manifestError)
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

local function scanPackage(appId)
    local appDir = fs.combine("apps", appId)
    local manifestPath = fs.combine(appDir, "manifest.lua")

    local manifest = nil
    local manifestError = nil

    if fs.exists(manifestPath) and not fs.isDir(manifestPath) then
        manifest, manifestError = safeDofile(manifestPath)
    end

    manifest = manifest or {}

    local entry = manifest.entry or "main.lua"
    local entryPath = fs.combine(appDir, entry)
    local status = getStatus(manifestPath, entryPath, manifestError)

    return {
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
        size = getSizeRecursive(appDir),
        sizeText = formatBytes(getSizeRecursive(appDir))
    }
end

local function listPackages()
    local result = {}

    if not fs.exists("apps") then
        fs.makeDir("apps")
    end

    local items = fs.list("apps")
    table.sort(items)

    for _, item in ipairs(items) do
        local appDir = fs.combine("apps", item)

        if fs.isDir(appDir) then
            table.insert(result, scanPackage(item))
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

local function findPackage(packageId)
    packageId = tostring(packageId or "")

    if packageId == "" then
        return nil
    end

    local packages = listPackages()

    for _, package in ipairs(packages) do
        if package.id == packageId or package.folder == packageId or package.name == packageId then
            return package
        end
    end

    return nil
end

local function getStatusColor(ctx, status)
    local theme = ctx.theme

    if status == "ok" then
        return theme.success
    end

    if status == "missing_manifest" or status == "missing_entry" or status == "broken_manifest" then
        return theme.error
    end

    return theme.warning
end

local function printPackageList(ctx)
    local theme = ctx.theme
    local packages = listPackages()
    local width = term.getSize()

    local nameWidth = math.max(14, math.floor(width * 0.34))
    local versionWidth = 8
    local statusWidth = math.max(10, width - nameWidth - versionWidth - 8)

    term.setTextColor(theme.accent)
    print("Packages")
    term.setTextColor(theme.muted)
    print("--------")

    if #packages == 0 then
        printColor("(no packages installed)", theme.muted)
        term.setTextColor(theme.text)
        return true
    end

    writeColor(padRight("Name", nameWidth), theme.accent2)
    writeColor("  ", theme.muted)
    writeColor(padRight("Version", versionWidth), theme.accent2)
    writeColor("  ", theme.muted)
    printColor("Status", theme.accent2)

    printColor(string.rep("-", math.min(width, nameWidth + versionWidth + statusWidth + 4)), theme.muted)

    for _, package in ipairs(packages) do
        writeColor(padRight(cutText(package.name, nameWidth), nameWidth), theme.foreground)
        writeColor("  ", theme.muted)
        writeColor(padRight(cutText(package.version, versionWidth), versionWidth), theme.muted)
        writeColor("  ", theme.muted)
        printColor(cutText(package.status, statusWidth), getStatusColor(ctx, package.status))
    end

    print()
    printColor("Use: pkg info <id> or open packages", theme.muted)
    term.setTextColor(theme.text)

    return true
end

local function printPackageInfo(ctx, packageId)
    local theme = ctx.theme
    local package = findPackage(packageId)

    if not package then
        return false, "Package not found: " .. tostring(packageId)
    end

    term.setTextColor(theme.accent)
    print(package.name)
    term.setTextColor(theme.muted)
    print(string.rep("-", math.min(term.getSize(), #package.name + 8)))
    print()

    writeColor("ID:          ", theme.accent2)
    printColor(package.id, theme.foreground)

    writeColor("Folder:      ", theme.accent2)
    printColor(package.folder, theme.foreground)

    writeColor("Version:     ", theme.accent2)
    printColor(package.version, theme.foreground)

    writeColor("Category:    ", theme.accent2)
    printColor(package.category, theme.foreground)

    writeColor("Author:      ", theme.accent2)
    printColor(package.author, theme.foreground)

    writeColor("Status:      ", theme.accent2)
    printColor(package.status, getStatusColor(ctx, package.status))

    writeColor("Entry:       ", theme.accent2)
    printColor(package.entry, theme.foreground)

    writeColor("Path:        ", theme.accent2)
    printColor("/" .. package.appDir, theme.foreground)

    writeColor("Manifest:    ", theme.accent2)
    printColor(package.manifestExists and "yes" or "no", package.manifestExists and theme.success or theme.error)

    writeColor("Entry file:  ", theme.accent2)
    printColor(package.entryExists and "yes" or "no", package.entryExists and theme.success or theme.error)

    writeColor("Files:       ", theme.accent2)
    printColor(tostring(package.fileCount), theme.foreground)

    writeColor("Size:        ", theme.accent2)
    printColor(package.sizeText, theme.foreground)

    print()
    printColor("Description:", theme.accent2)
    printColor("  " .. package.description, theme.foreground)

    if package.manifestError then
        print()
        printColor("Manifest error:", theme.error)
        printColor("  " .. package.manifestError, theme.error)
    end

    term.setTextColor(theme.text)

    return true
end

local function validatePackage(ctx, package)
    local theme = ctx.theme
    local ok = true

    writeColor(padRight(package.id, 16), theme.foreground)

    if package.status == "ok" then
        printColor("ok", theme.success)
        return true
    end

    ok = false
    printColor(package.status, getStatusColor(ctx, package.status))

    if not package.manifestExists then
        printColor("  missing: " .. package.manifestPath, theme.error)
    end

    if package.manifestError then
        printColor("  manifest error: " .. package.manifestError, theme.error)
    end

    if not package.entryExists then
        printColor("  missing entry: " .. package.entryPath, theme.error)
    end

    return ok
end

local function validatePackages(ctx, packageId)
    local theme = ctx.theme

    term.setTextColor(theme.accent)
    print("Package validation")
    term.setTextColor(theme.muted)
    print("------------------")

    local packages = {}

    if packageId then
        local package = findPackage(packageId)

        if not package then
            return false, "Package not found: " .. tostring(packageId)
        end

        table.insert(packages, package)
    else
        packages = listPackages()
    end

    if #packages == 0 then
        printColor("(no packages)", theme.muted)
        term.setTextColor(theme.text)
        return true
    end

    local broken = 0

    for _, package in ipairs(packages) do
        local ok = validatePackage(ctx, package)

        if not ok then
            broken = broken + 1
        end
    end

    print()

    if broken == 0 then
        printColor("All selected packages are valid.", theme.success)
    else
        printColor("Broken packages: " .. tostring(broken), theme.error)
    end

    term.setTextColor(theme.text)

    return broken == 0
end

local function createManifest(appId, appName)
    return
        "return {\n" ..
        "    id = \"" .. appId .. "\",\n" ..
        "    name = \"" .. appName .. "\",\n" ..
        "    description = \"New NovaOS application\",\n" ..
        "    version = \"0.1.0\",\n" ..
        "    author = \"NovaOS\",\n" ..
        "    entry = \"main.lua\",\n" ..
        "    category = \"user\"\n" ..
        "}\n"
end

local function createMain(appId, appName)
    return
        "local App = {}\n\n" ..
        "App.name = \"" .. appName .. "\"\n" ..
        "App.description = \"New NovaOS application\"\n\n" ..
        "function App.run(ctx, args)\n" ..
        "    ctx.screen:clear(ctx.theme.background, ctx.theme.text)\n\n" ..
        "    local width, height = term.getSize()\n" ..
        "    local boxW = width - 2\n" ..
        "    local boxH = height - 3\n\n" ..
        "    ctx.ui.Box.draw(ctx, 2, 2, boxW, boxH, \"" .. appName .. "\")\n" ..
        "    ctx.ui.Box.writeInside(ctx, 2, 2, boxW, 2, \"Application ID: " .. appId .. "\", ctx.theme.accent2)\n" ..
        "    ctx.ui.Box.writeInside(ctx, 2, 2, boxW, 4, \"Press any key or click to exit.\", ctx.theme.muted)\n" ..
        "    ctx.ui.StatusBar.drawBottom(ctx, \"NovaOS / " .. appName .. "\", \"template app\")\n\n" ..
        "    while true do\n" ..
        "        local event = os.pullEvent()\n\n" ..
        "        if event == \"key\" or event == \"mouse_click\" then\n" ..
        "            return true\n" ..
        "        end\n" ..
        "    end\n" ..
        "end\n\n" ..
        "return App\n"
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

local function createPackage(ctx, appId)
    appId = sanitizeId(appId)

    if not appId or appId == "" then
        return false, "Invalid package id."
    end

    local appDir = fs.combine("apps", appId)

    if fs.exists(appDir) then
        return false, "Package already exists: " .. appId
    end

    fs.makeDir(appDir)

    local appName = capitalize(appId)

    local okManifest, errManifest = writeFile(
        fs.combine(appDir, "manifest.lua"),
        createManifest(appId, appName)
    )

    if not okManifest then
        return false, errManifest
    end

    local okMain, errMain = writeFile(
        fs.combine(appDir, "main.lua"),
        createMain(appId, appName)
    )

    if not okMain then
        return false, errMain
    end

    term.setTextColor(ctx.theme.success)
    print("Created package: " .. appId)
    term.setTextColor(ctx.theme.muted)
    print("Path: /" .. appDir)
    print("Use: open " .. appId)
    term.setTextColor(ctx.theme.text)

    if ctx.logger then
        ctx.logger:info("Package created: " .. appId)
    end

    return true
end

local function openPackage(ctx, packageId)
    local package = findPackage(packageId)

    if not package then
        return false, "Package not found: " .. tostring(packageId)
    end

    if package.status ~= "ok" then
        return false, "Cannot open broken package: " .. package.status
    end

    local ok, result = ctx.appManager:launch(package.id, {
        "open",
        package.id
    })

    if not ok then
        return false, result
    end

    return true
end

local function printUsage(ctx)
    local theme = ctx.theme

    printColor("NovaOS package manager", theme.accent)
    printColor("----------------------", theme.muted)
    print()

    printColor("Usage:", theme.accent2)
    printColor("  pkg list", theme.foreground)
    printColor("  pkg info <id>", theme.foreground)
    printColor("  pkg validate [id]", theme.foreground)
    printColor("  pkg open <id>", theme.foreground)
    printColor("  pkg new <id>", theme.foreground)
    print()

    printColor("Better TUI:", theme.muted)
    printColor("  open packages", theme.foreground)

    term.setTextColor(theme.text)

    return true
end

function PkgCommand.run(ctx, args)
    local action = args[2]

    if not action then
        return printUsage(ctx)
    end

    if action == "list" or action == "ls" then
        return printPackageList(ctx)
    end

    if action == "info" then
        local packageId = args[3]

        if not packageId then
            return false, "Usage: pkg info <id>"
        end

        return printPackageInfo(ctx, packageId)
    end

    if action == "validate" or action == "check" then
        return validatePackages(ctx, args[3])
    end

    if action == "open" or action == "run" then
        local packageId = args[3]

        if not packageId then
            return false, "Usage: pkg open <id>"
        end

        return openPackage(ctx, packageId)
    end

    if action == "new" or action == "create" then
        local packageId = args[3]

        if not packageId then
            return false, "Usage: pkg new <id>"
        end

        return createPackage(ctx, packageId)
    end

    return false, "Unknown pkg action: " .. tostring(action)
end

return PkgCommand