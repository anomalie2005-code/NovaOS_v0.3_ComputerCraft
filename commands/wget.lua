local WgetCommand = {}

WgetCommand.description = "Download files from the internet or run remote Lua scripts"
WgetCommand.category = "network"
WgetCommand.usage = "wget <url> [file] | wget run <url>"
WgetCommand.aliases = {}
WgetCommand.examples = {
    "wget https://example.com/file.lua file.lua",
    "wget run https://example.com/install.lua"
}

local function printColor(text, color)
    if term.isColor and term.isColor() and color then
        term.setTextColor(color)
    end

    print(tostring(text or ""))

    if term.isColor and term.isColor() then
        term.setTextColor(colors.white)
    end
end

local function getArg(args, index)
    if not args then
        return nil
    end

    return args[index]
end

local function normalizeArgs(args)
    args = args or {}

    if args[1] == "wget" then
        return {
            args[2],
            args[3],
            args[4],
            args[5]
        }
    end

    return args
end

local function getFileNameFromUrl(url)
    url = tostring(url or "")

    local clean = string.gsub(url, "%?.*$", "")
    local name = string.match(clean, "([^/]+)$")

    if not name or name == "" then
        return "download.lua"
    end

    return name
end

local function ensureParentDir(path)
    local dir = fs.getDir(path)

    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

local function downloadText(url)
    if not http then
        return nil, "HTTP API is disabled."
    end

    local response, err = http.get(url)

    if not response then
        return nil, err or "HTTP request failed."
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

local function loadLua(code, chunkName)
    if load then
        local ok, chunk = pcall(function()
            return load(code, chunkName or "downloaded_chunk", "t", _G)
        end)

        if ok and chunk then
            return chunk
        end

        local fallbackChunk, fallbackErr = load(code, chunkName or "downloaded_chunk")

        if fallbackChunk then
            return fallbackChunk
        end

        return nil, fallbackErr or chunk
    end

    if loadstring then
        local chunk, err = loadstring(code, chunkName or "downloaded_chunk")

        if chunk then
            setfenv(chunk, _G)
            return chunk
        end

        return nil, err
    end

    return nil, "No Lua loader available."
end

local function runRemote(url)
    printColor("Downloading script:", colors.orange)
    print(url)

    local code, err = downloadText(url)

    if not code then
        return false, "Download failed: " .. tostring(err)
    end

    local firstChar = string.sub(code, 1, 1)

    if firstChar == "<" then
        return false, "Downloaded HTML, not Lua. Use raw.githubusercontent.com link."
    end

    local chunk, loadErr = loadLua(code, url)

    if not chunk then
        return false, "Lua load failed: " .. tostring(loadErr)
    end

    printColor("Running remote script...", colors.lime)

    local ok, result = pcall(chunk)

    if not ok then
        return false, "Runtime error: " .. tostring(result)
    end

    return true
end

local function downloadFile(url, path)
    path = path or getFileNameFromUrl(url)

    printColor("Downloading:", colors.orange)
    print(url)

    printColor("Target:", colors.orange)
    print(path)

    local content, err = downloadText(url)

    if not content then
        return false, "Download failed: " .. tostring(err)
    end

    local ok, saveErr = saveFile(path, content)

    if not ok then
        return false, saveErr
    end

    printColor("Saved: " .. path, colors.lime)

    return true
end

function WgetCommand.run(ctx, args)
    args = normalizeArgs(args)

    local first = getArg(args, 1)

    if not first or first == "" then
        printColor("Usage:", colors.orange)
        print("  wget <url> [file]")
        print("  wget run <url>")
        return false, "Missing URL."
    end

    if first == "run" then
        local url = getArg(args, 2)

        if not url or url == "" then
            return false, "Missing URL for wget run."
        end

        return runRemote(url)
    end

    local url = first
    local path = getArg(args, 2)

    return downloadFile(url, path)
end

return WgetCommand
