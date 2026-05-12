local FileActions = {}

function FileActions.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:openEntry(entry)
        if not entry then
            return nil
        end

        if entry.kind == "up" then
            return {
                type = "change_directory",
                path = entry.path
            }
        end

        if entry.kind == "dir" then
            return {
                type = "change_directory",
                path = entry.path
            }
        end

        if entry.kind == "file" then
            return {
                type = "preview_file",
                path = entry.path
            }
        end

        return nil
    end

    function self:editFile(path)
        if not path or path == "" then
            return false, "File path is required."
        end

        if fs.exists(path) and fs.isDir(path) then
            return false, "Cannot edit directory."
        end

        local ok, result = self.ctx.appManager:launch("editor", {
            "open",
            "editor",
            path
        })

        if not ok then
            return false, result
        end

        return true
    end

    return self
end

return FileActions