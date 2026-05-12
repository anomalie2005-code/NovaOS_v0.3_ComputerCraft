local LauncherData = {}

function LauncherData.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:listApps()
        if self.ctx.appManager and self.ctx.appManager.listMetadata then
            return self.ctx.appManager:listMetadata()
        end

        local result = {}
        local names = self.ctx.appManager:list()

        table.sort(names)

        for _, appName in ipairs(names) do
            table.insert(result, {
                id = appName,
                name = appName,
                label = appName,
                description = "No description",
                version = "0.1.0",
                author = "NovaOS",
                entry = "main.lua"
            })
        end

        return result
    end

    function self:getAppByIndex(index)
        local apps = self:listApps()

        return apps[index]
    end

    return self
end

return LauncherData