local Installer = {}

Installer.name = "NovaOS Online Installer"
Installer.version = "0.3.0"

local BASE_URL = "https://raw.githubusercontent.com/anomalie2005-code/NovaOS_v0.3_ComputerCraft/main/"
local MANIFEST_URL = BASE_URL .. "manifest.lua"

local SYSTEM_DIRS = {
    "sys",
    "commands",
    "apps",
    "lib",
    "ui"
}

local DATA_DIRS = {
    "data",
    "data/logs",
    "data/backups",
    "data/backups/system",
    "home",
    "home/user",
    "home/user/projects"
}

local function setColor(color)
    if term.isColor and term.isColor() then
        term.setTextColor(color)
    end
end

local function writeLine(text)
    print(tostring(text or ""))
end

local function writeStatus(label, text)
    setColor(colors.orange)
    write(tostring(label or ""))

    setColor(colors.white)
    print(tostring(text or ""))
end

local function writeOk(text)
    setColor(colors.lime)
    print(tostring(text or ""))

    setColor(colors.white)
end

local function writeWarn(text)
    setColor(colors.yellow)
    print(tostring(text or ""))

    setColor(colors.white)
end

local function writeError(text)
    setColor(colors.red)
    print(tostring(text or ""))

    setColor(colors.white)
end

local function clearScreen()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function ensureHttp()
    if not http then
        return false, "HTTP API is disabled. Enable HTTP in ComputerCraft config."
    end

    return true
end

local function ensureDir(path)
    if path and path ~= "" and not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function ensureParentDir(path)
    local dir = fs.getDir(path)

    if dir and dir ~= "" then
        ensureDir(dir)
    end
end

local function downloadText(url)
    local response, err = http.get(url)

    if not response then
        return nil, err or "HTTP request failed"
    end

    local content = response.readAll()
    response.close()

    return content
end

local function saveFile(path, content)
    ensureParentDir(path)

    local handle = fs.open(path, "w")

    if not handle then
        return false, "Cannot write file: " .. tostring(path)
    end

    handle.write(content or "")
    handle.close()

    return true
end

local function loadManifestFromText(text)
    local chunk, syntaxError = load(text, "novaos_manifest", "t", {})

    if not chunk then
        return nil, syntaxError
    end

    local ok, result = pcall(chunk)

    if not ok then
        return nil, result
    end

    if type(result) ~= "table" then
        return nil, "Manifest did not return a table."
    end

    if type(result.files) ~= "table" then
        return nil, "Manifest has no files table."
    end

    return result
end

local function askYesNo(question, defaultNo)
    writeLine("")

    setColor(colors.yellow)
    write(question .. " ")

    setColor(colors.gray)

    if defaultNo then
        write("[y/N] ")
    else
        write("[Y/n] ")
    end

    setColor(colors.white)

    local answer = read()
    answer = string.lower(tostring(answer or ""))

    if answer == "" then
        return not defaultNo
    end

    return answer == "y" or answer == "yes"
end

local function hasExistingNovaOS()
    if fs.exists("startup.lua") then
        return true
    end

    for _, dir in ipairs(SYSTEM_DIRS) do
        if fs.exists(dir) then
            return true
        end
    end

    return false
end

local function copyRecursive(source, target)
    if fs.isDir(source) then
        ensureDir(target)

        for _, item in ipairs(fs.list(source)) do
            copyRecursive(fs.combine(source, item), fs.combine(target, item))
        end

        return
    end

    ensureParentDir(target)
    fs.copy(source, target)
end

local function deleteSystemFiles()
    if fs.exists("startup.lua") then
        fs.delete("startup.lua")
    end

    for _, dir in ipairs(SYSTEM_DIRS) do
        if fs.exists(dir) then
            fs.delete(dir)
        end
    end
end

local function makeBackup()
    ensureDir("data")
    ensureDir("data/backups")
    ensureDir("data/backups/system")

    local stamp = tostring(math.floor(os.clock() * 1000))

    if os.epoch then
        stamp = tostring(os.epoch("utc"))
    end

    local backupName = "novaos_backup_" .. stamp
    local backupRoot = fs.combine("data/backups/system", backupName)

    ensureDir(backupRoot)

    if fs.exists("startup.lua") then
        copyRecursive("startup.lua", fs.combine(backupRoot, "startup.lua"))
    end

    for _, dir in ipairs(SYSTEM_DIRS) do
        if fs.exists(dir) then
            copyRecursive(dir, fs.combine(backupRoot, dir))
        end
    end

    return backupRoot
end

local function createDataDirs()
    for _, dir in ipairs(DATA_DIRS) do
        ensureDir(dir)
    end
end

