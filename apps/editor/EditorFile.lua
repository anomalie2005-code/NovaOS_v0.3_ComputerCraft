local EditorFile = {}

local function splitLines(content)
    local lines = {}

    content = tostring(content or "")
    content = string.gsub(content, "\r\n", "\n")
    content = string.gsub(content, "\r", "\n")

    for line in string.gmatch(content .. "\n", "(.-)\n") do
        table.insert(lines, line)
    end

    if #lines == 0 then
        table.insert(lines, "")
    end

    return lines
end

function EditorFile.load(path)
    if not fs.exists(path) then
        return { "" }, nil
    end

    if fs.isDir(path) then
        return nil, "Cannot edit a directory."
    end

    local handle = fs.open(path, "r")

    if not handle then
        return nil, "Cannot open file for reading."
    end

    local content = handle.readAll() or ""
    handle.close()

    local lines = splitLines(content)

    if #lines == 0 then
        lines = { "" }
    end

    return lines, nil
end

function EditorFile.save(path, lines)
    local parent = fs.getDir(path)

    if parent and parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end

    local handle = fs.open(path, "w")

    if not handle then
        return false, "Cannot open file for writing."
    end

    for index, line in ipairs(lines) do
        handle.write(tostring(line or ""))

        if index < #lines then
            handle.write("\n")
        end
    end

    handle.close()

    return true, nil
end

return EditorFile