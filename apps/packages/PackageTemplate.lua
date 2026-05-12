local PackageTemplate = {}

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

function PackageTemplate.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:askAppId()
        if self.ctx.ui and self.ctx.ui.Input then
            return self.ctx.ui.Input.prompt(self.ctx, {
                title = "New package",
                label = "Application ID:",
                placeholder = "Example: notes, clock, calculator",
                value = "",
                allowEmpty = false
            })
        end

        write("App id: ")
        return read()
    end

    function self:createManifest(appId, appName)
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

    function self:createMain(appId, appName)
        return
            "local App = {}\n\n" ..
            "App.name = \"" .. appName .. "\"\n" ..
            "App.description = \"New NovaOS application\"\n\n" ..
            "function App.run(ctx, args)\n" ..
            "    ctx.screen:clear(ctx.theme.background, ctx.theme.text)\n" ..
            "    ctx.ui.Box.draw(ctx, 2, 2, term.getSize() - 2, select(2, term.getSize()) - 3, \"" .. appName .. "\")\n" ..
            "    ctx.ui.Box.writeInside(ctx, 2, 2, term.getSize() - 2, 2, \"Application ID: " .. appId .. "\", ctx.theme.accent2)\n" ..
            "    ctx.ui.Box.writeInside(ctx, 2, 2, term.getSize() - 2, 4, \"Press any key or click to exit.\", ctx.theme.muted)\n" ..
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

    function self:create(appId)
        appId = sanitizeId(appId)

        if not appId or appId == "" then
            return false, "Invalid app id."
        end

        local appDir = fs.combine("apps", appId)

        if fs.exists(appDir) then
            return false, "Package already exists: " .. appId
        end

        fs.makeDir(appDir)

        local appName = capitalize(appId)

        local manifestOk, manifestError = writeFile(
            fs.combine(appDir, "manifest.lua"),
            self:createManifest(appId, appName)
        )

        if not manifestOk then
            return false, manifestError
        end

        local mainOk, mainError = writeFile(
            fs.combine(appDir, "main.lua"),
            self:createMain(appId, appName)
        )

        if not mainOk then
            return false, mainError
        end

        return true, "Created package: " .. appId
    end

    function self:createInteractive()
        local appId = self:askAppId()

        if not appId or appId == "" then
            return false, "Creation cancelled."
        end

        return self:create(appId)
    end

    return self
end

return PackageTemplate