local function showHeader()
    clearScreen()

    setColor(colors.orange)
    print(" _   _                 ___  ____  ")
    print("| \\ | | _____   ____ _/ _ \\/ ___| ")
    print("|  \\| |/ _ \\ \\ / / _` | | | \\___ \\")
    print("| |\\  | (_) \\ V / (_| | |_| |___) |")
    print("|_| \\_|\\___/ \\_/ \\__,_|\\___/|____/ ")
    setColor(colors.white)

    print("")
    writeStatus("Installer: ", Installer.version)
    writeStatus("Source: ", BASE_URL)
    print("")
end

local function downloadManifest()
    writeStatus("Downloading manifest: ", MANIFEST_URL)

    local text, err = downloadText(MANIFEST_URL)

    if not text then
        return nil, "Failed to download manifest: " .. tostring(err)
    end

    local manifest, manifestErr = loadManifestFromText(text)

    if not manifest then
        return nil, "Failed to load manifest: " .. tostring(manifestErr)
    end

    return manifest
end

local function validateManifestFiles(manifest)
    local seen = {}

    for _, path in ipairs(manifest.files) do
        if type(path) ~= "string" then
            return false, "Manifest contains non-string path."
        end

        if path == "" then
            return false, "Manifest contains empty path."
        end

        if seen[path] then
            return false, "Duplicate file in manifest: " .. tostring(path)
        end

        seen[path] = true

        if string.sub(path, 1, 1) == "/" then
            return false, "Manifest path must be relative: " .. tostring(path)
        end

        if string.find(path, "%.%.", 1, true) then
            return false, "Manifest path cannot contain '..': " .. tostring(path)
        end
    end

    return true
end

local function installFiles(manifest)
    local total = #manifest.files
    local installed = 0

    for index, path in ipairs(manifest.files) do
        local url = BASE_URL .. path

        setColor(colors.gray)
        print("[" .. tostring(index) .. "/" .. tostring(total) .. "] " .. path)
        setColor(colors.white)

        local content, err = downloadText(url)

        if not content then
            return false, "Failed to download " .. path .. ": " .. tostring(err)
        end

        local ok, saveErr = saveFile(path, content)

        if not ok then
            return false, saveErr
        end

        installed = installed + 1
    end

    return true, installed
end

local function writeInstallInfo(manifest)
    ensureDir("data")

    local handle = fs.open("data/install_info.lua", "w")

    if not handle then
        return false
    end

    local installedAt = tostring(os.clock())

    if os.epoch then
        installedAt = tostring(os.epoch("utc"))
    end

    handle.write("return {\n")
    handle.write("    system = \"NovaOS\",\n")
    handle.write("    version = \"" .. tostring(manifest.version or "unknown") .. "\",\n")
    handle.write("    source = \"" .. BASE_URL .. "\",\n")
    handle.write("    installedAt = \"" .. installedAt .. "\"\n")
    handle.write("}\n")
    handle.close()

    return true
end

local function showInstallSummary(manifest)
    writeOk("Manifest loaded.")
    writeStatus("Version: ", tostring(manifest.version or "unknown"))
    writeStatus("Files: ", tostring(#manifest.files))
end

function Installer.run()
    showHeader()

    local httpOk, httpErr = ensureHttp()

    if not httpOk then
        writeError(httpErr)
        return false
    end

    local manifest, manifestErr = downloadManifest()

    if not manifest then
        writeError(manifestErr)
        return false
    end

    local valid, validErr = validateManifestFiles(manifest)

    if not valid then
        writeError(validErr)
        return false
    end

    showInstallSummary(manifest)

    if hasExistingNovaOS() then
        writeWarn("Existing NovaOS/system files detected.")

        local replace = askYesNo("Replace existing system?", true)

        if not replace then
            writeWarn("Installation cancelled.")
            return false
        end

        local backup = askYesNo("Create backup before replace?", false)

        if backup then
            local backupPath = makeBackup()
            writeOk("Backup created: " .. backupPath)
        end

        deleteSystemFiles()
        writeOk("Old system files removed.")
    end

    createDataDirs()

    local ok, result = installFiles(manifest)

    if not ok then
        writeError(result)
        writeWarn("Installation stopped. Fix manifest/GitHub files and run installer again.")
        return false
    end

    writeInstallInfo(manifest)

    writeOk("")
    writeOk("NovaOS installed successfully.")
    writeOk("Installed files: " .. tostring(result))

    local rebootNow = askYesNo("Reboot now?", false)

    if rebootNow then
        os.reboot()
    end

    writeLine("")
    writeLine("Run 'reboot' to start NovaOS.")

    return true
end

return Installer.run()
