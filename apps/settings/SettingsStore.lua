local ThemeSelector = dofile("apps/settings/ThemeSelector.lua")

local SettingsStore = {}

function SettingsStore.new(ctx)
    local self = {}

    self.ctx = ctx
    self.configPath = "data/settings.lua"

    function self:save()
        if not fs.exists("data") then
            fs.makeDir("data")
        end

        local handle = fs.open(self.configPath, "w")

        if not handle then
            return false, "Cannot save config file: " .. self.configPath
        end

        handle.write("return ")
        handle.write(textutils.serialize(self.ctx.config))
        handle.close()

        return true, "Settings saved."
    end

    function self:getItems()
        return {
            {
                key = "username",
                label = "Username:        " .. tostring(self.ctx.config.username),
                hint = "Change displayed username"
            },
            {
                key = "hostname",
                label = "Hostname:        " .. tostring(self.ctx.config.hostname),
                hint = "Change terminal host name"
            },
            {
                key = "theme",
                label = "Theme:           " .. tostring(self.ctx.config.theme),
                hint = "Cycle color theme"
            },
            {
                key = "fetch",
                label = "Fetch on boot:   " .. tostring(self.ctx.config.showFetchOnBoot),
                hint = "Show system info after boot"
            },
            {
                key = "box",
                label = "Box style:       " .. tostring(self.ctx.config.boxStyle or "ascii"),
                hint = "Switch ascii/unicode borders"
            },
            {
                key = "save",
                label = "Save settings",
                hint = "Write config to data/settings.lua"
            },
            {
                key = "exit",
                label = "Exit",
                hint = "Return to shell"
            }
        }
    end

    function self:setUsername(value)
        if value and value ~= "" then
            self.ctx.config.username = value
            return self:save()
        end

        return true, "Username unchanged."
    end

    function self:setHostname(value)
        if value and value ~= "" then
            self.ctx.config.hostname = value
            return self:save()
        end

        return true, "Hostname unchanged."
    end

    function self:nextTheme()
        local nextTheme = ThemeSelector.next(self.ctx.config.theme)

        self.ctx.config.theme = nextTheme
        self.ctx.theme = ThemeSelector.get(nextTheme)

        return self:save()
    end

    function self:toggleFetchOnBoot()
        self.ctx.config.showFetchOnBoot = not self.ctx.config.showFetchOnBoot

        return self:save()
    end

    function self:toggleBoxStyle()
        if self.ctx.config.boxStyle == "unicode" then
            self.ctx.config.boxStyle = "ascii"
        else
            self.ctx.config.boxStyle = "unicode"
        end

        return self:save()
    end

    return self
end

return SettingsStore