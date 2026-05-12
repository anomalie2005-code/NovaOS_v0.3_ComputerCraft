local FileScanner = {}

local function getParent(path)
    if not path or path == "" then
        return ""
    end

    local parent = fs.getDir(path)

    if not parent or parent == "" then
        return ""
    end

    return parent
end

function FileScanner.new()
    local self = {}

    function self:getParent(path)
        return getParent(path)
    end

    function self:scan(path)
        local entries = {}

        if path ~= "" then
            table.insert(entries, {
                name = "..",
                label = "[UP]  ..",
                kind = "up",
                path = getParent(path)
            })
        end

        if not fs.exists(path) or not fs.isDir(path) then
            return entries
        end

        local items = fs.list(path)
        table.sort(items)

        for _, item in ipairs(items) do
            local fullPath = fs.combine(path, item)

            if fs.isDir(fullPath) then
                table.insert(entries, {
                    name = item,
                    label = "[DIR] " .. item,
                    kind = "dir",
                    path = fullPath
                })
            end
        end

        for _, item in ipairs(items) do
            local fullPath = fs.combine(path, item)

            if not fs.isDir(fullPath) then
                table.insert(entries, {
                    name = item,
                    label = "      " .. item,
                    kind = "file",
                    path = fullPath
                })
            end
        end

        return entries
    end

    return self
end

return FileScanner