local UninstallCommand = {}

UninstallCommand.description = "Completely remove NovaOS from this computer"
UninstallCommand.category = "system"
UninstallCommand.usage = "uninstall"
UninstallCommand.aliases = {}
UninstallCommand.examples = {
    "uninstall"
}

local SYSTEM_PATHS = {
    "startup.lua",
    "apps",
    "commands",
    "sys",
    "lib"
}

local USER_DATA_PATHS = {
    "data",
    "home"
}

local BACKUP_ROOT = "novaos_uninstall_backup"

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

local function copyRecursive(source, target)
    if not fs.exists(source) then
        return
    end

    if fs.isDir(source) then
        ensureDir(target)

        for _, item in ipairs(fs.list(source)) do
            copyRecursive(fs.combine(source, item), fs.combine(target, item))
        end

        return
    end

    ensureParentDir(target)

    if fs.exists(target) then
        fs.delete(target)
    end

    fs.copy(source, target)
end

local function deletePath(path)
    if fs.exists(path) then
        fs.delete(path)
        return true
    end

    return false
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

local function getStamp()
    local stamp = tostring(math.floor(os.clock() * 1000))

    if os.epoch then
        stamp = tostring(os.epoch("utc"))
    end

    return stamp
end

local function hasNovaOS()
    for _, path in ipairs(SYSTEM_PATHS) do
        if fs.exists(path) then
            return true
        end
    end

    return false
end

local function makeBackup(includeUserData)
    local backupPath = BACKUP_ROOT .. "_" .. getStamp()

    ensureDir(backupPath)

    for _, path in ipairs(SYSTEM_PATHS) do
        if fs.exists(path) then
            copyRecursive(path, fs.combine(backupPath, path))
        end
    end

    if includeUserData then
        for _, path in ipairs(USER_DATA_PATHS) do
            if fs.exists(path) then
                copyRecursive(path, fs.combine(backupPath, path))
            end
        end
    end

    return backupPath
end

local function deleteSystem()
    local deleted = 0

    for _, path in ipairs(SYSTEM_PATHS) do
        if deletePath(path) then
            deleted = deleted + 1
            writeWarn("Deleted: " .. path)
        end
    end

    return deleted
end

local function deleteUserData()
    local deleted = 0

    for _, path in ipairs(USER_DATA_PATHS) do
        if deletePath(path) then
            deleted = deleted + 1
            writeWarn("Deleted: " .. path)
        end
    end

    return deleted
end

local function finalConfirmation()
    writeLine("")
    writeError("DANGER: This will remove NovaOS from this computer.")
    writeWarn("To continue, type exactly:")
    writeLine("")
    setColor(colors.red)
    print("DELETE NOVAOS")
    setColor(colors.white)
    writeLine("")

    write("> ")
    local answer = read()

    return answer == "DELETE NOVAOS"
end

local function printHeader()
    writeLine("")
    writeError("NovaOS Uninstaller")
    writeWarn("------------------")
    writeLine("")
end

function UninstallCommand.run(ctx, args)
    printHeader()

    if not hasNovaOS() then
        writeWarn("NovaOS system files were not found.")
        return false, "NovaOS system files were not found."
    end

    writeError("This command will uninstall NovaOS.")
    writeWarn("System files to remove:")
    writeLine("")

    for _, path in ipairs(SYSTEM_PATHS) do
        if fs.exists(path) then
            writeLine("  - " .. path)
        end
    end

    writeLine("")
    writeWarn("Optional user data:")
    writeLine("  - data")
    writeLine("  - home")

    local continue = askYesNo("Continue uninstall?", true)

    if not continue then
        writeWarn("Uninstall cancelled.")
        return false, "Uninstall cancelled."
    end

    if not finalConfirmation() then
        writeWarn("Confirmation failed. Uninstall cancelled.")
        return false, "Confirmation failed."
    end

    local backup = askYesNo("Create backup before uninstall?", false)
    local includeUserDataInBackup = false

    if backup then
        includeUserDataInBackup = askYesNo("Include user data in backup?", false)

        local backupPath = makeBackup(includeUserDataInBackup)
        writeOk("Backup created: " .. backupPath)
    end

    local deleteData = askYesNo("Also delete user data, settings and home?", true)

    writeLine("")
    writeWarn("Removing NovaOS...")

    local systemDeleted = deleteSystem()
    local dataDeleted = 0

    if deleteData then
        dataDeleted = deleteUserData()
    end

    writeLine("")
    writeOk("Uninstall completed.")
    writeStatus("System entries removed: ", tostring(systemDeleted))
    writeStatus("User data entries removed: ", tostring(dataDeleted))

    writeLine("")
    writeWarn("NovaOS has been removed.")
    writeWarn("Run 'reboot' to return to plain CraftOS.")

    if ctx and ctx.logger then
        ctx.logger:info("NovaOS uninstalled from this computer.")
    end

    return true
end

return UninstallCommand