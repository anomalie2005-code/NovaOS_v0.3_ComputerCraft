local Config = {}

Config.path = "data/settings.lua"

Config.defaults = {
    systemName = "NovaOS",
    version = "0.1.0",
    username = "user",
    hostname = "nova",
    theme = "cyber",
    shellName = "NovaShell",
    homeDir = "home/user",
    showFetchOnBoot = true,
    promptStyle = "classic"
}

local function copyTable(source)
    local result = {}

    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = copyTable(value)
        else
            result[key] = value
        end
    end

    return result
end

local function mergeDefaults(data, defaults)
    for key, value in pairs(defaults) do
        if data[key] == nil then
            if type(value) == "table" then
                data[key] = copyTable(value)
            else
                data[key] = value
            end
        elseif type(value) == "table" and type(data[key]) == "table" then
            mergeDefaults(data[key], value)
        end
    end

    return data
end

function Config.ensureDataFolders()
    if not fs.exists("data") then
        fs.makeDir("data")
    end

    if not fs.exists("data/logs") then
        fs.makeDir("data/logs")
    end

    if not fs.exists("home") then
        fs.makeDir("home")
    end

    if not fs.exists("home/user") then
        fs.makeDir("home/user")
    end
end

function Config.save(data)
    Config.ensureDataFolders()

    local handle = fs.open(Config.path, "w")

    if not handle then
        error("Cannot open config file for writing: " .. Config.path)
    end

    handle.write("return ")
    handle.write(textutils.serialize(data))
    handle.close()
end

function Config.load()
    Config.ensureDataFolders()

    if not fs.exists(Config.path) then
        local defaults = copyTable(Config.defaults)
        Config.save(defaults)
        return defaults
    end

    local ok, data = pcall(dofile, Config.path)

    if not ok or type(data) ~= "table" then
        local defaults = copyTable(Config.defaults)
        Config.save(defaults)
        return defaults
    end

    data = mergeDefaults(data, Config.defaults)
    Config.save(data)

    return data
end

return Config
